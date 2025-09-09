#!/bin/bash
# Script para levantar todo el entorno: Keycloak, Gateway y microservicios

echo "== Levantando Keycloak con Docker Compose =="
docker-compose up -d
sleep 15

echo "== Configurando Keycloak =="
./configure-keycloak.sh

echo "== Levantando Gateway, Orders y Products =="
cd gateway && mvn spring-boot:run &
GATEWAY_PID=$!
cd ../orders-service && mvn spring-boot:run &
ORDERS_PID=$!
cd ../products-service && mvn spring-boot:run &
PRODUCTS_PID=$!

echo "== Todos los servicios están levantándose =="
echo "Gateway PID: $GATEWAY_PID"
echo "Orders PID: $ORDERS_PID"
echo "Products PID: $PRODUCTS_PID"

echo "Para detener todo, ejecuta: kill $GATEWAY_PID $ORDERS_PID $PRODUCTS_PID"
