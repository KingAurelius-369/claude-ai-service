#!/bin/bash
# Software Bill of Materials (SBOM) Generation Script
# Generates comprehensive SBOM for security and compliance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
SBOM_OUTPUT="${SBOM_OUTPUT:-$PROJECT_ROOT/sbom.json}"
SBOM_FORMAT="${SBOM_FORMAT:-spdx-json}"
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/$(basename "$PROJECT_ROOT")}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "📜 Generating Software Bill of Materials (SBOM)..."
echo "Format: $SBOM_FORMAT"
echo "Output: $SBOM_OUTPUT"

# Check for syft tool (recommended for SBOM generation)
if command -v syft >/dev/null 2>&1; then
    echo "✅ Using syft for SBOM generation"
    if [ -n "${IMAGE_NAME:-}" ] && docker image inspect "$IMAGE_NAME:$IMAGE_TAG" >/dev/null 2>&1; then
        # Generate SBOM from Docker image
        echo "Generating SBOM from Docker image: $IMAGE_NAME:$IMAGE_TAG"
        syft "$IMAGE_NAME:$IMAGE_TAG" -o "$SBOM_FORMAT=$SBOM_OUTPUT"
    else
        # Generate SBOM from source code
        echo "Generating SBOM from source directory: $PROJECT_ROOT"
        syft "dir:$PROJECT_ROOT" -o "$SBOM_FORMAT=$SBOM_OUTPUT"
    fi
else
    echo "⚠️  syft not found, generating basic SBOM manually"

    # Manual SBOM generation for Python dependencies
    cat > "$SBOM_OUTPUT" << EOF
{
  "SPDXID": "SPDXRef-DOCUMENT",
  "spdxVersion": "SPDX-2.3",
  "creationInfo": {
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "creators": ["Tool: manual-sbom-generator"]
  },
  "name": "$(basename "$PROJECT_ROOT")",
  "dataLicense": "CC0-1.0",
  "packages": [
EOF

    # Add Python dependencies if requirements.txt exists
    if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        echo "    {" >> "$SBOM_OUTPUT"
        echo "      \"SPDXID\": \"SPDXRef-Python-Requirements\"," >> "$SBOM_OUTPUT"
        echo "      \"name\": \"python-requirements\"," >> "$SBOM_OUTPUT"
        echo "      \"downloadLocation\": \"NOASSERTION\"," >> "$SBOM_OUTPUT"
        echo "      \"filesAnalyzed\": false," >> "$SBOM_OUTPUT"
        echo "      \"copyrightText\": \"NOASSERTION\"," >> "$SBOM_OUTPUT"
        echo "      \"externalRefs\": [" >> "$SBOM_OUTPUT"
        echo "        {" >> "$SBOM_OUTPUT"
        echo "          \"referenceCategory\": \"PACKAGE_MANAGER\"," >> "$SBOM_OUTPUT"
        echo "          \"referenceType\": \"purl\"," >> "$SBOM_OUTPUT"
        echo "          \"referenceLocator\": \"pkg:generic/python-requirements@1.0.0\"" >> "$SBOM_OUTPUT"
        echo "        }" >> "$SBOM_OUTPUT"
        echo "      ]" >> "$SBOM_OUTPUT"
        echo "    }" >> "$SBOM_OUTPUT"
    fi

    cat >> "$SBOM_OUTPUT" << EOF
  ]
}
EOF
fi

echo "✅ SBOM generated: $SBOM_OUTPUT"

# Validate SBOM format
if command -v jq >/dev/null 2>&1; then
    if jq . "$SBOM_OUTPUT" >/dev/null 2>&1; then
        echo "✅ SBOM JSON format is valid"

        # Count packages
        PACKAGE_COUNT=$(jq '.packages | length' "$SBOM_OUTPUT" 2>/dev/null || echo "0")
        echo "📦 Found $PACKAGE_COUNT packages in SBOM"
    else
        echo "❌ SBOM JSON format is invalid"
        exit 1
    fi
else
    echo "⚠️  jq not found, skipping SBOM validation"
fi

echo "📜 SBOM generation complete!"
echo "To install syft for better SBOM generation: curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"
