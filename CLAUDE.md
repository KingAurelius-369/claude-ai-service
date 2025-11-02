# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude AI Service is a Python-based secrets management application that integrates with CyberArk Conjur and other secret backends. It demonstrates secure token handling patterns with support for GitHub authentication and multiple cloud provider integration.

## Architecture

### Core Components
- **Main Application**: `src/main.py` - Entry point that demonstrates the secrets manager workflow
- **Secrets Management**: `src/secrets_manager.py` - Multi-backend secrets manager supporting:
  - Environment variables (default)
  - CyberArk Conjur (production)
  - Mock Conjur client (testing)
  - Future support for AWS, Azure, Vault
- **Mock Implementation**: `src/mock_conjur.py` - Testing client that mimics Conjur API without Docker
- **Configuration**: `defaults/secrets-map.yml` - Maps required/optional environment variables by backend

### Docker Infrastructure
- **Main Service**: Python 3.11 slim container
- **Conjur Stack**: Full CyberArk Conjur setup via `docker-compose.yml`:
  - Conjur server with PostgreSQL backend
  - NGINX proxy with SSL termination
  - Ubuntu client container for testing
  - Volume persistence for data and certificates

## Development Commands

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run application directly
python src/main.py

# Run with mock Conjur (no Docker required)
CONJUR_MOCK=true python src/main.py
```

### Code Quality & Testing
```bash
# Run linting
ruff check src/
ruff format src/ --check

# Fix linting issues
ruff check --fix src/
ruff format src/

# Run security scans
bandit -r src/ -f txt
safety check

# Run tests
pytest test_conjur_setup.py -v --cov=src --cov-report=xml --cov-report=term-missing

# Test with mock backend
CONJUR_MOCK=true pytest test_conjur_setup.py -v
```

### Docker Development
```bash
# Build application
docker build -t claude-ai-service .

# Run full Conjur stack
docker-compose up -d

# Check Conjur health
curl -k https://localhost:443/health

# Run application container
docker run claude-ai-service
```

### CI/CD Pipeline
The project uses a comprehensive secure CI/CD pipeline (`.github/workflows/secure-ci-cd.yml`) that:
- Tests on Python 3.10, 3.11, 3.12
- Runs security scans (Bandit, Safety, Trivy)
- Performs code quality checks (Ruff linting/formatting)
- Builds multi-architecture Docker images
- Includes integration and deployment stages

### Environment Configuration
The application supports multiple secret backends via `SECRET_BACKEND` environment variable:

- `env` (default): Uses environment variables
- `conjur`: Connects to CyberArk Conjur
- `aws/azure/vault`: Planned future implementations

Required environment variables are documented in `defaults/secrets-map.yml`.

## Key Implementation Patterns

### Security-First Design
- GitHub tokens never persist to disk - memory-only storage
- Automatic token cleanup via `SecretsManager.clear_github_token()`
- Multi-backend abstraction through `SecretsManager.get_secret()`
- SSL/TLS configuration for Conjur connections

### Backend Abstraction
The `SecretsManager` class provides a unified interface:
- Runtime backend selection based on configuration
- Graceful fallback from Conjur to environment variables
- Mock client support for development without infrastructure

### Development Infrastructure
- Complete Docker Compose setup for local Conjur testing
- SSL certificate management for secure connections
- Health checks and dependency ordering for reliable startup

## Deployment Scripts
DevSecOps utility scripts in `scripts/` directory (placeholders for future implementation):
- `attest_slsa.sh` - SLSA attestation generation
- `generate_sbom.sh` - Software Bill of Materials
- `sign_image.sh` - Container image signing
- `deploy_multi_cloud.sh` - Multi-cloud deployment

## Testing Patterns

### Mock Testing
- Use `CONJUR_MOCK=true` environment variable to enable mock client for testing without Docker infrastructure
- Mock client (`src/mock_conjur.py`) provides realistic test data including GitHub tokens, AWS keys, etc.
- Test file `test_conjur_setup.py` demonstrates complete mock workflow testing

### CI/CD Testing Strategy
- **Security-first**: All code must pass Bandit security scan and Safety dependency check
- **Multi-version**: Tests run on Python 3.10, 3.11, 3.12 to ensure compatibility
- **Code quality**: Ruff linting and formatting enforced with `# nosec` comments for legitimate security exceptions
- **Coverage**: Pytest with coverage reporting, mock mode enabled by default in CI

### Python Version Requirements
- **Minimum**: Python 3.10 (due to `conjur-api>=0.1.7` dependency)
- **Recommended**: Python 3.11 (matches Docker container)
- **Ruff target**: py310 (configured in `pyproject.toml`)
