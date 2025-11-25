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

echo "Criando namespace airflow..."
kubectl create namespace airflow --dry-run=client -o yaml | kubectl apply -f -

echo "Instalando Airflow usando chart Bitnami..."
cd "$PROJECT_ROOT/charts/airflow"

echo "Atualizando dependências do Helm..."
helm dependency update

echo "Instalando Airflow..."
helm upgrade --install airflow . \
    --namespace airflow \
    --values values.yaml \
    --wait

echo "Aguardando pods do Airflow ficarem prontos..."
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=airflow \
    -n airflow \
    --timeout=600s

echo "Airflow instalado com sucesso!"
echo ""
echo "Para acessar via port-forward:"
echo "kubectl port-forward svc/airflow-webserver -n airflow 8080:8080"
echo ""
echo "Ou acesse via NodePort:"
echo "minikube service airflow-webserver -n airflow"
echo ""
echo "Credenciais padrão:"
echo "Usuário: user"
echo "Senha: (verifique no secret airflow)"

