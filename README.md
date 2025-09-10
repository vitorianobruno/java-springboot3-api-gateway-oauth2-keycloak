# Spring Boot 3 - API Gateway with OAuth2, JWT, and Keycloak

This project demonstrates how to implement an API Gateway using Spring Cloud Gateway with Spring Security, delegating authentication to Keycloak via OAuth2 and JWT.
It includes:
- Gateway (Spring Cloud Gateway) with support for OAuth2 Login and Token Relay
- Microservices: Orders and Products (Resource Servers)
- Keycloak for authentication and authorization
- Scripts for automatic configuration and quick start

---

## 📦 Project Structure

```
java-springboot3-api-gateway-oauth2-keycloak/
├── gateway/              # API Gateway
├── orders-service/       # Orders microservice
├── products-service/     # Products microservice
├── docker-compose.yml    # Keycloak setup
├── run-all.ps1           # Script to start everything (PowerShell)
├── run-all.sh            # Script to start everything (Bash)
└── README.md
```

---

## 🏗️ Requirements
- **Java 17+**
- **Maven**
- **Docker + Docker Compose**
- **jq** (for JSON parsing in the Keycloak script)

---

## ▶️ Start Everything (Keycloak + Microservices)

**⚠️ IMPORTANT:** Make sure Docker Desktop is running on your local before run the script!

---

### ✅ This script does:
- `docker-compose up` (starts **Keycloak** at [http://localhost:8081](http://localhost:8081))
- Configures **realm, client, user, and roles**
- Starts **Gateway, Orders, and Products** in parallel

### ▶️ How to Use It?

### 1. Make it executable in Bash
```bash
chmod +x run-all.sh
```
### 2. Run
```bash
./run-all.sh
```

### 1. Make it executable in Powershell
```bash
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
### 2. Run
```bash
.\run-all.ps1
```

**⚠️ IMPORTANT:** After the script finish we need to add Redirect Uris 
"http://localhost:8080/login/oauth2/code/keycloak") for gateway client in the Keycloak console.

### TIP: How to start each service manually

If you want to start the microservices individually instead of using the full script, you can do it like this:

```bash
cd gateway && mvn spring-boot:run
cd ../orders-service && mvn spring-boot:run
cd ../products-service && mvn spring-boot:run
```

---

### 🔐 Keycloak Configuration
- **Realm:** `demo`
- **Client:** `gateway` (confidential)
- **Redirect URI:** `http://localhost:8080/login/oauth2/code/keycloak`
- **Secret:** `gateway-secret`
- **User:** `user1 / password`
- **Roles:** `orders.read`, `orders.write`, `products.read`

---

### 🌐 Endpoints
- **Gateway:** [http://localhost:8080](http://localhost:8080)
- `/api/orders/**` → **Orders Service** (port `9001`)
- `/api/products/**` → **Products Service** (port `9002`)

---

### 🔄 OAuth2 Flow
1. Client accesses **Gateway** → redirect to **Keycloak**
2. **Keycloak** authenticates and returns an **authorization code**
3. **Gateway** exchanges the code for a **JWT token**
4. **Gateway** adds the **JWT token** to each request to microservices (Token Relay)
5. Microservices validate the token using **issuer-uri**

---

### ✅ Included Scripts
- `run-all.ps1`: Starts **Keycloak** and all **microservices** PowerShell version
- `run-all.sh`: Starts **Keycloak** and all **microservices** Bash version

---

### 🔒 Security
- **Gateway** handles **OAuth2 Login** (for SPA/Browser)
- **Gateway** and microservices act as **Resource Servers** (validate JWT)
- Uses **Token Relay** in **Spring Cloud Gateway** to propagate the token

---

### 🧪 Test the Flow
1. Open [http://localhost:8080/api/orders](http://localhost:8080/api/orders) in your browser
2. You will be redirected to **Keycloak** → log in with `user1 / password`
3. **Gateway** will validate the token and forward the request to the corresponding service
