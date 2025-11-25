#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Verificando se Helm está instalado..."
if ! command -v helm &> /dev/null; then
    echo "Helm não encontrado. Por favor, instale o Helm primeiro."
    exit 1
fi

echo "Adicionando repositório Bitnami..."
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update

echo "Criando namespace argocd..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "Instalando ArgoCD usando chart Bitnami..."
cd "$PROJECT_ROOT/charts/argocd"

echo "Atualizando dependências do Helm..."
helm dependency update

echo "Instalando ArgoCD..."
helm upgrade --install argocd . \
    --namespace argocd \
    --values values.yaml \
    --wait

echo "Aguardando pods do ArgoCD ficarem prontos..."
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=argo-cd \
    -n argocd \
    --timeout=600s

echo "ArgoCD instalado com sucesso!"
echo ""
echo "Para obter a senha inicial do admin:"
echo "kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin\.password}' | base64 -d && echo"
echo ""
echo "Para acessar via port-forward:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "Ou acesse via NodePort:"
echo "minikube service argocd-server -n argocd"

