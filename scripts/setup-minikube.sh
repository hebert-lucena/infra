#!/bin/bash

set -e

echo "Verificando se Minikube está instalado..."
if ! command -v minikube &> /dev/null; then
    echo "Minikube não encontrado. Por favor, instale o Minikube primeiro."
    echo "Visite: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

echo "Verificando se kubectl está instalado..."
if ! command -v kubectl &> /dev/null; then
    echo "kubectl não encontrado. Por favor, instale o kubectl primeiro."
    exit 1
fi

echo "Verificando status do Minikube..."
if minikube status &> /dev/null; then
    echo "Minikube já está rodando."
else
    echo "Iniciando Minikube..."
    minikube start
fi

echo "Aguardando cluster ficar pronto..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "Habilitando ingress addon (opcional)..."
minikube addons enable ingress

echo "Minikube configurado com sucesso!"
echo "Para verificar o status: minikube status"
echo "Para acessar o dashboard: minikube dashboard"

