# Como Configurar o Repositório GitHub no ArgoCD

## 📋 Informações do Repositório

- **URL:** `https://github.com/hebert-lucena/infra.git`
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
   https://github.com/hebert-lucena/infra.git
   ```
   
   **Type:** `git`
   
   **Project:** `default` (ou selecione um projeto específico)
   
   **Username:** `hebert-lucena` (seu usuário do GitHub)
   
   **Password:** Use um **Personal Access Token** (obrigatório para repositórios privados)

### Passo 3: Criar Personal Access Token (Obrigatório)

O GitHub exige Personal Access Token para autenticação:

1. No GitHub, vá em **Settings** (seu perfil) > **Developer settings** > **Personal access tokens** > **Tokens (classic)**
2. Clique em **Generate new token (classic)**
3. Dê um nome ao token: `ArgoCD-Infra`
4. Selecione as permissões:
   - `repo` (acesso completo aos repositórios privados)
   - Ou apenas `public_repo` (se o repositório for público)
5. Clique em **Generate token**
6. **Copie o token imediatamente** (você só verá uma vez)
7. No ArgoCD, use o token como senha

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

**Com Personal Access Token (obrigatório):**
```bash
argocd repo add https://github.com/hebert-lucena/infra.git \
  --username hebert-lucena \
  --password SEU_TOKEN \
  --type git \
  --name infra
```

### Passo 4: Verificar Repositórios

```bash
# Listar repositórios
argocd repo list

# Ver detalhes de um repositório
argocd repo get https://github.com/hebert-lucena/infra.git
```

---

## 🔧 Método 3: Via YAML (Declarativo)

### Criar Secret do Repositório

Crie o arquivo `argocd-repo-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-repo-secret
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/hebert-lucena/infra.git
  password: SEU_PERSONAL_ACCESS_TOKEN
  username: hebert-lucena
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
2. Procure por `https://github.com/hebert-lucena/infra.git`
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
   - **Repository URL:** `https://github.com/hebert-lucena/infra.git`
   - **Path:** `charts/airflow`
   - **Cluster URL:** `https://kubernetes.default.svc`
   - **Namespace:** `airflow`
3. Clique em **Create**

Via CLI:
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

---

## 🔒 Segurança

- **Use Personal Access Token** ao invés de senha
- **Revise as permissões** do token (apenas o necessário)
- **Rotacione tokens** periodicamente
- **Use secrets do Kubernetes** para armazenar credenciais sensíveis

---

## ❓ Troubleshooting

### Erro: "repository not accessible"

- Verifique se o Personal Access Token está correto
- Teste a conexão manualmente: `git clone https://github.com/hebert-lucena/infra.git`
- Verifique se o token tem a permissão `repo` (para repositórios privados)
- Se o repositório for público, use `public_repo`

### Erro: "authentication failed"

- Verifique se está usando HTTPS (não SSH)
- Confirme que o token/senha está correto
- Tente regenerar o token

### Repositório aparece mas não sincroniza

- Verifique se a branch `main` existe
- Confirme que o caminho do chart está correto (`charts/airflow`, `charts/argocd`)
- Verifique os logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argo-cd-repo-server`

