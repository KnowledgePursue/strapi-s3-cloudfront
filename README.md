# 🚀 Strapi 5 + S3 + CloudFront + Docker

Stack de produção para o Strapi CMS com armazenamento de mídia no **AWS S3 privado**, distribuição via **CloudFront CDN** e proxy reverso com **Traefik + SSL automático**.

## 🏗️ Arquitetura

```
Usuário → CloudFront (CDN) → S3 (privado)
                ↑
Strapi → faz upload direto no S3
         e salva URL do CloudFront no banco
```

## 📋 Pré-requisitos

- Docker e Docker Compose instalados no servidor
- Domínio apontando para o IP do servidor (necessário para SSL)
- Conta AWS com:
  - Bucket S3 criado (privado, ACLs desabilitadas)
  - Distribuição CloudFront com OAC apontando para o bucket
  - IAM Access Key com permissões de leitura/escrita no bucket
  - Bucket policy permitindo acesso do CloudFront via OAC

## ⚙️ Permissões IAM necessárias

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:PutObject",
    "s3:GetObject",
    "s3:DeleteObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::SEU-BUCKET",
    "arn:aws:s3:::SEU-BUCKET/*"
  ]
}
```

## 🚀 Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/KnowledgePursue/strapi-s3-cloudfront.git
cd strapi-s3-cloudfront
```

### 2. Configure as variáveis de ambiente

```bash
cp .env.example .env
vim .env
```

Preencha todos os valores. Para gerar os secrets:

```bash
node -e "console.log(require('crypto').randomBytes(16).toString('base64'))"
```

Execute o comando acima uma vez para cada secret (`APP_KEYS` precisa de 4 valores separados por vírgula).

### 3. Crie a estrutura de pastas necessária

```bash
mkdir -p traefik public/uploads
touch traefik/acme.json
chmod 600 traefik/acme.json
```

> ⚠️ O `chmod 600` no `acme.json` é obrigatório — o Traefik recusa iniciar sem ele.

### 4. Build e inicialização

```bash
docker compose build --no-cache
docker compose up -d
```

### 5. Verifique os logs

```bash
docker compose logs -f strapi
```

Aguarde a mensagem:
```
info: Strapi started successfully
```

### 6. Acesse o painel admin

```
https://seu.dominio.com.br/admin
```

Na primeira vez, será solicitado criar o usuário administrador.

---

## 🧠 Recursos e Limitações (t3.medium)

A configuração foi otimizada para rodar em uma instância **AWS t3.medium (2 vCPUs / 4GB RAM)**.

### Docker Compose (`docker-compose.yml`)

| Diretiva | Valor | Descrição |
|---|---|---|
| `mem_limit` | `2g` | Teto máximo de RAM — se ultrapassar, o container é reiniciado |
| `mem_reservation` | `512m` | RAM garantida ao container mesmo sob pressão do host |
| `cpus` | `1.5` | Máximo de vCPUs — garante margem para SO, PostgreSQL e Traefik |

### Dockerfile
```dockerfile
ENV NODE_OPTIONS="--max-old-space-size=1536"
```

Limita o **heap do Node.js** a 1536MB em dois momentos:
- **Build** — evita que o compilador TypeScript + webpack trave a instância
- **Runtime** — evita crescimento descontrolado de memória em produção

### Por que dois limites de memória?

| Limite | Onde age | O que controla |
|---|---|---|
| `--max-old-space-size=1536` | Dentro do Node.js | Heap do JavaScript |
| `mem_limit: 2g` | Docker/Linux | Todo o processo (Node + vips + libs nativas) |

O `vips` (processamento de imagens) aloca memória **fora** do heap do Node, por isso o `mem_limit` é maior que o `--max-old-space-size`.

### Distribuição estimada de memória

| Serviço | Uso estimado |
|---|---|
| Sistema operacional | ~400MB |
| Traefik | ~50MB |
| PostgreSQL | ~200MB |
| Strapi | até 2GB |
| Margem de segurança | ~350MB |

---

## 🔄 Atualização

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## 📁 Estrutura do projeto

```
.
├── config/
│   ├── plugins.ts        # Configuração do provider S3
│   └── middlewares.ts    # CSP com domínio CloudFront via env
├── src/                  # Código fonte do Strapi
├── public/uploads/       # Uploads locais (ignorado pelo git)
├── traefik/
│   └── acme.json         # Certificados SSL (ignorado pelo git)
├── Dockerfile            # Multi-stage build otimizado
├── docker-compose.yml    # Strapi + PostgreSQL + Traefik
├── .env.example          # Template de variáveis de ambiente
└── .dockerignore
```

## 🌍 Variáveis de ambiente

| Variável | Descrição | Exemplo |
|---|---|---|
| `HOST` | Host do servidor | `0.0.0.0` |
| `PORT` | Porta do Strapi | `1337` |
| `NODE_ENV` | Ambiente | `production` |
| `APP_KEYS` | Chaves da aplicação (4 valores) | `chave1,chave2,chave3,chave4` |
| `API_TOKEN_SALT` | Salt para tokens de API | gerado |
| `JWT_SECRET` | Secret JWT | gerado |
| `ADMIN_JWT_SECRET` | Secret JWT do admin | gerado |
| `TRANSFER_TOKEN_SALT` | Salt para tokens de transferência | gerado |
| `ENCRYPTION_KEY` | Chave de criptografia | gerado |
| `DATABASE_CLIENT` | Tipo de banco | `postgres` |
| `DATABASE_HOST` | Host do banco | `strapiDB` |
| `DATABASE_PORT` | Porta do banco | `5432` |
| `DATABASE_NAME` | Nome do banco | `strapi` |
| `DATABASE_USERNAME` | Usuário do banco | `strapi` |
| `DATABASE_PASSWORD` | Senha do banco | senha forte |
| `DATABASE_SSL` | SSL no banco | `false` |
| `DOMAIN` | Domínio do Strapi | `strapi.seu-dominio.com` |
| `EMAIL_SSL` | Email para certificado SSL | `seu@email.com` |
| `AWS_ACCESS_KEY_ID` | Access Key da AWS | `AKIA...` |
| `AWS_ACCESS_SECRET` | Secret Key da AWS | `...` |
| `AWS_REGION` | Região do bucket S3 | `us-east-1` |
| `AWS_BUCKET` | Nome do bucket S3 | `meu-bucket` |
| `CDN_URL` | URL completa do CloudFront | `https://xxxx.cloudfront.net` |

## 🔒 Segurança

- Bucket S3 **100% privado** — sem acesso público direto
- CloudFront acessa o S3 via **OAC (Origin Access Control)**
- Acesso direto ao S3 retorna `403 Access Denied`
- SSL automático via **Let's Encrypt** (Traefik)
- Secrets nunca commitados — gerenciados via `.env` (no `.gitignore`)

## 🐳 Serviços Docker

| Serviço | Imagem | Descrição |
|---|---|---|
| `strapi` | build local | CMS Strapi 5 |
| `strapiDB` | postgres:16-alpine | Banco de dados |
| `traefik` | traefik:v3.6 | Proxy reverso + SSL |

## 📦 Adicionando dependências extras no build

O `Dockerfile` suporta instalação de pacotes extras via `EXTRA_DEPS` no `docker-compose.yml`:

```yaml
build:
  args:
    EXTRA_DEPS: "@strapi/provider-upload-aws-s3@5.40.0 outro-pacote"
```

Isso evita a necessidade de instalar manualmente no sistema de arquivos do host.
