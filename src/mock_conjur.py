#!/usr/bin/env python3
import os
from typing import Dict


class MockConjurClient:
    """Mock Conjur client for local testing without Docker."""

    def __init__(self):
        self.secrets: Dict[str, str] = {
            "github/token": os.environ.get("GITHUB_TOKEN", "mock-github-token-12345"),
            "semgrep/app-token": os.environ.get("SEMGREP_APP_TOKEN", "mock-semgrep-token"),
            "aws/access-key": os.environ.get("AWS_ACCESS_KEY_ID", "AKIAIOSFODNN7EXAMPLE"),
            "aws/secret-key": os.environ.get(
                "AWS_SECRET_ACCESS_KEY", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
            ),
            "azure/credentials": os.environ.get("AZURE_CREDENTIALS", "mock-azure-creds"),
        }

    def login(self) -> None:
        """Mock login - no-op."""
        pass

    def get(self, variable_id: str) -> str:
        """Retrieve secret from mock store."""
        if variable_id not in self.secrets:
            raise KeyError(f"Secret '{variable_id}' not found in mock Conjur")
        return self.secrets[variable_id]

    def get_many(self, variable_ids: list) -> Dict[str, str]:
        """Retrieve multiple secrets from mock store."""
        result = {}
        for var_id in variable_ids:
            try:
                result[var_id] = self.get(var_id)
            except KeyError:
                result[var_id] = None
        return result

    def set(self, variable_id: str, value: str) -> None:
        """Set secret in mock store."""
        self.secrets[variable_id] = value

    def list(self) -> list:
        """List all secrets in mock store."""
        return list(self.secrets.keys())
