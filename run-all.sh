#!/bin/bash
# =============================================================================
# Full environment startup script for Keycloak, Gateway, and microservices
# =============================================================================

# -------------------------------
# Variables
# -------------------------------
KEYCLOAK_CONTAINER="java-springboot3-api-gateway-oauth2-keycloak-keycloak-1"
REALM="demo"
CLIENT_ID="gateway"
CLIENT_SECRET="gateway-secret"
USER="user1"
PASS="password"
ROLES=("orders.read" "orders.write" "products.read")

# -------------------------------
# Step 1: Start Keycloak with Docker Compose
# -------------------------------
echo "== Starting Keycloak with Docker Compose =="

docker-compose down -v
docker-compose up -d

STARTUP_WAIT=25     # total wait in seconds (fixed wait)
INTERVAL=5          # update interval in seconds
ELAPSED=0

echo "== Waiting for Keycloak to start (fixed wait: $STARTUP_WAIT s) =="

while [ $ELAPSED -lt $STARTUP_WAIT ]; do
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
    if [ $ELAPSED -gt $STARTUP_WAIT ]; then
        ELAPSED=$STARTUP_WAIT
    fi
    PERCENT=$((ELAPSED * 100 / STARTUP_WAIT))
    echo "[$PERCENT%] $ELAPSED/$STARTUP_WAIT seconds elapsed"
done

echo "== Finished fixed wait of $STARTUP_WAIT seconds =="

# -------------------------------
# Step 2: Configure Keycloak
# -------------------------------
echo "== Configuring Keycloak =="

# Authenticate
docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080 \
    --realm master \
    --user admin \
    --password admin

# Create realm
docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create realms \
    -s realm=$REALM \
    -s enabled=true

# Create client
docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create clients \
    -r $REALM \
    -s clientId=$CLIENT_ID \
    -s name=$CLIENT_ID \
    -s enabled=true \
    -s publicClient=false \
    -s secret=$CLIENT_SECRET \
    -s protocol=openid-connect \
    -s standardFlowEnabled=true \
    -s directAccessGrantsEnabled=true

# Create user and set password
docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create users \
    -r $REALM \
    -s username=$USER \
    -s enabled=true

docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh set-password \
    -r $REALM \
    --username $USER \
    --new-password $PASS

# Create roles
for ROLE in "${ROLES[@]}"; do
    docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create roles \
        -r $REALM \
        -s name=$ROLE
done

# Assign roles to user
for ROLE in "${ROLES[@]}"; do
    docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh add-roles \
        -r $REALM \
        --uusername $USER \
        --rolename $ROLE
done

echo "== Keycloak configuration completed =="

# -------------------------------
# Step 3: Start Gateway, Orders, and Products microservices
# -------------------------------
echo "== Starting Gateway, Orders, and Products =="

pushd "$PWD/gateway" || exit
mvn spring-boot:run &
GATEWAY_PID=$!
popd || exit

pushd "$PWD/orders-service" || exit
mvn spring-boot:run &
ORDERS_PID=$!
popd || exit

pushd "$PWD/products-service" || exit
mvn spring-boot:run &
PRODUCTS_PID=$!
popd || exit

echo "== All services are starting =="
echo "Gateway PID: $GATEWAY_PID"
echo "Orders PID: $ORDERS_PID"
echo "Products PID: $PRODUCTS_PID"

echo "To stop all services, run: kill $GATEWAY_PID $ORDERS_PID $PRODUCTS_PID"
