# Infraestrutura Local - Minikube + ArgoCD + Airflow

Este repositório contém Helm charts para configurar uma infraestrutura local usando Minikube, ArgoCD e Apache Airflow, preparada para integração futura com GitLab via GitOps.

## Estrutura do Projeto

```
infra/
├── charts/
│   ├── argocd/          # Chart do ArgoCD (Bitnami)
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── airflow/         # Chart do Airflow (Bitnami)
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── scripts/
│   ├── setup-minikube.sh    # Script para configurar Minikube
│   ├── install-argocd.sh    # Script para instalar ArgoCD
│   └── install-airflow.sh   # Script para instalar Airflow
└── README.md
```

## Pré-requisitos

- [Minikube](https://minikube.sigs.k8s.io/docs/start/) instalado
- [kubectl](https://kubernetes.io/docs/tasks/tools/) instalado
- [Helm](https://helm.sh/docs/intro/install/) 3.x instalado
- Git Bash ou WSL (para executar os scripts bash no Windows)

## Instalação

### 1. Configurar Minikube

Execute o script para configurar o cluster Minikube:

```bash
chmod +x scripts/setup-minikube.sh
./scripts/setup-minikube.sh
```

Ou manualmente:

```bash
minikube start
minikube addons enable ingress
```

### 2. Instalar ArgoCD

Execute o script para instalar o ArgoCD:

```bash
chmod +x scripts/install-argocd.sh
./scripts/install-argocd.sh
```

O ArgoCD será instalado no namespace `argocd` usando o chart Bitnami.

**Acesso ao ArgoCD:**

- **Via NodePort:** `minikube service argocd-server -n argocd`
- **Via Port-Forward:** `kubectl port-forward svc/argocd-server -n argocd 8080:443`

**Obter senha inicial do admin:**

```bash
kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin\.password}' | base64 -d && echo
```

Usuário padrão: `admin`

### 3. Instalar Airflow

Execute o script para instalar o Airflow:

```bash
chmod +x scripts/install-airflow.sh
./scripts/install-airflow.sh
```

O Airflow será instalado no namespace `airflow` usando o chart Bitnami (versão >= 3.0).

**Acesso ao Airflow:**

- **Via NodePort:** `minikube service airflow-webserver -n airflow`
- **Via Port-Forward:** `kubectl port-forward svc/airflow-webserver -n airflow 8080:8080`

**Credenciais padrão:**

- Usuário: `user`
- Senha: Verifique no secret do Kubernetes:
  ```bash
  kubectl get secret airflow -n airflow -o jsonpath='{.data.airflow-password}' | base64 -d && echo
  ```

## Configurações

### ArgoCD

As configurações do ArgoCD estão em `charts/argocd/values.yaml`:

- **Service Type:** NodePort
- **Portas:** HTTP 30080, HTTPS 30443
- **Recursos:** Configurados para ambiente local

### Airflow

As configurações do Airflow estão em `charts/airflow/values.yaml`:

- **Versão:** >= 3.0.0
- **Executor:** LocalExecutor
- **Service Type:** NodePort
- **Porta:** 30808
- **PostgreSQL:** Incluído como dependência
- **Recursos:** Configurados para ambiente local

## Atualização dos Charts

Para atualizar as dependências dos charts:

```bash
cd charts/argocd
helm dependency update

cd ../airflow
helm dependency update
```

## Integração com GitLab (Futuro)

Após configurar o repositório no GitLab, você pode configurar o ArgoCD para sincronizar automaticamente:

1. **Adicionar repositório GitLab no ArgoCD:**

```bash
argocd repo add <URL_DO_REPOSITORIO_GITLAB> \
  --username <SEU_USUARIO> \
  --password <SUA_SENHA>
```

2. **Criar Application no ArgoCD:**

```bash
argocd app create airflow-app \
  --repo <URL_DO_REPOSITORIO_GITLAB> \
  --path charts/airflow \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace airflow \
  --sync-policy automated
```

3. **Ou criar via YAML:**

Crie um arquivo `argocd-apps.yaml` com a definição da Application e aplique:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: airflow
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <URL_DO_REPOSITORIO_GITLAB>
    targetRevision: main
    path: charts/airflow
  destination:
    server: https://kubernetes.default.svc
    namespace: airflow
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Troubleshooting

### Verificar status dos pods

```bash
kubectl get pods -n argocd
kubectl get pods -n airflow
```

### Ver logs

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argo-cd
kubectl logs -n airflow -l app.kubernetes.io/name=airflow
```

### Desinstalar

```bash
helm uninstall argocd -n argocd
helm uninstall airflow -n airflow
```

## Referências

- [Bitnami Helm Charts](https://github.com/bitnami/charts)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

