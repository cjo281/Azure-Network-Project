AZURE INFRASTRUCTURE DEPLOYMENT WITH BICEP & GITHUB ACTIONS
This project automates the deployment of a complete Azure infrastructure using Bicep and GitHub Actions. It provisions a virtual network, subnets, network security groups, virtual machines, and monitoring — all orchestrated through a robust CI/CD pipeline.

PROJECT OVERVIEW
Bicep Template: azure-network3.2.bicep
    This file defines the infrastructure:

    - Virtual Network with two subnets: WebSubnet3.2 and AppSubnet3.2
    - Network Security Groups for each subnet with custom rules
    - Virtual Machines: WebVM3.2 and AppVM3.2 with static IPs
    - NICs for VM connectivity
    - Log Analytics Workspace for monitoring
    - Optional NAT Gateway (commented out for future use)

GITHUB ACTIONS WORKFLOWS 
All workflows are located in ".github/workflows/"

    Workflow	
        deploy.yml
        Purpose: Primary deployment to staging on every push to main
        approval-deploy.yml	
        Purpose: Deploys to production with manual approval gate
        output.yml	
        Purpose: Captures and logs deployment outputs (e.g., VM IPs, workspace ID)
        rollback.yml	
        Purpose: Automatically rolls back using a backup Bicep file if deployment fails
        scheduled-deploy.yml	
        Purpose: Runs daily at 2 AM UTC to deploy infrastructure on a schedule

SECRETS REQUIRED
Set the following secrets in your GitHub repository:
    AZURE_CREDENTIALS: Azure service principal credentials in JSON format
    ADMIN_PASSWORD: Secure password for VM admin user

DEPLOYMENT FLOW
1. Push to main triggers:
    - deploy.yml → deploys to staging
    - approval-deploy.yml → waits for manual approval before deploying to production
    - output.yml → logs deployment outputs

2. Failure in deploy.yml triggers:
    - rollback.yml → deploys azure-network3.2-backup.bicep

3. Scheduled Deployment:
    - scheduled-deploy.yml runs daily at 2 AM UTC

OUTPUTS CAPTURED
From the Bicep deployment:

    - webVMIP: Static IP of Web VM
    - appVMIP: Static IP of App VM
    - workspaceId: ID of the Log Analytics workspace

FILE STRUCTURE
.github/workflows/
├── deploy.yml
├── approval-deploy.yml
├── output.yml
├── rollback.yml
├── scheduled-deploy.yml

azure-network3.2.bicep
azure-network3.2-backup.bicep

NOTES:
    - All workflows use ubuntu-latest runners
    - Environment protection is enabled for production deployments
    - Rollback is triggered only on failure or manual dispatch
    - You can extend this setup for additional projects by duplicating the Bicep and workflow files