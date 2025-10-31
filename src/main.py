#!/usr/bin/env python3
from secrets_manager import SecretsManager

def main():
    print("Claude AI Service")

    try:
        token = SecretsManager.get_github_token()
        print("GitHub token loaded successfully")
    except ValueError as e:
        print(f"Error: {e}")
        return 1
    finally:
        SecretsManager.clear_github_token()

    return 0

if __name__ == "__main__":
    exit(main())
