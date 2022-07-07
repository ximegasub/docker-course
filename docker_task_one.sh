#!/bin/bash

sysctl -w vm.max_map_count=262144
systemctl restart docker

user=root
password=test

echo "Deleting previous settings ..."
docker rm -f $(docker ps -aq)
docker network rm task-network

echo "Creating network ..."
docker network create task-network

echo "Creating postgres container ..."
docker run -d \
	--name postgres \
	-e POSTGRES_USER=$user \
	-e POSTGRES_PASSWORD=$password \
	-v posgres_data:/var/lib/postgresql/data \
	--network task-network \
	postgres

echo "Creating sonarqube container ..."
docker run -d \
	--name sonarqube \
	-p 9000:9000 \
	-e sonar.jdbc.username=$user \
	-e sonar.jdbc.password=$password \
	-e sonar.jdbc.url=jdbc:postgresql://postgres/postgres \
	-v sonarqube_data:/opt/sonarqube/data \
	-v sonarqube_extensions:/opt/sonarqube/extensions \
	-v sonarqube_logs:/opt/sonarqube/logs \
	--network task-network \
	sonarqube

echo "Creating jenkins container ..."
docker run -d \
	--name jenkins \
	-p 8080:8080 \
	-p 50000:50000 \
	-v jenkins_home:/var/jenkins_home \
	--network task-network \
        jenkins/jenkins

echo "Creating nexus container ..."
docker run -d \
        -p 8081:8081 \
        --name nexus \
        -v nexus-data:/nexus-data \
        --network task-network \
        sonatype/nexus3

echo "Creating portainer ..."
docker run -d \
        -p 9001:9000 \
        --name=portainer \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data --network task-network \
        portainer/portainer-ce

echo "Containers' list ..."
docker ps
