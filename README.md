# 🚀 Projekt Zaliczeniowy DevOps: CI/CD do AWS ECS

Kompletny, w pełni zautomatyzowany system budowania, testowania i wdrażania aplikacji w chmurze AWS przy użyciu konteneryzacji oraz podejścia Infrastructure as Code (IaC).

---

## 📋 Spis treści
1. [Opis projektu](#-opis-projektu)
2. [Architektura rozwiązania](#-architektura-rozwiązania)
3. [Struktura repozytorium](#-struktura-repozytorium)
4. [Wymagania techniczne i endpointy](#-wymagania-techniczne-i-endpointy)
5. [Infrastruktura jako kod (Terraform)](#-infrastruktura-jako-kod-terraform)
6. [Pipeline CI/CD (GitHub Actions)](#-pipeline-cicd-github-actions)
7. [Instrukcja uruchomienia lokalnego i wdrażania](#-instrukcja-uruchomienia-lokalnego-i-wdrażania)
8. [Publiczny adres URL](#-publiczny-adres-url)

---

## 🔍 Opis projektu

Projekt realizuje pełny cykl DevOps (SDLC). Aplikacja webowa została oteksturowana przy pomocy **Dockera**, zautomatyzowana za pomocą **GitHub Actions** i wdrożona na **Amazon ECS** z wykorzystaniem load balancera (**ALB**). Cała infrastruktura chmurowa powstała za pomocą narzędzia **Terraform**.

---

## 🏗️ Architektura rozwiązania

Schemat przedstawia przepływ danych w procesie CI/CD oraz dystrybucję ruchu użytkowników:

```text
[ Developer / Git Push ] 
       │
       ▼
[ GitHub Repository ] ──► [ GitHub Actions (CI/CD Pipeline) ]
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
[ Budowanie obrazu Docker ]              [ Push do Amazon ECR ]
                                                  │
                                                  ▼
                                       [ Aktualizacja Amazon ECS ]
                                                  │
                                                  ▼
                                       [ AWS Application Load Balancer ]
                                                  │
                                                  ▼
                                       [ Publiczny URL / Użytkownik ]
```

## 📁 Struktura repozytorium

Projekt posiada czytelną i uporządkowaną strukturę katalogów, co ułatwia zarządzanie kodem aplikacji, automatyzacją oraz infrastrukturą:

```text
moj-projekt-devops/
├── .github/
│   └── workflows/
│       └── deploy.yml        # Konfiguracja pipeline'u CI/CD (GitHub Actions)
├── app/                      # Kod źródłowy aplikacji webowej
│   └── main.py               # Główny plik aplikacji (endpointy /health, /version, /calculate)
├── docker/                   # Pliki pomocnicze związane z konteneryzacją
├── terraform/                # Infrastruktura jako kod (IaC)
│   ├── main.tf               # Definicje zasobów AWS (ECS, ECR, ALB, VPC, Security Groups)
│   └── variables.tf          # Zmienne konfiguracyjne dla Terraforma
├── Dockerfile                # Instrukcja budowania obrazu kontenera aplikacji
├── .dockerignore             # Pliki i foldery ignorowane podczas budowania Dockera
├── .gitignore                # Pliki ignorowane przez system kontroli wersji Git
└── requirements.txt          # Zależności i biblioteki Pythona wymagane przez aplikację

```
## 🧩 Wymagania techniczne i endpointy

Aplikacja została wyposażona w wymagane endpointy diagnostyczne oraz logikę biznesową (kalkulator), co pozwala w pełni zweryfikować jej poprawność działania:

| Endpoint | Metoda HTTP | Opis działania |
| :--- | :--- | :--- |
| **`/health`** | GET | Endpoint diagnostyczny zwracający status zdrowia aplikacji (wykorzystywany m.in. przez AWS ECS / Load Balancer) |
| **`/version`** | GET | Endpoint informujący o aktualnej wersji wdrożonego oprogramowania |
| **`/calculate?a=X&b=Y`** | GET | Biznesowy endpoint kalkulatora wykonujący operację matematyczną na podanych parametrach |

## 🏗️ Infrastruktura jako kod (Terraform)

Cała infrastruktura w chmurze AWS została zdefiniowana w kodzie (katalog `terraform/main.tf`), co zapewnia powtarzalność i łatwość zarządzania środowiskiem. 

Utworzone komponenty obejmują m.in.:
* **Sieć (VPC):** Skonfigurowana sieć wirtualna z podsieciami publicznymi i prywatnymi, bramą sieciową (Internet Gateway) oraz tablicami routingu.
* **Grupy bezpieczeństwa (Security Groups):** Reguły kontroli ruchu sieciowego dla Load Balancera oraz zadań ECS.
* **Amazon ECR:** Prywatny rejestr kontenerów przechowujący obrazy aplikacji budowane przez pipeline.
* **Amazon ECS (Fargate):** Klaster kontenerowy zarządzający uruchomionymi instancjami aplikacji w trybie bezserwerowym (Fargate).
* **Application Load Balancer (ALB):** Komponent routujący ruch z internetu na odpowiednie porty i zadania w klastrze ECS.

## 🔄 Pipeline CI/CD (GitHub Actions)

Proces automatyzacji wdrożeń (`.github/workflows/deploy.yml`) dba o to, aby każda zmiana w kodzie była automatycznie testowana i wysyłana do chmury. Pipeline wykonuje się przy każdym `push` do gałęzi `main` i składa się z następujących kroków:

1. **Checkout kodu:** Pobranie aktualnego stanu repozytorium do środowiska wykonawczego GitHub Actions.
2. **Uwierzytelnianie w AWS:** Bezpieczne logowanie przy użyciu sekretów repozytorium (`AWS_ACCESS_KEY_ID` oraz `AWS_SECRET_ACCESS_KEY`) przypisanych do dedykowanego użytkownika z ograniczonymi uprawnieniami (`devuser`).
3. **Logowanie do Amazon ECR:** Autoryzacja w prywatnym rejestrze kontenerów AWS.
4. **Build & Push:** Skompilowanie obrazu Docker dla aplikacji i wysłanie go do Amazon Elastic Container Registry (ECR).
5. **Deployment na Amazon ECS:** Odświeżenie definicji zadania (Task Definition) i wdrożenie najnowszej wersji aplikacji na klaster ECS.

## 🚀 Instrukcja uruchomienia lokalnego i wdrażania

### 1. Uruchomienie lokalne w kontenerze Docker
Aby uruchomić i przetestować aplikację lokalnie na własnym komputerze:
```bash
# Zbudowanie obrazu Docker lokalnie
docker build -t moj-projekt-app .

# Uruchomienie kontenera w tle (mapowanie portu 80 na 80)
docker run -d -p 80:80 --name moj-projekt-kontener moj-projekt-app
```
## 🔗 Publiczny Adres URL

Wdrożona aplikacja jest w pełni dostępna z poziomu internetu pod publicznym adresem Application Load Balancera (ALB) w chmurze AWS:

👉 **[http://moj-projekt-alb-2008667154.us-east-1.elb.amazonaws.com/health/calculate?a=5&b=10](http://moj-projekt-alb-2008667154.us-east-1.elb.amazonaws.com/health)**

