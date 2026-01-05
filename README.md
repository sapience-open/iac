# iac
Infrastructure as Code for the Sapience Azure deployment.

This repository contains the Bicep template and CI workflow used to deploy the Ntier sample infrastructure to an Azure Resource Group.

**Repository layout**
- **Ntier/**: Bicep entrypoint at [Ntier/infra.bicep](Ntier/infra.bicep)
- **.github/workflows/main.yml**: GitHub Actions workflow that deploys the Bicep template

**Prerequisites**
- Install the Azure CLI: https://learn.microsoft.com/cli/azure
- Install Bicep tooling (bundled with recent Azure CLI) or `az bicep` commands
- A target Azure subscription and permission to create Resource Groups and resources

**Deploying**
- The repository uses a GitHub Actions workflow triggered manually (`workflow_dispatch`). The workflow file is [/.github/workflows/main.yml](.github/workflows/main.yml).
- The workflow deploys the template at [Ntier/infra.bicep](Ntier/infra.bicep). Ensure the following repository secrets are set in Settings → Secrets:
	- `AZURE_CLIENT_ID`
	- `AZURE_TENANT_ID`
	- `AZURE_SUBSCRIPTION_ID`
	- `WEB_APP_NAME` (if required by the bicep template)
	- `SQL_SERVER_NAME`, `SQL_DATABASE_NAME`, `SQL_ADMIN_LOGIN`, `SQL_ADMIN_PASSWORD` (if used)
	- `KEYVAULT_NAME`, `AFD_PROFILE_NAME`, `AFD_ENDPOINT_NAME` (if used)

**Local validation (recommended)**
- Validate and build the Bicep file locally:
```bash
az bicep build --file Ntier/infra.bicep
az deployment group what-if --resource-group rg-sapience-app-prod --template-file Ntier/infra.bicep --parameters location=westeurope
```

