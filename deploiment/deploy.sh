#!/bin/bash
# Télécharger l'image Redis
echo "Téléchargement de l'image Redis depuis Docker Hub..."
docker pull redis
if [ $? -ne 0 ]; then
    echo "Erreur lors du téléchargement de l'image Redis."
    exit 1
fi

# Démarrer Minikube avec Docker comme driver
echo "Démarrage de Minikube avec Docker comme driver..."
minikube start --driver=docker
if [ $? -ne 0 ]; then
    echo "Erreur lors du démarrage de Minikube."
    exit 1
fi

# Liste des répertoires où se trouvent les fichiers Kubernetes
K8S_DIRS=(
  "backend"
  "front"
  "prom-graf"
  "redis"
)

# Vérifier si kubectl est installé
if ! command -v kubectl &> /dev/null
then
    echo "kubectl n'est pas installé. Veuillez installer kubectl pour continuer."
    exit 1
fi

# Appliquer les fichiers Kubernetes dans chaque répertoire
for dir in "${K8S_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "Application des fichiers Kubernetes dans le répertoire : $dir"
    kubectl apply -f "$dir"  # Appliquer tous les fichiers YAML dans le répertoire
    if [ $? -ne 0 ]; then
        echo "Erreur lors de l'application des fichiers dans $dir."
        exit 1
    fi
  else
    echo "Le répertoire $dir n'existe pas."
    exit 1
  fi
done

# Attendre que les pods du serveur Backend (Node.js) soient prêts
echo "Attente que les pods du serveur Backend (Node.js) soient prêts..."
kubectl wait --for=condition=ready pod -l app=node-redis --timeout=600s

if [ $? -eq 0 ]; then
    echo "Le pod Backend (Node.js) est maintenant prêt."
else
    echo "Erreur lors de l'attente du pod Backend."
    exit 1
fi

# Attendre que les pods du serveur Frontend (React) soient prêts
echo "Attente que les pods du serveur Frontend (React) soient prêts..."
kubectl wait --for=condition=ready pod -l app=redis-react --timeout=600s

if [ $? -eq 0 ]; then
    echo "Le pod Frontend (React) est maintenant prêt."
else
    echo "Erreur lors de l'attente du pod Frontend."
    exit 1
fi

# Vérification de l'état des ressources déployées
echo "Vérification des pods Kubernetes..."
kubectl get pods

# Vérification des services
echo "Vérification des services Kubernetes..."
kubectl get svc

# Affichage de l'URL du serveur Prometheus via minikube
echo "Récupération de l'URL de Prometheus via Minikube..."
PROMETHEUS_URL=$(minikube service prometheus --url)
if [ $? -eq 0 ]; then
    echo "Prometheus est accessible à l'adresse : $PROMETHEUS_URL"
else
    echo "Impossible de récupérer l'URL de Prometheus."
fi

# Affichage de l'URL du serveur Grafana via minikube
echo "Récupération de l'URL de Grafana via Minikube..."
GRAFANA_URL=$(minikube service grafana --url)
if [ $? -eq 0 ]; then
    echo "Grafana est accessible à l'adresse : $GRAFANA_URL"
else
    echo "Impossible de récupérer l'URL de Grafana."
fi


# Affichage de l'URL du serveur backend (Node.js) via minikube
echo "Récupération de l'URL du serveur Backend (Node.js) via Minikube..."
BACKEND_URL=$(minikube service node-redis-projet --url)
if [ $? -eq 0 ]; then
    echo "Le serveur Backend (Node.js) est accessible à l'adresse : $BACKEND_URL"
else
    echo "Impossible de récupérer l'URL du serveur Backend."
fi

# Affichage de l'URL du frontend (React) via minikube
echo "Récupération de l'URL du frontend (React) via Minikube..."
FRONTEND_URL=$(minikube service redis-react-projet --url)
if [ $? -eq 0 ]; then
    echo "Le frontend (React) est accessible à l'adresse : $FRONTEND_URL"
else
    echo "Impossible de récupérer l'URL du frontend."
fi

# Fin du script
echo "Tous les fichiers Kubernetes ont été appliqués avec succès."

