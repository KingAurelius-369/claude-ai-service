#!/bin/bash
# Container Image Signing Script
# Signs container images using cosign for supply chain security

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/$(basename "$PROJECT_ROOT")}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
KEY_FILE="${KEY_FILE:-$PROJECT_ROOT/cosign.key}"
PUB_KEY_FILE="${PUB_KEY_FILE:-$PROJECT_ROOT/cosign.pub}"
SIGNATURE_OUTPUT="${SIGNATURE_OUTPUT:-$PROJECT_ROOT/image-signature.sig}"

echo "✍️ Signing container image..."
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "Key file: $KEY_FILE"

# Check for cosign tool
if ! command -v cosign >/dev/null 2>&1; then
    echo "❌ cosign is required but not installed."
    echo "Install cosign: https://docs.sigstore.dev/cosign/installation/"
    exit 1
fi

# Verify image exists
if ! docker image inspect "$IMAGE_NAME:$IMAGE_TAG" >/dev/null 2>&1; then
    echo "❌ Image $IMAGE_NAME:$IMAGE_TAG not found locally"
    echo "Please build or pull the image first"
    exit 1
fi

# Generate key pair if it doesn't exist
if [ ! -f "$KEY_FILE" ] || [ ! -f "$PUB_KEY_FILE" ]; then
    echo "🔑 Generating cosign key pair..."
    cosign generate-key-pair

    # Move keys to expected locations
    mv cosign.key "$KEY_FILE" 2>/dev/null || true
    mv cosign.pub "$PUB_KEY_FILE" 2>/dev/null || true

    echo "✅ Key pair generated"
    echo "Private key: $KEY_FILE"
    echo "Public key: $PUB_KEY_FILE"
else
    echo "✅ Using existing key pair"
fi

# Sign the image
echo "✍️ Signing image with cosign..."
if [ -n "${COSIGN_PASSWORD:-}" ]; then
    # Use environment variable for password (CI/CD)
    echo "Using COSIGN_PASSWORD from environment"
    cosign sign --key="$KEY_FILE" "$IMAGE_NAME:$IMAGE_TAG"
else
    # Interactive password prompt
    cosign sign --key="$KEY_FILE" "$IMAGE_NAME:$IMAGE_TAG"
fi

# Verify the signature
echo "🔍 Verifying signature..."
if cosign verify --key="$PUB_KEY_FILE" "$IMAGE_NAME:$IMAGE_TAG" > "$SIGNATURE_OUTPUT"; then
    echo "✅ Image signature verified successfully"
    echo "Signature details saved to: $SIGNATURE_OUTPUT"
else
    echo "❌ Image signature verification failed"
    exit 1
fi

# Generate signature manifest
SIG_DIGEST=$(cosign triangulate "$IMAGE_NAME:$IMAGE_TAG" 2>/dev/null || echo "unknown")
if [ "$SIG_DIGEST" != "unknown" ]; then
    echo "📜 Signature manifest: $SIG_DIGEST"
fi

echo "✍️ Container image signing complete!"
echo ""
echo "To verify this image later:"
echo "cosign verify --key=$PUB_KEY_FILE $IMAGE_NAME:$IMAGE_TAG"
echo ""
echo "Security note: Keep your private key ($KEY_FILE) secure and never commit it to version control!"
