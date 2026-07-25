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
