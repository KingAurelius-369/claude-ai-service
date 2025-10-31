#!/bin/bash
# SLSA Attestation Generation Script
# Generates SLSA (Supply Chain Levels for Software Artifacts) attestations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/$(basename "$PROJECT_ROOT")}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
ATTESTATION_OUTPUT="${ATTESTATION_OUTPUT:-$PROJECT_ROOT/slsa-attestation.json}"

echo "🔐 Generating SLSA Attestation..."
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "Output: $ATTESTATION_OUTPUT"

# Verify required tools
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed."; exit 1; }

# Generate attestation metadata
cat > "$ATTESTATION_OUTPUT" << EOF
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "subject": [
    {
      "name": "$IMAGE_NAME:$IMAGE_TAG",
      "digest": {
        "sha256": "$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE_NAME:$IMAGE_TAG" 2>/dev/null | cut -d'@' -f2 | cut -d':' -f2 || echo 'unknown')"
      }
    }
  ],
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "predicate": {
    "builder": {
      "id": "https://github.com/actions/runner",
      "version": {
        "github-actions": "$(github --version 2>/dev/null || echo 'unknown')"
      }
    },
    "buildType": "https://github.com/actions/workflow",
    "metadata": {
      "buildInvocationId": "${GITHUB_RUN_ID:-$(date +%s)}",
      "completeness": {
        "parameters": true,
        "environment": false,
        "materials": false
      },
      "reproducible": false
    },
    "materials": [
      {
        "uri": "git+https://github.com/$(basename "$(dirname "$PROJECT_ROOT")")/$(basename "$PROJECT_ROOT").git",
        "digest": {
          "sha1": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
        }
      }
    ]
  }
}
EOF

echo "✅ SLSA attestation generated: $ATTESTATION_OUTPUT"

# Verify attestation format
if command -v jq >/dev/null 2>&1; then
    if jq . "$ATTESTATION_OUTPUT" >/dev/null 2>&1; then
        echo "✅ Attestation JSON format is valid"
    else
        echo "❌ Attestation JSON format is invalid"
        exit 1
    fi
else
    echo "⚠️  jq not found, skipping JSON validation"
fi

echo "🔐 SLSA attestation generation complete!"
