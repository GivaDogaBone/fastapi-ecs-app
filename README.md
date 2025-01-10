## GivaDogaBone
Let's walk through the process of creating a **FastAPI application** built with **Poetry**, and deploying it using **GitHub Actions** into **AWS ECS Fargate**. I will provide the detailed **end-to-end instructions**, including creating the application, using Poetry for dependencies, Dockerizing it, and automating the deployment with GitHub Actions.

---

### **Step 1: Set Up the FastAPI Project Using Poetry**

We'll use **Poetry** for dependency management and application packaging.

---

#### 1.1 Initialize the Project:
Start by creating a new FastAPI project with Poetry.

```shell script
mkdir fastapi-poetry-ecs
cd fastapi-poetry-ecs
poetry init --name fastapi-ecs-app --description "FastAPI application for ECS Fargate" --author "Your Name <your-email@example.com>" --python "^3.11"
```

During initialization, answer prompts for package info. The `pyproject.toml` will be created automatically.

---

#### 1.2 Add Dependencies:
Install the required dependencies using Poetry:

```shell script
poetry add fastapi uvicorn
```

- **fastapi**: Core web framework.
- **uvicorn**: ASGI server to run the FastAPI app.

For development, you can add optional tools:

```shell script
poetry add --group dev pytest black isort
```

---

#### 1.3 Create the Application Structure:
Inside the project directory, create the following folder structure:

```
fastapi-poetry-ecs/
├── app/
│   ├── __init__.py
│   ├── main.py
├── Dockerfile
├── pyproject.toml
├── README.md
└── .github/
    └── workflows/
        └── deploy.yml
```

---

#### 1.4 Write the FastAPI Application:
Write the FastAPI application in **`app/main.py`**:

```python
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def read_root():
    return {"message": "Welcome to the FastAPI ECS Fargate app!"}


@app.get("/hello/{name}")
def read_item(name: str):
    return {"message": f"Hello {name}!"}
```

---

### **Step 2: Dockerize the FastAPI Application**

We'll use Docker to package the FastAPI application into a container.

---

#### 2.1 Create a `Dockerfile`:
Add the **`Dockerfile`** to the root of your project:

```dockerfile
# Use an official Python lightweight image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install Poetry
RUN pip install poetry

# Copy project files
COPY ./pyproject.toml ./poetry.lock* /app/

# Install dependencies
RUN poetry install --no-dev --no-root

# Copy application code
COPY ./app /app/app

# Expose port 80 to the outside
EXPOSE 80

# Command to run the FastAPI app with Uvicorn
CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
```

This Dockerfile uses Poetry to manage dependencies within the container.

---

### **Step 3: Push the Code to GitHub**

1. Create a new GitHub repository, e.g., `fastapi-ecs-app`.
2. Push your code to the repository:

```shell script
git init
git remote add origin https://github.com/<your-username>/fastapi-ecs-app.git
git add .
git commit -m "Initial commit"
git branch -M main
git push -u origin main
```

---

### **Step 4: Set Up AWS ECS**

We'll deploy the application to **AWS ECS** using **Fargate**. Make sure you have the **AWS CLI** configured with the necessary permissions.

---

#### 4.1 Create an ECS Cluster:
1. Go to the AWS Management Console.
2. Navigate to **ECS > Clusters > Create Cluster**.
3. Select **Networking only > Fargate**.
4. Provide a cluster name (e.g., `fastapi-ecs-cluster`).

---

#### 4.2 Create an Amazon ECR Repository:
1. Navigate to AWS **ECR (Elastic Container Registry)**.
2. Create a new repository, e.g., `fastapi-ecs-app`.
3. Note the repository URI (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/fastapi-ecs-app`).

---

#### 4.3 Set Up a Task Definition:
1. Go to ECS > Task Definitions > Create new task definition.
2. Configure it for Fargate:
   - Add a container:
     - Image URI: `<ECR_REPO_URI>:latest`
     - Port mappings: Expose port 80.
   - Set memory (e.g., **512 MiB**) and vCPU (e.g., **0.25 vCPU**).

---

### **Step 5: Automate Deployment With GitHub Actions**

We will create a **GitHub Actions workflow** to automate the deployment process.

---

#### 5.1 Create the Workflow File:
Add a file `.github/workflows/deploy.yml`:

```yaml
name: Deploy FastAPI to AWS ECS

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    # Step 1: Checkout the repository
    - name: Checkout code
      uses: actions/checkout@v3

    # Step 2: Log in to Amazon ECR
    - name: Log in to Amazon ECR
      id: ecr-login
      uses: aws-actions/amazon-ecr-login@v1

    # Step 3: Build and Push Docker Image
    - name: Build, Tag, and Push Image to Amazon ECR
      env:
        ECR_REPOSITORY: fastapi-ecs-app
        AWS_REGION: us-east-1
        IMAGE_TAG: latest
      run: |
        # Build Docker image
        docker build -t $ECR_REPOSITORY:$IMAGE_TAG .
        
        # Tag the image for ECR
        docker tag $ECR_REPOSITORY:$IMAGE_TAG ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

        # Push the image
        docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

    # Step 4: Deploy to ECS
    - name: Deploy to ECS
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: ecs-task-definition.json
        service: fastapi-ecs-service
        cluster: fastapi-ecs-cluster
        wait-for-service-stability: true
```

---

#### 5.2 Add GitHub Secrets:
Go to your GitHub Repository > Settings > Secrets and Variables > Actions and add:

- `AWS_ACCESS_KEY_ID`: Your AWS Access Key.
- `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Key.
- `AWS_ACCOUNT_ID`: Your AWS Account ID.

---

#### 5.3 Push and Deploy:
On pushing to the `main` branch:

1. GitHub Actions will build the Docker image, push it to Amazon ECR, and deploy it to ECS.
2. Once deployed, you can access the application via the load balancer or public ECS service endpoint.

---

### **Step 6: Test the Deployment**

1. Visit your application URL in the browser (e.g., ALB DNS or ECS public IP):
```
http://<your-alb-public-dns>/
```
   This should return:
```json
{"message": "Welcome to the FastAPI ECS Fargate app!"}
```

2. Test various endpoints (e.g., `/hello/<name>`).

---

### **Summary**
You now have:
1. A **FastAPI** application built with **Poetry**.
2. Dockerized and deployed to **AWS ECS Fargate** using GitHub Actions.
3. Automated build, Docker image push, and deployment workflow with GitHub Actions.

Let me know if you'd like help debugging or with any specific part of the workflow!
