# Infra AWS Free Tier — ECS + EC2 + ECR + RDS

Este repositório contém uma **infraestrutura AWS totalmente baseada em Free Tier**, criada com foco em:

- Baixo custo (controle absoluto de gastos)
- Reprodutibilidade (infra como código via AWS CLI)
- Simplicidade arquitetural
- Estudo prático de ECS (EC2 launch type)
- Integração real com banco de dados (RDS)

A infraestrutura foi pensada para **MVP, estudos, portfólio e projetos pessoais**, evitando serviços gerenciados caros como **ALB, NAT Gateway e Fargate**, mantendo apenas o **RDS dentro do Free Tier** quando necessário.

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
    |
    v
    RDS (PostgreSQL / MySQL)
```

- Apenas **uma porta pública** (gateway)
- Comunicação interna via Docker bridge
- Banco acessível **somente via Security Group**
- Um único host (Free Tier)

---

## 📁 Estrutura do Repositório

```
infra-aws-free-tier/
├── ecs/
│   └── task-definitions/
│       ├── app-task-definition.json
│       └── app-task-definition.gen.json
│
├── rds/
│   ├── subnet-group.json
│   └── parameter-group.json
│
├── scripts/
│   ├── create/
│   │   ├── 01-ecr.sh
│   │   ├── 02-ecs-cluster.sh
│   │   ├── 03-ec2.sh
│   │   ├── 04-register-task-definition.sh
│   │   ├── 05-ecs-service.sh
│   │   ├── 06-rds-subnet-group.sh
│   │   ├── 07-rds-security-group.sh
│   │   └── 08-rds-instance.sh
│   │
│   └── destroy/
│       ├── 01-destroy-ecs.sh
│       ├── 02-destroy-ec2.sh
│       └── 03-destroy-rds.sh
│
└── README.md
````

---

## 🔐 Pré-requisitos

- AWS CLI configurada (`aws configure`)
- Conta AWS com Free Tier ativo
- Docker instalado localmente
- Repositórios ECR criados
- Key Pair EC2 criado previamente (ex: `ecs-key`)

---

## 🚀 Subindo a Infra (ordem obrigatória)

### 1️⃣ Criar repositórios ECR

```bash
./scripts/create/01-ecr.sh
````

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

Essa tag é usada para destruição segura e controle de custos.

---

### 4️⃣ Registrar Task Definition

```bash
./scripts/create/04-register-task-definition.sh
```

* Substitui automaticamente `ACCOUNT_ID`
* Gera arquivo `.gen.json`
* Cada execução cria uma **nova revisão** da task

---

### 5️⃣ Criar ECS Service

```bash
./scripts/create/05-ecs-service.sh
```

Após isso:

* Containers sobem automaticamente
* ECS gerencia restart
* Gateway fica acessível via porta pública

---

## 🗄️ (Opcional) Criando o RDS

> Use apenas se sua aplicação precisar de banco persistente.

### 6️⃣ Criar Subnet Group do RDS

```bash
./scripts/create/01-rds-subnet-group.sh
```

---

### 7️⃣ Criar Security Group do RDS

```bash
./scripts/create/02-rds-security-group.sh
```

* Acesso liberado **somente para o SG da EC2/ECS**
* RDS **não é público**

---

### 8️⃣ Criar instância RDS (Free Tier)

```bash
./scripts/create/03-rds-instance.sh
```

Configuração:

* `db.t3.micro`
* 20 GB storage
* Backup desativado
* Free Tier safe

---

## 🧨 Destruindo Tudo (sem risco de custo)

### 1️⃣ Remover ECS Service e Cluster

```bash
./scripts/destroy/01-destroy-ecs.sh
```

---

### 2️⃣ Encerrar EC2 (PASSO CRÍTICO)

```bash
./scripts/destroy/02-destroy-ec2.sh
```

* Filtra por TAG
* Confirmação manual
* Aguarda estado `terminated`

---

### 3️⃣ Remover RDS (se criado)

```bash
./scripts/destroy/03-destroy-rds.sh
```

* Sem snapshot
* Sem backups
* Custo zero após exclusão

---

## 💸 Controle de Custos

* Apenas **1 EC2 t3.micro**
* Apenas **1 RDS db.t3.micro** (opcional)
* Nenhum ALB
* Nenhum NAT Gateway
* Nenhum Fargate

Custo esperado: **R$ 0 dentro do Free Tier**

---

## 🧠 Decisões Arquiteturais

* ECS com EC2 → controle total de custo
* Gateway interno → apenas uma porta pública
* Task única → simplicidade operacional
* RDS privado → segurança real
* Scripts CLI → reprodutibilidade
* Destroy obrigatório → segurança financeira

---

## 📌 Evoluções Futuras

* Secrets Manager para credenciais do RDS
* docker-compose local espelhando ECS
* GitHub Actions (build + push ECR)
* NGINX ou Spring Cloud Gateway
* Migração para ALB ao sair do Free Tier

---

## ✅ Status do Projeto

* Infra funcional
* Free Tier safe
* ECS + EC2 + RDS real
* Criar / destruir em minutos
  * Documentação consistente

---

> Este repositório foi construído com mentalidade de **Arquiteto de Soluções**, priorizando **clareza, custo, segurança e controle total da infraestrutura**.

```