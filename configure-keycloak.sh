#!/bin/bash
# Script para configurar Keycloak automáticamente
# Requisitos: docker-compose con Keycloak corriendo, kcadm.sh disponible en el contenedor

# Variables
KEYCLOAK_CONTAINER="spring-gateway-oauth2-demo-keycloak-1"
REALM="demo"
CLIENT_ID="gateway"
CLIENT_SECRET="gateway-secret"
USER="user1"
PASS="password"
ROLES=("orders.read" "orders.write" "products.read")

echo "== Autenticando en Keycloak CLI =="
docker exec -it $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "== Creando realm '$REALM' =="
docker exec -it $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create realms -s realm=$REALM -s enabled=true

echo "== Creando cliente '$CLIENT_ID' =="
docker exec -it $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create clients -r $REALM -s clientId=$CLIENT_ID -s enabled=true -s publicClient=false -s 'redirectUris=["http://localhost:8080/login/oauth2/code/keycloak"]' -s secret=$CLIENT_SECRET

echo "== Creando usuario '$USER' =="
docker exec -it $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create users -r $REALM -s username=$USER -s enabled=true
docker exec -it $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh set-password -r $REALM --username $USER --new-password $PASS

echo "== Creando roles =="
for role in "${ROLES[@]}"; do
    docker exec -it $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create roles -r $REALM -s name=$role
done

echo "== Asignando roles al usuario =="
for role in "${ROLES[@]}"; do
    ROLE_ID=$(docker exec -it $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh get roles -r $REALM | jq -r ".[] | select(.name==\"$role\") | .id")
    docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh add-roles -r $REALM --uusername $USER --rolename $role
done

echo "== Configuración completada =="
