<#
.SYNOPSIS
    Full environment startup script for Keycloak, Gateway, and microservices
.DESCRIPTION
    This script will:
    1. Start Keycloak using Docker Compose
    2. Configure Keycloak (realm, client, user, roles)
    3. Start Gateway, Orders, and Products microservices in background jobs
    4. Output job IDs for stopping the services
#>

# -------------------------------
# Variables
# -------------------------------
$KEYCLOAK_CONTAINER = "java-springboot3-api-gateway-oauth2-keycloak-keycloak-1"
$REALM = "demo"
$CLIENT_ID = "gateway"
$CLIENT_SECRET = "gateway-secret"
$USER = "user1"
$PASS = "password"
$ROLES = @("orders.read", "orders.write", "products.read")

# -------------------------------
# Step 1: Start Keycloak with Docker Compose
# -------------------------------
Write-Host "== Starting Keycloak with Docker Compose ==" -ForegroundColor Cyan
docker-compose down -v
docker-compose up -d

$startupWait = 25     # total wait in seconds (mantener Start-Sleep behavior)
$interval = 5         # update interval in seconds
$elapsed = 0

Write-Host "== Waiting for Keycloak to start (fixed wait: $startupWait s) ==" -ForegroundColor Yellow

while ($elapsed -lt $startupWait) {
    Start-Sleep -Seconds $interval
    $elapsed += $interval
    if ($elapsed -gt $startupWait) { $elapsed = $startupWait }

    # compute percentage (0..100)
    $percent = [int]( ($elapsed / $startupWait) * 100 )

    # show progress bar in PowerShell
    Write-Progress -Activity "Keycloak startup" -Status "$percent% complete ($elapsed/$startupWait s)" -PercentComplete $percent

    # also write a plain line so it is visible in logs
    Write-Host ("[{0}%] {1}/{2} seconds elapsed" -f $percent, $elapsed, $startupWait)
}

# optional: clear the progress UI
Write-Progress -Activity "Keycloak startup" -Completed
Write-Host "== Finished fixed wait of $startupWait seconds ==" -ForegroundColor Green

# -------------------------------
# Step 2: Configure Keycloak
# -------------------------------
Write-Host "== Configuring Keycloak =="

# Authenticate
docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh config credentials `
    --server http://localhost:8080 `
    --realm master `
    --user admin `
    --password admin

# Create realm
docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create realms -s realm=$REALM -s enabled=true

# Create client
docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create clients -r demo -s clientId=$CLIENT_ID -s name=$CLIENT_ID -s enabled=true -s publicClient=false -s secret=$CLIENT_SECRET -s protocol=openid-connect -s standardFlowEnabled=true -s directAccessGrantsEnabled=true

# Create user and set password
docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create users -r $REALM -s username=$USER -s enabled=true
docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh set-password -r $REALM --username $USER --new-password $PASS

# Create roles
foreach ($role in $ROLES) {
    docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh create roles -r $REALM -s name=$role
}

# Assign roles to user
foreach ($role in $ROLES) {
    docker exec -i $KEYCLOAK_CONTAINER /opt/keycloak/bin/kcadm.sh add-roles -r $REALM --uusername $USER --rolename $role
}

Write-Host "== Keycloak configuration completed =="

# -------------------------------
# Step 3: Start Gateway, Orders, and Products microservices
# -------------------------------
Write-Host "== Starting Gateway, Orders, and Products =="

Push-Location "$PWD\gateway"
$GATEWAY_JOB = Start-Job { mvn spring-boot:run }
Pop-Location

Push-Location "$PWD\orders-service"
$ORDERS_JOB = Start-Job { mvn spring-boot:run }
Pop-Location

Push-Location "$PWD\products-service"
$PRODUCTS_JOB = Start-Job { mvn spring-boot:run }
Pop-Location

Write-Host "== All services are starting =="
Write-Host "Gateway Job ID: $($GATEWAY_JOB.Id)"
Write-Host "Orders Job ID: $($ORDERS_JOB.Id)"
Write-Host "Products Job ID: $($PRODUCTS_JOB.Id)"

Write-Host "To stop all services, run: Stop-Job $($GATEWAY_JOB.Id), $($ORDERS_JOB.Id), $($PRODUCTS_JOB.Id)"
