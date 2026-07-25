# --- KONFIGURACJA PODSTAWOWA ---
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Konfiguracja dostawcy AWS i wybranego regionu
provider "aws" {
  region = "us-east-1"
}

# --- SIECI (VPC I PODSIECI) ---
# Pobieramy domyślne VPC, aby nie pisać całej infrastruktury sieciowej od zera
data "aws_vpc" "default" {
  default = true
}

# Pobieramy identyfikatory domyślnych podsieci w wybranym VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- REPOZYTORIUM ECR ---
# Tworzy prywatne repozytorium na obrazy Dockera dla naszej aplikacji
resource "aws_ecr_repository" "app_repo" {
  name                 = "moj-projekt-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- BEZPIECZEŃSTWO (SECURITY GROUPS) ---
# 1. Security Group dla Load Balancera – zezwala na ruch HTTP (port 80) z całego świata
resource "aws_security_group" "alb_sg" {
  name        = "moj-projekt-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Security Group dla zadań ECS – zezwala na ruch wyłącznie z Load Balancera na porcie aplikacji
resource "aws_security_group" "ecs_sg" {
  name        = "moj-projekt-ecs-sg"
  description = "Allow inbound from ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- LOAD BALANCING (ALB) ---
# Tworzenie Application Load Balancera
resource "aws_lb" "main" {
  name               = "moj-projekt-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

# Target Group wskazująca na port aplikacji wewnątrz kontenera (8000)
resource "aws_lb_target_group" "app_tg" {
  name        = "moj-projekt-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Listener przekierowujący ruch z portu 80 na Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# --- AWS ECS (CLUSTER, TASK DEFINITION, SERVICE) ---
# Klaster ECS zarządzający kontenerami
resource "aws_ecs_cluster" "main" {
  name = "moj-projekt-cluster"
}

# Definicja zadania Fargate (zasoby, obraz z ECR, porty, logi)
resource "aws_ecs_task_definition" "app" {
  family                   = "moj-projekt-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/moj-projekt"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}

# Usługa ECS utrzymująca uruchomioną aplikację i łącząca ją z Load Balancerem
resource "aws_ecs_service" "main" {
  name            = "moj-projekt-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "app"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
}

# --- UPRAWNIENIA IAM ---
# Rola IAM pozwalająca ECS na pobieranie obrazów z ECR oraz zapisywanie logów do CloudWatch
resource "aws_iam_role" "ecs_execution_role" {
  name = "moj_projekt_ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Przypisanie oficjalnej polityki AWS do roli wykonawczej ECS
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- WYJŚCIE (OUTPUT) ---
# Zwraca publiczny adres URL Load Balancera po zakończeniu wdrożenia
output "app_url" {
  value       = "http://${aws_lb.main.dns_name}"
  description = "Publiczny adres URL aplikacji"
}
