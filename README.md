# Projet AutoScaling et IaC avec Kubernetes
Ce projet a pour objectif de mettre en place une infrastructure auto-scalable dans un cluster Kubernetes pour héberger une application utilisant Redis, Node.js, React et Prometheus/Grafana pour la surveillance. L'application doit être capable de monter en charge automatiquement pour chaque composant, avec des stratégies d'auto-scaling adaptées et une configuration de monitoring.

## Objectifs du projet
- Déployer une infrastructure Kubernetes pour gérer les services Redis, Node.js et React.
- Configurer l'auto-scaling pour les réplicas de Redis.
- Mettre en place un outil de monitoring avec Prometheus et Grafana pour observer le comportement du serveur NodeJs.

## Composants de l'infrastructure

### Redis
- Utilisation d'un modèle main/replicas où une base Redis principale accepte les écritures et réplique les données vers plusieurs réplicas pour gérer la lecture parallèle.
- Seuls les réplicas de Redis seront auto-scalés.
- Docker image : Redis DockerHub.

### NodeJs
- Un serveur Node.js stateless qui interagit avec la base Redis
- Configuration de réplicas fixes : Le nombre de réplicas du serveur Node.js a été fixé à un nombre précis (3 réplicas) dans le fichier de déploiement Kubernetes.
- Docker image : yasmine77/back (sur DockerHub).

### React
-  L'application React interagit avec le serveur Node.js pour afficher les données. Elle est servie comme une application statique via un serveur NGINX.
- pas d'auto-scaling pour le front.
- Docker image : yasmine77/front (sur DockerHub).

### Prometheus et Grafana
- Prometheus collecte les métriques de Node.Js et les stocke pour analyse.
- Grafana est utilisé pour visualiser les métriques collectées par Prometheus via des dashboards.
- Docker image : Prometheus Docker Hub.
- Docker image : Grafana Docker Hub.

## Prérequis
- Docker.
- Minikube.
- kubectl.

## Fichiers de Déploiement et de Service
### Redis
- **Déscription du déploiment**  (*redis-replica-deployment.yml et redis-master-deployment.yml*)
    - Image Docker : redis:latest
    - Port exposé : 6379 (port par défaut de Redis)
    - Réplicas : 3 (dont 1 master et 2 réplicas)
- **Déscription du service** (*redis-replica-service.yml et redis-master-service.yml*) 
    - Port exposé du master et replicas : 6379
- **Déscription du configmap du master** (*redis-master-configmap.yml*)
    -  active la persistance des données via le fichier AOF (appendonly yes).
- **Déscription du configmap des replicas** (*redis-replica-configmap.yml*)
    -  indique uniquement que les réplicas devraient être en mode lecture seule.

- **Déscription de l'autoscaler HPA des replicas** (*redis-replica-hpa.yml*)
    - configure un autoscaling basé sur le CPU pour le déploiement des réplicas Redis. Il permet de faire varier automatiquement le nombre de réplicas entre 2 et 5 en fonction de l'utilisation du CPU, garantissant une mise à l'échelle efficace en fonction des besoins.
    - Si l'utilisation moyenne du CPU des réplicas de Redis dépasse 50%, l'HPA augmentera le nombre de réplicas jusqu'à un maximum de 5.
    - Si l'utilisation du CPU est inférieure à 50%, l'HPA réduira le nombre de réplicas à au moins 2.
- **Lancement des fichiers** : ces fichiers se trouvent dans le dossier *Projet1_CRV_autoscaling/deploiement/redis*, pour les lancer manuellement, il suffit de se positionner dans le dossier et éxécuter : **kubectl apply -f .**

### Node.Js
- **Déscription du déploiment** (*node-redis-deployment.yml*)
    - Le déploiment utilise l'image docker : *yasmine77/back*.
    - 3 réplicas de pods pour assurer la tolérance aux pannes et la haute disponibilité.
    - le port d'écoute est 8080.
- **Déscription du service** (*node-redis-service.yml*)
    - Type LoadBalancer : Cela permet au service d'être accessible via une IP publique.
    - Le service écoute sur le port 8080, et et redirige le trafic vers le même port.
    - Expose le service sur un port externe spécifique (30010), permettant l'accès au service en dehors du cluster.
    - Kubernetes vérifie et télécharge toujours la dernière version de l'image

### React 
- **Déscription du déploiment** (*front-redis-deployment.yml*)
    - 2 réplicas.
    - Le conteneur utilise l'image Docker *yasmine77/front*.
    - Le conteneur expose le port 8080.
    - Kubernetes vérifie et télécharge toujours la dernière version de l'image
- **Déscription du service** (*front-redis-service.yml*)
    - Type LoadBalancer : Expose l'application via une IP publique.
    - Le service écoute sur le port 8080 et redirige le trafic vers le port 80 du conteneur.
### Prometheus et  Grafana
-  **Déscription du service** (*prom-graf-service.yml*)
    - Type LoadBalancer : Permet à Prometheus et Grafana d'être accessibles via une IP publique.
    - Le service Prometheus écoute sur le port 9090 et redirige le trafic vers le même port.
    - Le service écoute sur le port 3000 et redirige le trafic vers le même port.
- **Déscription du déploiment** (*prom-graf-dep.yml*)
    - 1 réplique pour Prometheus et une pour Grafana.
    - Utilise l'image officielle prom/prometheus et grafana/grafana
    - Port exposé : 9090 pour accéder à l'interface de Prometheus.
    - Port exposé : 3000 pour accéder à l'interface de Grafana.

- **Déscription du configmap** (*prom-graf-conf.yml*)
    - Ce fichier permet de configurer Prometheus pour collecter des métriques à partir du service node-redis-projet (l'application Node.js). Il interroge ce service toutes les 15 secondes pour récupérer les informations sur les performances de l'application.


## Contenu et utilité du bash (deploy.sh)
- Télechargement de l’image Redis. (*docker pull redis)
- Démarrage de minikube. (*minikube start --driver=docker)
- Démarrage des pods et des services. (*kubectl apply -f .)
- Attente que les pods soient complètement lancés, car le lancement des pods du serveur prennent du temps a se mettre en etat *running*. (*kubectl wait --for=condition=ready pod -l app=node-redis --timeout=600s*)
- Vérification des services pour s’assurer que tout fonctionne correctement. (*kubectl get svc*)
- Affichage des URL des différentes parties afin de garantir le bon fonctionnement (Serveur, Frontend, Prometheus et Grafana) 
    - *minikube service prometheus --url*
    - *minikube service grafana --url*
    - *minikube service redis-react-projet --url*, avec *redis-react-projet* le nom du service React.
    - *minikube service node-redis-projet --url*, avec *redis-react-projet* le nom du service Node.Js.
## Lancer l'infrastructure avec le script bash
1. **Cloner le dépôt** : 
Utiliser ce lien lien_github_ta3_leila ou lien_github_ta3_yasmine.
2. **Exécuter le script de déploiement** : Vous trouvez le script bash nommé *deploy.sh* dans *projet_CRV_autoscaling/deploiement/*. 
 Afin de l'éxécuter, vous tapez les deux commandes : 
    - chmod +x deploy.sh
    - ./deploy.sh








