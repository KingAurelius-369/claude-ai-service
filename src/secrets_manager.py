#!/usr/bin/env python3
import os
import getpass
import asyncio
from typing import Optional

class SecretsManager:
    _github_token: Optional[str] = None
    _conjur_client = None
    _secret_backend: str = "env"

    @classmethod
    async def initialize_conjur(cls) -> None:
        """Initialize CyberArk Conjur client if configured."""
        secret_backend = os.environ.get("SECRET_BACKEND", "env")
        if secret_backend != "conjur":
            return

        use_mock = os.environ.get("CONJUR_MOCK", "false").lower() == "true"

        try:
            if use_mock:
                from mock_conjur import MockConjurClient
                cls._conjur_client = MockConjurClient()
                cls._conjur_client.login()
                cls._secret_backend = "conjur"
                return

            from conjur_api import Client
            from conjur_api.models import ConjurConnectionInfo, SslVerificationMode, CredentialsData
            from conjur_api.providers import SimpleCredentialsProvider, AuthnAuthenticationStrategy

            conjur_url = os.environ.get("CONJUR_URL")
            conjur_account = os.environ.get("CONJUR_ACCOUNT")
            conjur_username = os.environ.get("CONJUR_USERNAME")
            conjur_password = os.environ.get("CONJUR_PASSWORD")

            if not all([conjur_url, conjur_account, conjur_username, conjur_password]):
                raise ValueError("Missing Conjur configuration: CONJUR_URL, CONJUR_ACCOUNT, CONJUR_USERNAME, CONJUR_PASSWORD")

            connection_info = ConjurConnectionInfo(
                conjur_url=conjur_url,
                account=conjur_account,
                cert_file=None,
                service_id=None
            )

            credentials = CredentialsData(
                username=conjur_username,
                password=conjur_password,
                machine=conjur_url
            )
            credentials_provider = SimpleCredentialsProvider()
            credentials_provider.save(credentials)

            authn_strategy = AuthnAuthenticationStrategy(credentials_provider)

            cls._conjur_client = Client(
                connection_info,
                authn_strategy=authn_strategy,
                ssl_verification_mode=SslVerificationMode.INSECURE
            )
            await cls._conjur_client.login()
            cls._secret_backend = "conjur"
        except ImportError:
            raise ImportError("conjur-api package not installed. Install with: pip install conjur-api")
        except Exception as e:
            raise RuntimeError(f"Failed to initialize Conjur client: {e}")

    @classmethod
    def initialize_conjur_sync(cls) -> None:
        """Synchronous wrapper for initialize_conjur."""
        asyncio.run(cls.initialize_conjur())

    @classmethod
    async def get_secret_async(cls, secret_path: str) -> str:
        """
        Get secret from configured backend (env, conjur, aws, azure, vault) - async version.
        """
        if cls._secret_backend == "conjur" and cls._conjur_client:
            try:
                secret = await cls._conjur_client.get(secret_path)
                if isinstance(secret, bytes):
                    return secret.decode('utf-8')
                return secret
            except Exception as e:
                raise RuntimeError(f"Failed to retrieve secret '{secret_path}' from Conjur: {e}")
        else:
            env_var = secret_path.replace("/", "_").upper()
            return os.environ.get(env_var, "")

    @classmethod
    def get_secret(cls, secret_path: str) -> str:
        """
        Get secret from configured backend (env, conjur, aws, azure, vault) - sync wrapper.
        """
        if cls._secret_backend == "conjur" and cls._conjur_client:
            return asyncio.run(cls.get_secret_async(secret_path))
        else:
            env_var = secret_path.replace("/", "_").upper()
            return os.environ.get(env_var, "")

    @classmethod
    def get_github_token(cls) -> str:
        """
        Get GitHub token from configured backend or prompt user.
        Token is not stored in files, only kept in memory during runtime.
        """
        if cls._github_token:
            return cls._github_token

        if cls._secret_backend == "conjur" and cls._conjur_client:
            try:
                token = cls.get_secret("github/token")
                if token and token.strip():
                    cls._github_token = token
                    return token
            except Exception:
                pass

        token = os.environ.get("GITHUB_TOKEN")

        if not token:
            if os.environ.get("CONJUR_MOCK", "false").lower() == "true":
                # In mock mode, don't prompt - use mock token
                token = "mock-github-token-12345"
            else:
                token = getpass.getpass("Enter your GitHub token: ")

        if not token:
            raise ValueError("GitHub token is required")

        cls._github_token = token
        return token

    @classmethod
    def clear_github_token(cls) -> None:
        """Clear token from memory."""
        cls._github_token = None
