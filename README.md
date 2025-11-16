# 🚀 EpicBook AWS Infrastructure (EC2 + RDS)

This Terraform project provisions a secure, production-ready AWS environment for hosting a web application - **EpicBook**. It includes:

- A custom VPC with public and private subnets across two Availability Zones  
- A publicly accessible EC2 instance for the frontend application 
- A private, highly available Amazon RDS MySQL instance for the database tier
- Proper networking, security groups, and IAM-free access control 
- Secure SSH key-based authentication

All resources are deployed in the us-west-1 region (configurable).

---

## 📁 Project Structure

```bash
aws-epicbook/
├── main.tf          # Core infrastructure definitions
├── variables.tf     # Input variables (customizable)
├── outputs.tf       # Useful outputs after deployment
└── README.md        # This file
```

---

## 🛠️ Prerequisites

Before you deploy, ensure you have:

1. **[Terraform](https://www.terraform.io/downloads.html)** installed (`v1.3+` recommended)
2. **[AWS CLI](https://aws.amazon.com/cli/)** installed and configured:
3. An SSH key pair for EC2 access (or generate one as shown below)

> 💡 **Permissions**: Your AWS user needs permissions to create VPC, EC2, RDS, Security Groups, and Key Pairs.

---

## 🔐 SSH Key Setup

You must provide an SSH public key for secure EC2 access.

### Option A: Use an existing key
- Ensure your public key (e.g., `~/.ssh/id_rsa.pub`) exists.
- Set `ssh_public_key_path` in `terraform.tfvars` (see below).

### Option B: Generate a new key (Linux/macOS)
```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/epicbook-key -N ""
# Public key: ~/.ssh/epicbook-key.pub
# Private key: ~/.ssh/epicbook-key (KEEP SECURE!)
```

## ⚙️ Configuration

### 1. Create `terraform.tfvars`
Create a file named `terraform.tfvars` in this directory to set your variables:

```hcl
# terraform.tfvars
region            = "us-west-1"
vpc_name          = "epicbook-vpc"

# EC2
ec2_instance_type = "t3.micro"
ssh_public_key_path = "~/.ssh/epicbook-key.pub"  # Path to your PUBLIC key

# RDS
rds_instance_class = "db.t3.micro"
rds_username       = "admin"
rds_password       = "MySecurePassword123!"  # Must be 8-41 chars, include letters & numbers
rds_name           = "epicbook-mysql"
```

---

## ▶️ Deployment

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Preview changes**:
   ```bash
   terraform plan
   ```

3. **Deploy**:
   ```bash
   terraform apply
   ```

4. Approve the plan when prompted.

> ⏱️ Deployment takes about **5–10 minutes**.

---

## 📤 Outputs

After deployment, Terraform shows useful info:

```bash
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

ec2_instance_id = "i-0abcd1234efgh5678"
ec2_public_ip   = "203.0.113.25"
rds_endpoint    = "epicbook-mysql.cxyzxyzxyz.us-west-1.rds.amazonaws.com:3306"
vpc_id          = "vpc-0a1b2c3d4e5f6g7h8"
```

Use these to connect to your resources.

---

## 🔌 Connecting to Your Resources

### 1. SSH into EC2 Instance
```bash
ssh -i ~/.ssh/epicbook-key ec2-user@<ec2_public_ip>
# Example:
ssh -i ~/.ssh/epicbook-key ec2-user@203.0.113.25
```

or you can connect through the AWS console

> 🐧 **Usernames**:
> - Amazon Linux: `ec2-user`
> - Ubuntu: `ubuntu`

### 2. Configure EC2 instance for the web application
Use this guide to install dependencies: [EpicBook](https://github.com/pravinmishraaws/theepicbook/blob/main/Installation%20%26%20Configuration%20Guide.md)
Or you can follow along below: (ensure to put in each command one at a time)
```bash
sudo yum update -y

sudo yum install -y https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
sudo yum-config-manager --disable mysql80-community
sudo yum-config-manager --enable mysql57-community

sudo yum install -y mysql-community-server
sudo systemctl start mysqld
sudo systemctl status mysqld

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
source ~/.nvm/nvm.sh
nvm install v17
node -v

sudo yum install git -y
git clone https://github.com/pravinmishraaws/theepicbook
cd theepicbook
npm install

mysql -h <rds_endpoint> -u <rds_username> -p #input db password when prompted
CREATE DATABASE bookstore; #inside mysql
SOURCE db/BuyTheBook_Schema.sql;
SOURCE db/author_seed.sql;
SOURCE db/books_seed.sql;
\q #exit mysql

sudo nano config/config.json #update config.json with database details. value of host should be replaced with rds_endpoint

sudo yum install -y epel-release
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx

echo 'server {
    listen 80;
    server_name your_domain_or_IP;  # input ec2 public ip here

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}' sudo tee /etc/nginx/conf.d/theepicbooks.conf > /dev/null

sudo nginx -t    # Check for syntax errors
sudo systemctl restart nginx

node server.js # start application
```

### 3. Connect to RDS from EC2 using the console


> 🔒 RDS is **not publicly accessible** — you **must connect via EC2** (or a bastion host).

### 4. Verify the setup
Check if the application is running:
```bash
http://<PublicIP>
```
If everything is set up correctly, you should see The EpicBook! application running.

---

## 🧹 Cleanup

To **destroy all resources** (to avoid charges):

```bash
terraform destroy
```

> ⚠️ This deletes **everything**, including your database! Ensure you’ve backed up data.

---

## 📌 Best Practices Implemented

- ✅ VPC with public/private subnets (multi-AZ)
- ✅ RDS in private subnets, not publicly accessible
- ✅ Security groups restrict access (EC2 → RDS only)
- ✅ SSH key authentication (no passwords)
- ✅ No hardcoded credentials in code (use `tfvars` or env vars)
- ✅ DB subnet group meets AWS high-availability requirements

---

## ❓ Troubleshooting

| Issue | Solution |
|------|--------|
| `InvalidSubnet.Conflict` | Ensure VPC uses **private IP range** (`10.0.0.0/8`, `172.16.0.0/12`, or `192.168.0.0/16`) |
| RDS not accessible from EC2 | Verify: (1) same VPC, (2) RDS SG allows EC2 SG, (3) RDS is not public |
| `user_data` not running | Use `terraform taint aws_instance.app_instance` to force re-run on next apply |
| DNS resolution failure | Ensure your machine has internet access when running `terraform apply` |
