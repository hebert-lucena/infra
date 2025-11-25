# Infraestrutura Kubernetes - ArgoCD + Airflow

Este repositório contém Helm charts para configurar ArgoCD e Apache Airflow em clusters Kubernetes, preparado para integração com GitLab via GitOps.

## 📋 Índice

- [Estrutura do Projeto](#estrutura-do-projeto)
- [Pré-requisitos](#pré-requisitos)
- [Instalação Local (Minikube)](#instalação-local-minikube)
- [Instalação em Produção](#instalação-em-produção)
- [Como Subir Cada Chart](#como-subir-cada-chart)
  - [ArgoCD](#instalando-o-argocd)
  - [Airflow](#instalando-o-airflow)
- [Acesso aos Serviços](#acesso-aos-serviços)
- [Integração com GitLab](#integração-com-gitlab)
- [Troubleshooting](#troubleshooting)

## 📁 Estrutura do Projeto

```
infra/
├── charts/
│   ├── argocd/              # Chart do ArgoCD
│   │   ├── Chart.yaml      # Definição do chart
│   │   ├── Chart.lock      # Lock file das dependências
│   │   ├── values.yaml     # Valores de configuração (comentado para produção)
│   │   └── templates/      # Templates do Helm (se necessário)
│   └── airflow/            # Chart do Airflow
│       ├── Chart.yaml
│       ├── Chart.lock
│       ├── values.yaml      # Valores de configuração (comentado para produção)
│       └── templates/
├── scripts/
│   ├── setup-minikube.sh   # Script para configurar Minikube
│   ├── install-argocd.sh   # Script para instalar ArgoCD
│   └── install-airflow.sh  # Script para instalar Airflow
├── .gitignore              # Arquivos ignorados pelo Git
└── README.md               # Este arquivo
```

## 🔧 Pré-requisitos

### Para Ambiente Local (Minikube)

- [Minikube](https://minikube.sigs.k8s.io/docs/start/) instalado
- [kubectl](https://kubernetes.io/docs/tasks/tools/) instalado
- [Helm](https://helm.sh/docs/intro/install/) 3.x instalado
- Git Bash ou WSL (para executar scripts bash no Windows)

### Para Produção

- Cluster Kubernetes 1.24+ configurado
- kubectl configurado para o cluster
- Helm 3.x instalado
- Acesso ao repositório de imagens Docker
- StorageClass configurado no cluster
- Ingress Controller (opcional, recomendado)
- Cert-Manager (opcional, para TLS automático)

## 🚀 Instalação Local (Minikube)

### 1. Configurar Minikube

```bash
# Iniciar o cluster Minikube
minikube start

# Habilitar addon de ingress (opcional)
minikube addons enable ingress

# Verificar status
minikube status
```

### 2. Adicionar Repositórios Helm

```bash
# Adicionar repositório oficial do ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm

# Adicionar repositório Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami

# Atualizar repositórios
helm repo update
```

## 📦 Como Subir Cada Chart

### Instalando o ArgoCD

#### Passo 1: Preparar o Chart

```bash
# Navegar para o diretório do chart
cd charts/argocd

# Atualizar dependências do Helm
helm dependency update
```

#### Passo 2: Criar Namespace

```bash
# Criar namespace
kubectl create namespace argocd
```

#### Passo 3: Instalar o ArgoCD

**Para Ambiente Local:**

```bash
# Instalar com valores padrão (NodePort para acesso local)
helm upgrade --install argocd . \
  --namespace argocd \
  --values values.yaml \
  --wait \
  --timeout 10m
```

**Para Produção:**

1. **Editar `values.yaml`** e fazer as seguintes alterações:
   - Remover `--insecure` do `server.extraArgs`
   - Habilitar e configurar `server.ingress` com TLS
   - Aumentar recursos conforme carga esperada
   - Configurar autenticação OIDC/SAML via Dex
   - Usar LoadBalancer ou Ingress em vez de NodePort

2. **Instalar:**

```bash
helm upgrade --install argocd . \
  --namespace argocd \
  --values values.yaml \
  --wait \
  --timeout 10m
```

#### Passo 4: Obter Credenciais de Acesso

```bash
# Obter senha inicial do admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

**Usuário padrão:** `admin`

#### Passo 5: Acessar o ArgoCD

**Via Port-Forward (recomendado para local):**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Acesse: `https://localhost:8080` (ignorar aviso de certificado)

**Via NodePort (Minikube):**

```bash
# Obter IP do Minikube
minikube ip

# Acessar via navegador
# http://<MINIKUBE_IP>:30080 (HTTP)
# https://<MINIKUBE_IP>:30443 (HTTPS - ignorar aviso de certificado)
```

**Via Minikube Service:**

```bash
minikube service argocd-server -n argocd
```

### Instalando o Airflow

#### Passo 1: Preparar o Chart

```bash
# Navegar para o diretório do chart
cd charts/airflow

# Atualizar dependências do Helm
helm dependency update
```

#### Passo 2: Criar Namespace

```bash
# Criar namespace
kubectl create namespace airflow
```

#### Passo 3: Instalar o Airflow

**Para Ambiente Local:**

```bash
# Instalar com valores padrão (LocalExecutor, NodePort)
helm upgrade --install airflow . \
  --namespace airflow \
  --values values.yaml \
  --wait \
  --timeout 15m
```

**Para Produção:**

1. **Editar `values.yaml`** e fazer as seguintes alterações:
   - Alterar `executor` para `CeleryExecutor` ou `KubernetesExecutor`
   - Habilitar e configurar workers (se CeleryExecutor)
   - Configurar banco de dados externo (não usar PostgreSQL interno)
   - Configurar Redis/RabbitMQ externo (se CeleryExecutor)
   - Habilitar ingress com TLS
   - Aumentar recursos conforme carga de DAGs
   - Configurar autenticação (LDAP, OAuth, etc.)

2. **Instalar:**

```bash
helm upgrade --install airflow . \
  --namespace airflow \
  --values values.yaml \
  --wait \
  --timeout 15m
```

#### Passo 4: Obter Credenciais de Acesso

```bash
# Obter senha do usuário padrão
kubectl get secret airflow -n airflow \
  -o jsonpath='{.data.airflow-password}' | base64 -d && echo
```

**Credenciais padrão:**
- Usuário: `user`
- Senha: (obtida do comando acima)

#### Passo 5: Acessar o Airflow

**Via Port-Forward (recomendado para local):**

```bash
kubectl port-forward svc/airflow-web -n airflow 8080:8080
```

Acesse: `http://localhost:8080`

**Via NodePort (Minikube):**

```bash
# Obter IP do Minikube
minikube ip

# Acessar via navegador
# http://<MINIKUBE_IP>:30808
```

**Via Minikube Service:**

```bash
minikube service airflow-web -n airflow
```

## 🌐 Acesso aos Serviços

### ArgoCD

| Método | URL | Observações |
|--------|-----|-------------|
| Port-Forward | `https://localhost:8080` | Ignorar aviso de certificado |
| NodePort HTTP | `http://<MINIKUBE_IP>:30080` | Apenas local |
| NodePort HTTPS | `https://<MINIKUBE_IP>:30443` | Ignorar aviso de certificado |
| Ingress (Produção) | `https://argocd.example.com` | Configurar no values.yaml |

**Credenciais:**
- Usuário: `admin`
- Senha: Obter do secret `argocd-initial-admin-secret`

### Airflow

| Método | URL | Observações |
|--------|-----|-------------|
| Port-Forward | `http://localhost:8080` | Recomendado para local |
| NodePort | `http://<MINIKUBE_IP>:30808` | Apenas local |
| Ingress (Produção) | `https://airflow.example.com` | Configurar no values.yaml |

**Credenciais:**
- Usuário: `user`
- Senha: Obter do secret `airflow`

## 🔗 Integração com GitLab

### 1. Adicionar Repositório GitLab no ArgoCD

**Via CLI:**

```bash
# Instalar ArgoCD CLI (se ainda não tiver)
# Windows: choco install argocd
# Linux/Mac: curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

# Fazer login no ArgoCD
argocd login <ARGOCD_SERVER> --username admin --password <SENHA>

# Adicionar repositório GitLab
argocd repo add https://github.com/hebert-lucena/infra.git \
  --username hebert-lucena \
  --password <SEU_PERSONAL_ACCESS_TOKEN> \
  --type git
```

**Via Interface Web:**

1. Acesse o ArgoCD
2. Vá em **Settings** > **Repositories**
3. Clique em **Connect Repo**
4. Preencha:
   - **Type:** Git
   - **Project:** default
   - **Repository URL:** `https://github.com/hebert-lucena/infra.git`
   - **Username:** Seu usuário GitLab
   - **Password:** Sua senha ou token de acesso

### 2. Criar Application no ArgoCD

**Via CLI:**

```bash
argocd app create airflow \
  --repo https://github.com/hebert-lucena/infra.git \
  --path charts/airflow \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace airflow \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

**Via YAML (recomendado):**

Crie o arquivo `argocd-apps/airflow.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: airflow
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/hebert-lucena/infra.git
    targetRevision: main
    path: charts/airflow
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: airflow
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Aplicar:

```bash
kubectl apply -f argocd-apps/airflow.yaml
```

### 3. Sincronizar Aplicação

**Via Interface Web:**

1. Acesse o ArgoCD
2. Clique na aplicação `airflow`
3. Clique em **Sync**
4. Selecione as opções desejadas
5. Clique em **Synchronize**

**Via CLI:**

```bash
# Sincronizar manualmente
argocd app sync airflow

# Ver status
argocd app get airflow
```

## 🔍 Verificações e Troubleshooting

### Verificar Status dos Pods

```bash
# ArgoCD
kubectl get pods -n argocd

# Airflow
kubectl get pods -n airflow
```

### Ver Logs

```bash
# Logs do ArgoCD Server
kubectl logs -n argocd -l app.kubernetes.io/name=argo-cd-server

# Logs do Airflow Scheduler
kubectl logs -n airflow -l component=scheduler

# Logs do Airflow Webserver
kubectl logs -n airflow -l component=webserver
```

### Verificar Serviços

```bash
# Listar serviços
kubectl get svc -n argocd
kubectl get svc -n airflow
```

### Problemas Comuns

#### ArgoCD não inicia

```bash
# Verificar eventos
kubectl describe pod -n argocd -l app.kubernetes.io/name=argo-cd-server

# Verificar logs
kubectl logs -n argocd -l app.kubernetes.io/name=argo-cd-server
```

#### Airflow não consegue conectar ao banco

```bash
# Verificar status do PostgreSQL
kubectl get pods -n airflow -l app.kubernetes.io/name=postgresql

# Verificar logs do PostgreSQL
kubectl logs -n airflow -l app.kubernetes.io/name=postgresql

# Testar conexão
kubectl exec -it -n airflow <postgresql-pod> -- psql -U airflow -d airflow
```

#### Imagens não são baixadas

```bash
# Verificar se o cluster tem acesso à internet
kubectl run test-pod --image=busybox --rm -it -- ping google.com

# Verificar configuração de imagePullSecrets (se necessário)
kubectl get secrets -n argocd
kubectl get secrets -n airflow
```

### Desinstalar

```bash
# Desinstalar ArgoCD
helm uninstall argocd -n argocd
kubectl delete namespace argocd

# Desinstalar Airflow
helm uninstall airflow -n airflow
kubectl delete namespace airflow
```

## 📝 Configurações para Produção

### Checklist de Produção

#### ArgoCD

- [ ] Remover flag `--insecure` do `server.extraArgs`
- [ ] Configurar ingress com TLS/HTTPS
- [ ] Aumentar recursos (CPU/Memory) conforme carga
- [ ] Configurar autenticação OIDC/SAML via Dex
- [ ] Usar secrets do Kubernetes para senhas
- [ ] Configurar RBAC e políticas de segurança
- [ ] Habilitar backup automático do Redis
- [ ] Configurar monitoramento (Prometheus)
- [ ] Usar LoadBalancer ou Ingress Controller
- [ ] Configurar múltiplas réplicas para HA

#### Airflow

- [ ] Alterar executor para `CeleryExecutor` ou `KubernetesExecutor`
- [ ] Configurar banco de dados externo (não usar PostgreSQL interno)
- [ ] Configurar Redis/RabbitMQ externo (se CeleryExecutor)
- [ ] Habilitar ingress com TLS/HTTPS
- [ ] Configurar autenticação (LDAP, OAuth, etc.)
- [ ] Aumentar recursos conforme carga de DAGs
- [ ] Configurar múltiplas réplicas para HA
- [ ] Usar secrets do Kubernetes para credenciais
- [ ] Configurar backup automático do banco de dados
- [ ] Habilitar monitoramento e alertas
- [ ] Configurar políticas de rede e segurança

### Exemplo de Values para Produção

Veja os comentários detalhados nos arquivos `values.yaml` de cada chart. Todos os valores têm comentários indicando o que alterar para produção.

## 📚 Referências

- [Bitnami Helm Charts](https://github.com/bitnami/charts)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

## 🤝 Contribuindo

1. Faça suas alterações nos charts
2. Teste localmente
3. Atualize a documentação se necessário
4. Faça commit e push para o repositório
5. O ArgoCD sincronizará automaticamente (se configurado)

## 📄 Licença

Este projeto é para uso interno da organização.
