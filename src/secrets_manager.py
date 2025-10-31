#!/usr/bin/env python3
import os
import getpass
from typing import Optional

class SecretsManager:
    _github_token: Optional[str] = None

    @classmethod
    def get_github_token(cls) -> str:
        """
        Get GitHub token from environment variable or prompt user.
        Token is not stored in files, only kept in memory during runtime.
        """
        if cls._github_token:
            return cls._github_token

        token = os.environ.get("GITHUB_TOKEN")

        if not token:
            token = getpass.getpass("Enter your GitHub token: ")

        if not token:
            raise ValueError("GitHub token is required")

        cls._github_token = token
        return token

    @classmethod
    def clear_github_token(cls) -> None:
        """Clear token from memory."""
        cls._github_token = None
