# 🚀 Django CI/CD Pipeline with AWS Terraform Deployment

This project sets up a **CI/CD pipeline** for a Django application using **GitHub Actions** and deploys infrastructure on **AWS** using **Terraform**.

## 📌 CI/CD Pipeline Workflow  
The pipeline triggers on:
- Push to `main` and `july-updates` branches  
- Pull requests to `main`  

### 🔧 Steps in the Workflow  
1. **Checkout Repository**  
2. **Set up Python (3.10) & Install Dependencies**  
3. **Run Migrations & Unit Tests**  
4. *(Optional)* Deploy to AWS Lightsail (commented out)  

Run tests locally:  
```sh
python manage.py migrate  
python manage.py test shop.tests  

🌍 AWS Infrastructure (Terraform)
Terraform provisions:

VPC (10.0.0.0/16) with Public & Private Subnets in ap-south-1
Internet Gateway & Route Table for public access
Security Group allowing SSH, HTTP, HTTPS
EC2 Instance (t3.micro, Amazon Linux 2)
✅ Deploy Terraform
terraform init  
terraform plan  
terraform apply -auto-approve  
❌ Destroy Resources
terraform destroy -auto-approve  
🔑 Configuration
Update aws_instance key name (ajithdroidal).
Set GitHub Secrets for AWS deployment.
👤 Author: Ajith
