#!/usr/bin/env python3
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from secrets_manager import SecretsManager


def test_mock_conjur():
    print("Testing local Conjur mock setup...")
    print()

    os.environ["SECRET_BACKEND"] = "conjur"
    os.environ["CONJUR_MOCK"] = "true"
    os.environ["GITHUB_TOKEN"] = "test-github-token-xyz"

    try:
        SecretsManager.initialize_conjur()
        print("✓ Mock Conjur initialized successfully")
        print()

        print("Testing secret retrieval:")
        token = SecretsManager.get_github_token()
        print(f"✓ GitHub token retrieved: {token[:20]}...")
        print()

        print("Testing get_secret method:")
        semgrep_token = SecretsManager.get_secret("semgrep/app-token")
        print(f"✓ Semgrep token retrieved: {semgrep_token[:20]}...")
        print()

        print("Testing mock client directly:")
        secrets = SecretsManager._conjur_client.list()
        print(f"✓ Available secrets: {', '.join(secrets)}")
        print()

        print("Testing secret retrieval for all backends:")
        for secret_path in secrets:
            secret = SecretsManager.get_secret(secret_path)
            print(f"  {secret_path}: {secret[:30]}...")
        print()

        print("All tests passed! ✓")
        return 0

    except Exception as e:
        print(f"✗ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return 1
    finally:
        SecretsManager.clear_github_token()


if __name__ == "__main__":
    sys.exit(test_mock_conjur())
