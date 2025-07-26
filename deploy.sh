#!/bin/bash
set -e

# Check if credentials are set
if [ -z "$API_KEY_ID" ] || [ -z "$API_ISSUER_ID" ]; then
    # Try to source credentials file
    if [ -f "$HOME/.posta_deploy_env" ]; then
        source "$HOME/.posta_deploy_env"
    else
        echo "❌ Credentials not found. Please run:"
        echo "   ./scripts/setup-credentials.sh"
        exit 1
    fi
fi

# Run the local deployment script
./scripts/deploy-local.sh
