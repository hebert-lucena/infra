# Como Configurar o Repositório GitLab no ArgoCD

## 📋 Informações do Repositório

- **URL:** `https://gitlab-dti.agu.gov.br/hebert.silva/infra.git`
- **Tipo:** Git
- **Branch padrão:** `main`

---

## 🌐 Método 1: Via Interface Web (Recomendado)

### Passo 1: Acessar o ArgoCD

1. Abra o navegador e acesse: `https://localhost:8080`
2. Faça login com:
   - **Usuário:** `admin`
   - **Senha:** `U1FXHbyMSNITh0WA`

### Passo 2: Adicionar Repositório

1. No menu lateral, clique em **Settings** (⚙️)
2. Clique em **Repositories** (ou vá diretamente em **Settings** > **Repositories**)
3. Clique no botão **Connect Repo** (canto superior direito)
4. Preencha o formulário:

   **Connection Method:** `Via HTTPS`
   
   **Repository URL:** 
   ```
   https://gitlab-dti.agu.gov.br/hebert.silva/infra.git
   ```
   
   **Type:** `git`
   
   **Project:** `default` (ou selecione um projeto específico)
   
   **Username:** `hebert.silva` (seu usuário do GitLab)
   
   **Password:** Sua senha do GitLab OU um **Personal Access Token** (recomendado)

### Passo 3: Usar Personal Access Token (Recomendado)

Para maior segurança, use um Personal Access Token ao invés da senha:

1. No GitLab, vá em **Settings** > **Access Tokens**
2. Crie um novo token com as permissões:
   - `read_repository`
   - `read_api`
3. Copie o token gerado
4. No ArgoCD, use o token como senha

### Passo 4: Verificar Conexão

1. Após adicionar, o repositório aparecerá na lista
2. Clique no repositório para ver detalhes
3. Verifique se o status está **Successful** (verde)

---

## 💻 Método 2: Via CLI (ArgoCD CLI)

### Passo 1: Instalar ArgoCD CLI (se ainda não tiver)

**Windows (via Chocolatey):**
```powershell
choco install argocd
```

**Windows (via Scoop):**
```powershell
scoop install argocd
```

**Linux/Mac:**
```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

### Passo 2: Fazer Login no ArgoCD

```bash
# Via port-forward (se ainda não estiver rodando)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Em outro terminal, fazer login
argocd login localhost:8080 --username admin --password U1FXHbyMSNITh0WA --insecure
```

### Passo 3: Adicionar Repositório

**Com usuário e senha:**
```bash
argocd repo add https://gitlab-dti.agu.gov.br/hebert.silva/infra.git \
  --username hebert.silva \
  --password SUA_SENHA \
  --type git \
  --name infra
```

**Com Personal Access Token (recomendado):**
```bash
argocd repo add https://gitlab-dti.agu.gov.br/hebert.silva/infra.git \
  --username hebert.silva \
  --password SEU_TOKEN \
  --type git \
  --name infra
```

### Passo 4: Verificar Repositórios

```bash
# Listar repositórios
argocd repo list

# Ver detalhes de um repositório
argocd repo get https://gitlab-dti.agu.gov.br/hebert.silva/infra.git
```

---

## 🔧 Método 3: Via YAML (Declarativo)

### Criar Secret do Repositório

Crie o arquivo `argocd-repo-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo-secret
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://gitlab-dti.agu.gov.br/hebert.silva/infra.git
  password: SEU_TOKEN_OU_SENHA
  username: hebert.silva
```

**Aplicar:**
```bash
kubectl apply -f argocd-repo-secret.yaml
```

### Verificar

```bash
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository
```

---

## ✅ Verificar se Funcionou

### Via Interface Web:

1. Acesse **Settings** > **Repositories**
2. Procure por `https://gitlab-dti.agu.gov.br/hebert.silva/infra.git`
3. O status deve estar **Successful** (ícone verde)

### Via CLI:

```bash
argocd repo list
```

Você deve ver o repositório listado com status **Successful**.

---

## 🚀 Próximos Passos

Após configurar o repositório, você pode:

1. **Criar Applications** que apontam para os charts neste repositório
2. **Sincronizar automaticamente** mudanças do GitLab para o cluster
3. **Gerenciar toda a infraestrutura** via GitOps

### Exemplo: Criar Application para Airflow

Via Interface Web:
1. Clique em **New App**
2. Preencha:
   - **Application Name:** `airflow`
   - **Project:** `default`
   - **Repository URL:** `https://gitlab-dti.agu.gov.br/hebert.silva/infra.git`
   - **Path:** `charts/airflow`
   - **Cluster URL:** `https://kubernetes.default.svc`
   - **Namespace:** `airflow`
3. Clique em **Create**

Via CLI:
```bash
argocd app create airflow \
  --repo https://gitlab-dti.agu.gov.br/hebert.silva/infra.git \
  --path charts/airflow \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace airflow \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

---

## 🔒 Segurança

- **Use Personal Access Token** ao invés de senha
- **Revise as permissões** do token (apenas o necessário)
- **Rotacione tokens** periodicamente
- **Use secrets do Kubernetes** para armazenar credenciais sensíveis

---

## ❓ Troubleshooting

### Erro: "repository not accessible"

- Verifique se o usuário/senha está correto
- Teste a conexão manualmente: `git clone https://gitlab-dti.agu.gov.br/hebert.silva/infra.git`
- Verifique se o token tem as permissões corretas

### Erro: "authentication failed"

- Verifique se está usando HTTPS (não SSH)
- Confirme que o token/senha está correto
- Tente regenerar o token

### Repositório aparece mas não sincroniza

- Verifique se a branch `main` existe
- Confirme que o caminho do chart está correto (`charts/airflow`, `charts/argocd`)
- Verifique os logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argo-cd-repo-server`

