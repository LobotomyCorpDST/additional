#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Apartment Invoice Management System${NC}"
echo -e "${GREEN}Kubernetes Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    echo "Please install kubectl and enable Kubernetes in Docker Desktop"
    exit 1
fi

# Check if Kubernetes is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Kubernetes cluster is not running${NC}"
    echo "Please enable Kubernetes in Docker Desktop Settings"
    exit 1
fi

echo -e "${YELLOW}Step 1: Creating namespace...${NC}"
kubectl apply -f 00-namespace.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create namespace${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Deploying MySQL database...${NC}"
kubectl apply -f 01-mysql.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to deploy MySQL${NC}"
    exit 1
fi
echo -e "${GREEN}✓ MySQL deployment created${NC}"
echo ""

echo -e "${YELLOW}Step 3: Waiting for MySQL to be ready (this may take 1-2 minutes)...${NC}"
kubectl wait --for=condition=ready pod -l app=mysql -n doomed-apt --timeout=300s
if [ $? -ne 0 ]; then
    echo -e "${RED}MySQL pod failed to become ready${NC}"
    echo "Check logs with: kubectl logs -n doomed-apt -l app=mysql"
    exit 1
fi
echo -e "${GREEN}✓ MySQL is ready${NC}"
echo ""

echo -e "${YELLOW}Step 4: Deploying backend application...${NC}"
kubectl apply -f 02-backend.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to deploy backend${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Backend deployment created${NC}"
echo ""

echo -e "${YELLOW}Step 5: Waiting for backend to be ready (this may take 1-2 minutes)...${NC}"
kubectl wait --for=condition=ready pod -l app=backend -n doomed-apt --timeout=300s
if [ $? -ne 0 ]; then
    echo -e "${RED}Backend pod failed to become ready${NC}"
    echo "Check logs with: kubectl logs -n doomed-apt -l app=backend"
    exit 1
fi
echo -e "${GREEN}✓ Backend is ready${NC}"
echo ""

echo -e "${YELLOW}Step 6: Deploying frontend application...${NC}"
kubectl apply -f 03-frontend.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to deploy frontend${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Frontend deployment created${NC}"
echo ""

echo -e "${YELLOW}Step 7: Waiting for frontend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=frontend -n doomed-apt --timeout=300s
if [ $? -ne 0 ]; then
    echo -e "${RED}Frontend pod failed to become ready${NC}"
    echo "Check logs with: kubectl logs -n doomed-apt -l app=frontend"
    exit 1
fi
echo -e "${GREEN}✓ Frontend is ready${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Application is now running:"
echo -e "  Frontend:    ${GREEN}http://localhost:32080${NC}"
echo -e "  Backend API: ${GREEN}http://localhost:32081${NC}"
echo -e "  MySQL:       ${GREEN}localhost:3306${NC}"
echo ""
echo "Login credentials:"
echo "  Username: guest"
echo "  Password: guest123"
echo ""
echo "Useful commands:"
echo "  View all resources:  kubectl get all -n doomed-apt"
echo "  View logs:           kubectl logs -n doomed-apt -l app=backend"
echo "  Delete deployment:   kubectl delete namespace doomed-apt"
echo ""
