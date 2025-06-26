Designed by - @chetas24 - github-id
more info on the way

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Headless mode (default Redis usage)
redis:
  service:
    headless: true
    ports:
      - name: redis
        port: 6379

# ClusterIP/NodePort/LoadBalancer example
redis:
  service:
    headless: false
    type: LoadBalancer
    ports:
      - name: redis
        port: 6379
        targetPort: 6379
      - name: metrics
        port: 9121
        targetPort: 9121

| Condition                                  | What Happens                                                     |
| ------------------------------------------ | ---------------------------------------------------------------- |
| `headless: true`                           | Uses `clusterIP: None` ✅                                         |
| `headless: false` + `type: ClusterIP`/etc. | Sets `.spec.type`                                                |
| Port list                                  | Supports multiple ports, with optional `targetPort` & `nodePort` |

----------------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

redis:
  config:
    maxmemory: "128mb"
    policy: allkeys-lru

| Policy Name         | Description                                               | Deletes Keys From  | Algorithm |
| ------------------- | --------------------------------------------------------- | ------------------ | --------- |
| **noeviction**      | Returns errors when memory limit is reached               | None               | N/A       |
| **allkeys-lru**     | Evicts the **least recently used** key                    | All keys           | LRU       |
| **volatile-lru**    | Evicts LRU key **only from keys with expiration (`TTL`)** | Expiring keys only | LRU       |
| **allkeys-random**  | Evicts a random key                                       | All keys           | Random    |
| **volatile-random** | Evicts a random key **with expiration**                   | Expiring keys only | Random    |
| **volatile-ttl**    | Evicts the key with **nearest expiration (lowest TTL)**   | Expiring keys only | TTL-based |
| **allkeys-lfu**     | Evicts the **least frequently used** key                  | All keys           | LFU       |
| **volatile-lfu**    | LFU eviction only among expiring keys                     | Expiring keys only | LFU       |

| Use Case                                                  | Recommended Policy                    |
| --------------------------------------------------------- | ------------------------------------- |
| ❌ Don’t want to lose data (read-only or queue-style app) | `noeviction`                          |
| ✅ General cache with no TTL (Time-To-Live)               | `allkeys-lru`                         |
| ✅ Cache **with TTLs** (e.g., expiring sessions)          | `volatile-lru` or `volatile-ttl`      |
| ⚡️ Very dynamic and high-churn data                       | `allkeys-random` or `volatile-random` |
| 🧠 Smarter cache (frequently used keys retained)          | `allkeys-lfu` or `volatile-lfu`       |


You can check eviction stats using:
redis-cli INFO memory

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
redis:
  auth:
    enabled: true
    password: "supersecret"

redis:
  name: redis
  auth:
    enabled: true
    password: "supersecure"
    secretName: "my-custom-secret-name"

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: {{ .Values.redis.persistence.storageClass }}
      resources:
        requests:
          storage: {{ .Values.redis.persistence.size }}
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

1. Add Redis Dependency (Maven, Gradle)
If using Redis for caching or data storage:
ex: Maven
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

2. Add config in application.yml
spring:
  cache:
    type: redis
  redis:
    host: redis-backend            # Redis service name from your Helm chart
    port: 6379
    password: supersecure          # Must match .Values.redis.auth.password
    timeout: 60000
    lettuce:
      pool:
        max-active: 10
        max-idle: 10
        min-idle: 2

Or in application.properties:
spring.cache.type=redis
spring.redis.host=redis-backend
spring.redis.port=6379
spring.redis.password=supersecure

Replace redis-backend with the actual name of the Service created by your Helm chart (usually it’s defined by .Values.redis.serviceName or the fallback name).

3. Enable Caching
@EnableCaching
@SpringBootApplication
public class YourApplication { ... }

4. Use Redis in Your Code
@Cacheable("users")
public User getUserById(String id) {
  return userRepository.findById(id);
}


Node.js Microservice

1. Install Redis Client
npm install redis

2. Connect to Redis in Code
const redis = require('redis');
const client = redis.createClient({
  url: 'redis://:supersecure@redis-backend:6379'      //supersecure is password here and redis-backend is service name
});
client.connect()
  .then(() => console.log('Connected to Redis'))
  .catch(console.error);


Redis behaves like a server:
- It listens on a port (6379)
- It waits for clients (like your microservices) to connect
Your microservice is the Redis client, using a library like:
- Lettuce or Jedis (Java/Spring Boot)
- redis (Node.js)
- redis-py (Python)

[MICROSERVICE POD]
    |
    | TCP request to redis-backend:6379
    v
[SERVICE: redis-backend]
    |
    | Round-robin load balancing
    v
[REDIS POD (statefulset)]


| Concept                         | Answer                                                          |
| ------------------------------- | --------------------------------------------------------------- |
| Who initiates connection?       | **Microservice connects to Redis**                              |
| What host is used?              | The Redis **service name** (e.g., `redis-backend`)              |
| How does DNS work?              | Kubernetes/OpenShift **resolves service names** to internal IPs |
| Can Redis talk to microservice? | ❌ No — Redis is passive. It does not make outbound connections  |



redis-cli -a yourpassword
redis-cli -h redis-backend -p 6379 -a yourpassword

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

terminationGracePeriodSeconds:
When stopping this pod, wait up to X seconds before forcefully killing it.
Kubernetes sends a SIGTERM to the container.
It waits for terminationGracePeriodSeconds.
If the container hasn’t exited by then, Kubernetes sends a SIGKILL (force kill)

| Scenario | Why You Need It                                |
| -------- | ---------------------------------------------- |
| Redis    | Allows time to **flush data** to disk (AOF)    |
| DBs      | Let connections close gracefully               |
| Web apps | Finish in-flight requests before shutting down |


| App Type          | Recommended Value |
| ----------------- | ----------------- |
| Stateless Web App | 5–10 seconds      |
| Redis or Stateful | 10–30 seconds     |
| Database          | 30+ seconds       |


Security contexts help:
- Run containers as non-root users (best practice)
- Restrict Linux capabilities
- Control file system permissions
- Harden container isolation


Common securityContext Fields
At Pod level (spec.securityContext)
| Field                | Description                                               |
| -------------------- | --------------------------------------------------------- |
| `runAsUser`          | UID the container runs as                                 |
| `runAsGroup`         | GID the container runs as                                 |
| `fsGroup`            | GID used for mounted volumes (affects volume permissions) |
| `supplementalGroups` | Extra group IDs for access                                |
| `seccompProfile`     | Linux syscall filtering                                   |

At Container level (containers[].securityContext)
| Field                      | Description                                    |
| -------------------------- | ---------------------------------------------- |
| `readOnlyRootFilesystem`   | Makes container FS read-only                   |
| `allowPrivilegeEscalation` | Prevents `sudo`-like behavior inside container |
| `capabilities`             | Add/drop Linux kernel capabilities             |
| `runAsUser` / `runAsGroup` | Override user per container                    |

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



