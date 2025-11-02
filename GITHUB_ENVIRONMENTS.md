# GitHub Environments Setup

## Overview
The CI/CD workflow includes deployment to staging and production environments that require GitHub environment configuration.

## Current State
Environment references are commented out in `.github/workflows/secure-ci-cd.yml` to prevent validation errors:
- Lines 224-226: staging environment
- Lines 242-244: production environment

## Setting Up GitHub Environments

### 1. Create Environments
1. Go to repository Settings → Environments
2. Click "New environment"
3. Create environments named:
   - `staging`
   - `production`

### 2. Configure Environment Settings

#### Staging Environment
- **Name**: `staging`
- **URL**: `https://staging.example.com` (update with actual URL)
- **Protection Rules** (optional):
  - Required reviewers: Add team members
  - Wait timer: 0 minutes
  - Deployment branches: `main` and `develop`

#### Production Environment
- **Name**: `production`
- **URL**: `https://production.example.com` (update with actual URL)
- **Protection Rules** (recommended):
  - Required reviewers: Add senior team members
  - Wait timer: 5-10 minutes
  - Deployment branches: `main` only

### 3. Environment Variables & Secrets
Add deployment-specific secrets for each environment:
- `DEPLOY_TOKEN`: Deployment authentication token
- `REGISTRY_PASSWORD`: Container registry password
- `CONJUR_PRODUCTION_URL`: Production Conjur endpoint
- Any other environment-specific configuration

### 4. Enable Environments in Workflow
Once environments are created, uncomment the environment sections in the workflow:

```yaml
environment:
  name: staging
  url: https://staging.example.com
```

```yaml
environment:
  name: production
  url: https://production.example.com
```

## Benefits of GitHub Environments
- **Manual approval gates** for production deployments
- **Environment-specific secrets** management
- **Deployment history** and rollback capabilities
- **Branch protection** for deployment targets
- **Wait timers** for staged rollouts