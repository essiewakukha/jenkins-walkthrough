# Terraform AWS Infrastructure for React Deployment (Modular)

This Terraform configuration uses **reusable modules** to set up AWS infrastructure for deploying the React app via Jenkins CI/CD pipeline. The modular approach improves maintainability, reusability, and code organization.

## Architecture

```
terraform/
├── main.tf              # Root module - orchestrates child modules
├── variables.tf         # Root input variables
├── outputs.tf           # Root outputs from all modules
├── modules/
│   ├── s3/             # S3 bucket configuration
│   ├── cloudfront/     # CloudFront CDN and OAI
│   └── iam/            # IAM user and policies for Jenkins
├── terraform.tfvars.example
└── README.md
```

## What Gets Created

Through three reusable modules:

- **S3 Module** (`modules/s3/`) - S3 bucket with versioning and public access block
- **CloudFront Module** (`modules/cloudfront/`) - CDN distribution, OAI, and S3 bucket policy with SPA routing
- **IAM Module** (`modules/iam/`) - Jenkins deployment user with minimal required permissions

## Prerequisites

1. AWS Account with appropriate permissions
2. Terraform installed locally (>= 1.0)
3. AWS CLI configured with credentials: `aws configure`

## Architecture

```
terraform/
├── main.tf                      # Root module - orchestrates child modules
├── variables.tf                 # Root input variables
├── outputs.tf                   # Root outputs from all modules
├── terraform.tfvars.example     # Example variables file
├── BACKEND.md                   # Backend configuration documentation
├── MODULES.md                   # Module documentation
├── backends/                    # Backend configuration examples
│   ├── local.hcl.example        # Default local backend
│   ├── s3.hcl.example           # AWS S3 backend (team/production)
│   └── terraform-cloud.hcl.example  # Terraform Cloud backend
└── modules/
    ├── s3/                      # S3 bucket module
    ├── cloudfront/              # CloudFront CDN module
    └── iam/                     # IAM user module
```

## State Management

This configuration uses a **local backend** by default. The Terraform state file is stored locally:

```
terraform/terraform.tfstate
```

For details about backend configuration, team collaboration, and remote backends, see [BACKEND.md](BACKEND.md).

### Quick Backend Reference

**Current (Local):** Perfect for development and classroom demos  
**S3 Backend:** For team collaboration with state locking  
**Terraform Cloud:** Fully managed by HashiCorp  

See `backends/` directory for example configurations.

## Setup Instructions

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Update Variables

Copy the example file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
- Change `bucket_name` to a globally unique name (S3 requires this)
- Adjust `aws_region` if needed (default: us-east-1)

### 3. Plan Deployment

Review what Terraform will create:

```bash
terraform plan
```

### 4. Apply Configuration

Deploy to AWS:

```bash
terraform apply
```

When prompted, type `yes` to confirm.

### 5. Capture Outputs

Save the outputs for Jenkins configuration:

```bash
terraform output -json > outputs.json
```

**WARNING**: This file contains AWS credentials. Store it securely and never commit to Git.

## Jenkins Configuration

After Terraform completes, extract credentials from `outputs.json`:

```bash
terraform output jenkins_access_key_id
terraform output jenkins_secret_access_key
terraform output cloudfront_distribution_id
terraform output s3_bucket_name
```

### Add AWS Credentials to Jenkins

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Manage Credentials**
2. Click **Add Credentials**
3. Kind: **AWS Credentials**
4. Access Key ID: (from `terraform output jenkins_access_key_id`)
5. Secret Access Key: (from `terraform output jenkins_secret_access_key`)
6. ID: `aws-deploy-credentials`
7. Click **Create**

## Example Jenkinsfile

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm test'
                sh 'npm run build'
            }
        }
        
        stage('Deploy to S3') {
            steps {
                withAWS(credentials: 'aws-deploy-credentials', region: 'us-east-1') {
                    sh '''
                        aws s3 sync dist/ s3://YOUR_BUCKET_NAME --delete
                    '''
                }
            }
        }
        
        stage('Invalidate CloudFront') {
            steps {
                withAWS(credentials: 'aws-deploy-credentials', region: 'us-east-1') {
                    sh '''
                        aws cloudfront create-invalidation \
                            --distribution-id YOUR_DISTRIBUTION_ID \
                            --paths "/*"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Deployment successful!"
            echo "Site live at: https://YOUR_CLOUDFRONT_DOMAIN"
        }
    }
}
```

Replace placeholder values with outputs from `terraform output`.

## Accessing Output Values

Get individual outputs:

```bash
terraform output s3_bucket_name
terraform output cloudfront_domain_name
terraform output cloudfront_distribution_id
terraform output site_url
terraform output jenkins_user_name
```

Get all outputs as JSON:

```bash
terraform output -json
```

## Security Notes

- ✅ **S3 bucket is private** - Only CloudFront can read objects
- ✅ **HTTPS enforced** - CloudFront redirects HTTP to HTTPS
- ✅ **IAM user principle** - Jenkins user has minimal required permissions
- ⚠️ **Protect credentials** - Never commit `outputs.json` or AWS keys to Git
- ⚠️ **Rotate keys** - Periodically regenerate Jenkins access keys in IAM

## Cleanup

To destroy all AWS resources:

```bash
terraform destroy
```

When prompted, type `yes` to confirm.

## Troubleshooting

### Bucket Name Already Taken
S3 bucket names are globally unique. If you get an error, choose a different name in `terraform.tfvars`.

### Permission Denied Errors
Ensure your AWS credentials have permissions to create S3, CloudFront, and IAM resources.

### CloudFront Takes Time to Deploy
CloudFront distributions can take 5-10 minutes to fully propagate. Check status in AWS Console.

## For Class Demonstration

1. **Show infrastructure diagram**: Explain S3 → CloudFront → Jenkins workflow
2. **Live demo**: Run `terraform plan`, explain each resource
3. **Discuss costs**: Show AWS pricing (S3 and CloudFront have free tiers)
4. **Point out IAM**: Highlight principle of least privilege for Jenkins user
5. **Show Jenkins integration**: Demo the pipeline executing a deployment

## Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS S3 Static Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/HostingWebsiteOnS3Setup.html)
- [CloudFront for SPAs](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/custom-error-pages.html)
