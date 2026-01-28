# Infra AWS Free Tier — ECS + EC2 + ECR

Este repositório contém uma **infraestrutura AWS totalmente baseada em Free Tier**, criada com foco em:

* Baixo custo (controle absoluto de gastos)
* Reprodutibilidade (scripts CLI)
* Simplicidade arquitetural
* Estudo prático de ECS (EC2 launch type)

A infraestrutura foi pensada para **MVP, estudos, portfólio e projetos pessoais**, evitando serviços gerenciados caros como ALB, Fargate e RDS.

---

## 🧱 Arquitetura Geral

```
Internet
   |
   v
EC2 (t3.micro)
 └── ECS Cluster
      └── 1 Task
           ├── gateway (porta 8080)
           ├── user-service (8081)
           ├── lista-service (8082)
           └── notification-service (8083)
```

* **Apenas uma porta pública** (gateway)
* Comunicação interna via Docker bridge
* Um único host (Free Tier)

---

## 📁 Estrutura do Repositório

```
infra-aws-free-tier/
├── ecs/
│   └── task-definitions/
│       └── app-task-definition.json
│
├── scripts/
│   ├── create/
│   │   ├── 01-ecr.sh
│   │   ├── 02-ecs-cluster.sh
│   │   ├── 03-ec2.sh
│   │   ├── 04-register-task-definition.sh
│   │   └── 05-ecs-service.sh
│   │
│   └── destroy/
│       ├── 06-destroy-ecs.sh
│       └── 07-destroy-ec2.sh
│
└── README.md
```

---

## 🔐 Pré-requisitos

* AWS CLI configurada (`aws configure`)
* Conta AWS com Free Tier ativo
* Docker instalado localmente
* Repositórios ECR criados

---

## 🚀 Subindo a Infra (ordem obrigatória)

### 1️⃣ Criar repositórios ECR

```bash
./scripts/create/01-ecr.sh
```

---

### 2️⃣ Criar Cluster ECS

```bash
./scripts/create/02-ecs-cluster.sh
```

---

### 3️⃣ Criar EC2 (ECS-Optimized)

```bash
./scripts/create/03-ec2.sh
```

⚠️ Esta EC2 é criada com **TAG obrigatória**:

```
Project=infra-aws-free-tier
```

Essa tag é usada para destruição segura.

---

### 4️⃣ Registrar Task Definition

```bash
./scripts/create/04-register-task-definition.sh
```

Cada execução cria uma **nova revisão** da task.

---

### 5️⃣ Criar ECS Service

```bash
./scripts/create/05-ecs-service.sh
```

Após isso:

* Containers sobem automaticamente
* ECS gerencia restart

---

## 🧨 Destruindo Tudo (sem risco de custo)

### 1️⃣ Remover ECS Service e Cluster

```bash
./scripts/destroy/06-destroy-ecs.sh
```

---

### 2️⃣ Encerrar EC2 (PASSO CRÍTICO)

```bash
./scripts/destroy/07-destroy-ec2.sh
```

⚠️ **Nunca pule este passo** — EC2 gera cobrança se ficar ligada.

O script:

* Filtra EC2 por TAG
* Pede confirmação manual
* Aguarda término completo

---

## 💸 Controle de Custos

* Apenas **1 EC2 t3.micro**
* Nenhum ALB
* Nenhum NAT Gateway
* Nenhum Fargate
* Nenhum RDS

Custo esperado: **R$ 0 dentro do Free Tier**

---

## 🧠 Decisões Arquiteturais

* ECS com EC2 (não Fargate) → custo zero
* Gateway interno → 1 porta pública
* Task única → simplicidade
* Scripts CLI → reprodutibilidade
* Destroy obrigatório → segurança financeira

---

## 📌 Evoluções Futuras (opcional)

* docker-compose local espelhando ECS
* Spring Cloud Gateway ou NGINX
* GitHub Actions (build + push ECR)
* Migração para ALB quando sair do Free Tier

---

## ✅ Status do Projeto

✔ Infra funcional
✔ Free Tier safe
✔ Criar / destruir em minutos
✔ Documentado

---

> Este repositório foi criado com mentalidade de **Arquiteto de Soluções**, priorizando clareza, custo e controle.
