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
spring-gateway-oauth2-demo/
├── gateway/              # API Gateway
├── orders-service/       # Orders microservice
├── products-service/     # Products microservice
├── docker-compose.yml    # Keycloak setup
├── configure-keycloak.sh # Script to configure realm, client, and roles
├── run-all.sh            # Script to start everything
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

```bash
./run-all.sh
```

---

### ✅ This script does:
- `docker-compose up` (starts **Keycloak** at [http://localhost:8081](http://localhost:8081))
- Configures **realm, client, user, and roles** with `configure-keycloak.sh`
- Starts **Gateway, Orders, and Products** in parallel

### ▶️ How to Use It?

### 1. Make it executable
```bash
chmod +x run-all.sh
```
### 2. Run the script
```bash
./run-all.sh
```

### How to start each service manually
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
- `configure-keycloak.sh`: Automatically configures **Keycloak**
- `run-all.sh`: Starts **Keycloak** and all **microservices**

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
