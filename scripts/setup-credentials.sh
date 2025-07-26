#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 App Store Connect Credentials Setup${NC}"
echo

# Default values
DEFAULT_API_KEY_ID="6VZ4NHWMQN"
DEFAULT_API_ISSUER_ID="0acdb473-8d3f-4eba-85bc-d2de82234bea"

# Get API Key ID
read -p "Enter API Key ID [$DEFAULT_API_KEY_ID]: " API_KEY_ID
API_KEY_ID=${API_KEY_ID:-$DEFAULT_API_KEY_ID}

# Get API Issuer ID
read -p "Enter API Issuer ID [$DEFAULT_API_ISSUER_ID]: " API_ISSUER_ID
API_ISSUER_ID=${API_ISSUER_ID:-$DEFAULT_API_ISSUER_ID}

# Get path to .p8 file
echo
echo "Please provide the path to your AuthKey_${API_KEY_ID}.p8 file"
read -p "Path to .p8 file: " P8_PATH

# Expand tilde in path
P8_PATH="${P8_PATH/#\~/$HOME}"

# Check if file exists
if [ ! -f "$P8_PATH" ]; then
    echo -e "${RED}❌ Error: File not found at $P8_PATH${NC}"
    exit 1
fi

# Create directory
echo -e "${YELLOW}📁 Creating App Store Connect directory...${NC}"
mkdir -p ~/.appstoreconnect/private_keys

# Copy key file
echo -e "${YELLOW}📋 Copying API key...${NC}"
cp "$P8_PATH" ~/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8
chmod 600 ~/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8

# Create environment file
ENV_FILE="$HOME/.posta_deploy_env"
echo -e "${YELLOW}💾 Creating environment file...${NC}"
cat > "$ENV_FILE" << EOF
# Posta App Store Connect Credentials
export API_KEY_ID="$API_KEY_ID"
export API_ISSUER_ID="$API_ISSUER_ID"
EOF

echo
echo -e "${GREEN}✅ Setup complete!${NC}"
echo
echo "To use these credentials, run:"
echo -e "${BLUE}source $ENV_FILE${NC}"
echo
echo "You can also add this to your shell profile (.zshrc or .bash_profile):"
echo -e "${BLUE}echo 'source $ENV_FILE' >> ~/.zshrc${NC}"
echo
echo "For GitHub Actions, add these secrets:"
echo "  - APP_STORE_API_KEY_ID: $API_KEY_ID"
echo "  - APP_STORE_API_ISSUER_ID: $API_ISSUER_ID"
echo "  - APP_STORE_CONNECT_API_KEY_BASE64: (base64 encoded .p8 file)"
echo
echo "To get the base64 encoded key for GitHub:"
echo -e "${BLUE}base64 -i ~/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8 | pbcopy${NC}"
echo "(This copies it to your clipboard)"