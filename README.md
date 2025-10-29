# Kubernetes Deployment for Docker Desktop

This directory contains Kubernetes manifests for deploying the Apartment Invoice Management System to Docker Desktop Kubernetes.

## Quick Start

### For Windows:
```bash
cd k8s
deploy.bat
```

### For Linux/Mac:
```bash
cd k8s
chmod +x deploy.sh
./deploy.sh
```

### Manual Deployment:
```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-mysql.yaml
kubectl apply -f 02-backend.yaml
kubectl apply -f 03-frontend.yaml

# Or apply all at once:
kubectl apply -f .
```

## Manifests Overview

| File | Description |
|------|-------------|
| `00-namespace.yaml` | Creates the `doomed-apt` namespace |
| `01-mysql.yaml` | MySQL database with PersistentVolumeClaim |
| `02-backend.yaml` | Spring Boot backend application |
| `03-frontend.yaml` | React frontend application |

## Services & Ports

| Service | Type | Internal Port | External Port (NodePort) |
|---------|------|---------------|--------------------------|
| MySQL | ClusterIP | 3306 | N/A (internal only) |
| Backend | NodePort | 8080 | 32081 |
| Frontend | NodePort | 3000 | 32080 |

## Access URLs

- **Frontend**: http://localhost:32080
- **Backend API**: http://localhost:32081
- **MySQL**: localhost:3306 (accessible from host)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Desktop K8s                    │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Namespace: doomed-apt                 │ │
│  │                                                    │ │
│  │  ┌──────────────┐      ┌──────────────┐          │ │
│  │  │   Frontend   │──────│   Backend    │          │ │
│  │  │  (React)     │      │ (Spring Boot)│          │ │
│  │  │  Port: 3000  │      │  Port: 8080  │          │ │
│  │  └──────────────┘      └──────┬───────┘          │ │
│  │        │                       │                  │ │
│  │  NodePort:32080          NodePort:32081          │ │
│  │                                │                  │ │
│  │                         ┌──────┴───────┐          │ │
│  │                         │    MySQL     │          │ │
│  │                         │  Port: 3306  │          │ │
│  │                         │ (ClusterIP)  │          │ │
│  │                         └──────────────┘          │ │
│  │                                │                  │ │
│  │                         PersistentVolume          │ │
│  │                         (5Gi Storage)             │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                    localhost:32080 (Frontend)
                    localhost:32081 (Backend)
```

## Key Features

### MySQL Deployment
- Uses PersistentVolumeClaim for data persistence
- 5Gi storage allocation
- Health checks via mysqladmin
- Root password: `admin123`
- Database: `apartment_db`

### Backend Deployment
- Init container waits for MySQL to be ready
- Environment variables for database connection
- Readiness & liveness probes on `/health` endpoint
- Resource limits: 200m-1000m CPU, 512Mi-2Gi memory

### Frontend Deployment
- Environment variable for backend API URL
- TCP socket probes for health checks
- Resource limits: 100m-1000m CPU, 512Mi-2Gi memory

## Common Commands

### View Resources
```bash
kubectl get all -n doomed-apt
kubectl get pods -n doomed-apt
kubectl get svc -n doomed-apt
kubectl get pvc -n doomed-apt
```

### View Logs
```bash
kubectl logs -n doomed-apt -l app=backend
kubectl logs -n doomed-apt -l app=frontend
kubectl logs -n doomed-apt -l app=mysql

# Follow logs
kubectl logs -f -n doomed-apt deployment/backend-deployment
```

### Describe Resources
```bash
kubectl describe pod <pod-name> -n doomed-apt
kubectl describe svc backend -n doomed-apt
kubectl describe pvc mysql-pvc -n doomed-apt
```

### Scale Deployments
```bash
kubectl scale deployment backend-deployment -n doomed-apt --replicas=2
kubectl scale deployment frontend-deployment -n doomed-apt --replicas=2
```

### Restart Deployments
```bash
kubectl rollout restart deployment/backend-deployment -n doomed-apt
kubectl rollout restart deployment/frontend-deployment -n doomed-apt
```

### Port Forwarding (Alternative Access)
```bash
# Forward frontend to local port 3000
kubectl port-forward -n doomed-apt deployment/frontend-deployment 3000:3000

# Forward backend to local port 8080
kubectl port-forward -n doomed-apt deployment/backend-deployment 8080:8080

# Access MySQL
kubectl port-forward -n doomed-apt deployment/mysql 3306:3306
```

### Execute Commands in Pods
```bash
# Access backend shell
kubectl exec -it -n doomed-apt <backend-pod-name> -- /bin/bash

# Access MySQL
kubectl exec -it -n doomed-apt <mysql-pod-name> -- mysql -u root -padmin123

# Check database
kubectl exec -it -n doomed-apt <mysql-pod-name> -- mysql -u root -padmin123 -e "SHOW DATABASES;"
```

### Monitor Resources
```bash
# Watch pod status
kubectl get pods -n doomed-apt -w

# View events
kubectl get events -n doomed-apt --sort-by='.lastTimestamp'

# Resource usage (requires metrics-server)
kubectl top pods -n doomed-apt
kubectl top nodes
```

## Cleanup

### Using Script (Windows):
```bash
cleanup.bat
```

### Manual Cleanup:
```bash
# Delete entire namespace (removes everything)
kubectl delete namespace doomed-apt

# Or delete individual resources
kubectl delete -f 03-frontend.yaml
kubectl delete -f 02-backend.yaml
kubectl delete -f 01-mysql.yaml
kubectl delete -f 00-namespace.yaml
```

**Note**: Deleting the namespace will also delete the PersistentVolumeClaim and associated data.

## Troubleshooting

### Pods Not Starting
```bash
# Check pod status
kubectl get pods -n doomed-apt

# Describe pod for events
kubectl describe pod <pod-name> -n doomed-apt

# Check logs
kubectl logs -n doomed-apt <pod-name>
```

### Backend Can't Connect to MySQL
```bash
# Verify MySQL is running
kubectl get pods -n doomed-apt -l app=mysql

# Check MySQL logs
kubectl logs -n doomed-apt -l app=mysql

# Test DNS resolution from backend pod
kubectl exec -it -n doomed-apt <backend-pod-name> -- nslookup db
```

### Image Pull Errors
```bash
# Check if images exist locally
docker images | grep lobotomy

# Build images locally
cd Backend
docker build -t mmmmnl/lobotomy:v.1.0 .

cd ../Frontend/app
docker build -t mmmmnl/lobotomy_but_front:latest .

# Update imagePullPolicy to "IfNotPresent" in YAML files
```

### PersistentVolume Issues
```bash
# Check PVC status
kubectl get pvc -n doomed-apt

# Describe PVC
kubectl describe pvc mysql-pvc -n doomed-apt

# Check available storage classes
kubectl get storageclass
```

## Configuration

### Backend Environment Variables
Edit `02-backend.yaml` to modify:
- `SPRING_DATASOURCE_URL` - MySQL connection string
- `SPRING_DATASOURCE_USERNAME` - Database username
- `SPRING_DATASOURCE_PASSWORD` - Database password
- `SPRING_PROFILES_ACTIVE` - Spring profile (default: `docker`)

### Frontend Environment Variables
Edit `03-frontend.yaml` to modify:
- `REACT_APP_API` - Backend API URL (default: `http://localhost:32081`)

### NodePort Configuration
To change external ports, edit the `nodePort` values:
- Frontend: `03-frontend.yaml` line 16
- Backend: `02-backend.yaml` line 14

Valid NodePort range: 30000-32767

## Security Notes

⚠️ **Important Security Considerations:**

1. **Database Credentials**: Change default MySQL password in production
2. **NodePort Exposure**: NodePorts expose services externally - use LoadBalancer or Ingress for production
3. **Secrets Management**: Use Kubernetes Secrets instead of plain text environment variables
4. **Network Policies**: Consider implementing NetworkPolicies to restrict pod-to-pod communication
5. **Resource Limits**: Adjust resource requests/limits based on actual usage

## Production Considerations

For production deployments:
1. Use Kubernetes Secrets for sensitive data
2. Implement proper Ingress controller (e.g., nginx-ingress)
3. Use persistent storage class suitable for your environment
4. Configure proper backup strategies for MySQL data
5. Implement monitoring and logging (Prometheus, Grafana, ELK stack)
6. Use separate namespaces for different environments
7. Implement RBAC (Role-Based Access Control)
8. Use ConfigMaps for non-sensitive configuration
9. Consider using StatefulSet for MySQL instead of Deployment
10. Implement proper CI/CD pipelines

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
