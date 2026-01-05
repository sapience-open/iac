Azure ↔ GitHub Actions OIDC (Workload Identity Federation)

This repository uses GitHub Actions with Azure Workload Identity Federation (OIDC) to authenticate securely with Azure without client secrets.

OIDC replaces long-lived credentials with short-lived tokens issued at runtime, improving security and reducing operational overhead.

🔐 What This Setup Does

Uses Microsoft Entra ID (Azure AD) workload identity federation

Authenticates GitHub Actions → Azure via OIDC

Eliminates the need for stored Azure client secrets

Supports least-privilege RBAC

Designed for Bicep / ARM deployments

📚 Key Azure Documentation
Core Concepts (Start Here)

Workload Identity Federation Overview
https://learn.microsoft.com/entra/workload-id/workload-identity-federation

Connect GitHub Actions to Azure (OIDC)
Step-by-step guide covering App Registration, federated credentials, and workflows
https://learn.microsoft.com/azure/developer/github/connect-from-azure

azure/login GitHub Action
Official GitHub Action used for OIDC authentication
https://github.com/Azure/login

🧾 Azure App Registration & RBAC

Create an App Registration
https://learn.microsoft.com/entra/identity-platform/quickstart-register-app

Add Federated Credentials
Defines trust between GitHub repo/workflow and Azure
https://learn.microsoft.com/entra/identity-platform/workload-identity-federation-create-trust

Assign Azure RBAC Roles
Grant least-privilege access (e.g. Contributor at RG scope)
https://learn.microsoft.com/azure/role-based-access-control/role-assignments-portal

⚠️ Avoid Owner unless absolutely required.

🚀 Deploying Infrastructure (Bicep)

Deploy Bicep with GitHub Actions
https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-github-actions

ARM / Resource Group Deployments
https://learn.microsoft.com/azure/azure-resource-manager/templates/deploy-cli

🧠 Security Best Practices

OIDC Security Guidance
https://learn.microsoft.com/entra/workload-id/workload-identity-federation-security-best-practices

GitHub OIDC Token Claims
Understand sub, aud, and iss claims
https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect

Recommended hardening:

Scope federated credentials to:

Repository

Branch

Environment

Assign RBAC at resource group level

Avoid subscription-wide permissions

🧪 Troubleshooting

Common Azure ↔ GitHub OIDC Errors
(AADSTS70021, subject mismatch, etc.)
https://learn.microsoft.com/azure/developer/github/troubleshoot-connect-from-azure

Debugging Federated Identity Issues
https://learn.microsoft.com/entra/workload-id/workload-identity-federation-debug

✅ Minimum Required GitHub Permissions

Your workflow must include:

permissions:
  id-token: write
  contents: read


Without id-token: write, OIDC authentication will fail.

📌 Recommended Bookmarks (TL;DR)

If you only keep three links:

https://learn.microsoft.com/azure/developer/github/connect-from-azure

https://github.com/Azure/login

https://learn.microsoft.com/entra/workload-id/workload-identity-federation

📬 Notes

OIDC tokens are short-lived and issued per workflow run

No Azure secrets are stored in GitHub

This approach is suitable for production workloads