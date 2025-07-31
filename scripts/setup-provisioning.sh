#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 Setting up App Store Connect provisioning${NC}"

# Set credentials
API_KEY_ID="6VZ4NHWMQN"
API_ISSUER_ID="0acdb473-8d3f-4eba-85bc-d2de82234bea"
API_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8"

# Check API key
if [ ! -f "$API_KEY_PATH" ]; then
    echo -e "${RED}❌ API key not found at $API_KEY_PATH${NC}"
    exit 1
fi

# Create JWT token for API requests
echo -e "${YELLOW}🔑 Creating API token...${NC}"

# Base64 URL encoding function
base64url() {
    # Use base64 encode and replace +/ with -_ and remove padding
    base64 | tr '+/' '-_' | tr -d '='
}

# Create JWT header
JWT_HEADER=$(echo -n '{"alg":"ES256","kid":"'$API_KEY_ID'","typ":"JWT"}' | base64url)

# Create JWT payload
ISSUED_AT=$(date +%s)
EXPIRES_AT=$((ISSUED_AT + 1200)) # 20 minutes
JWT_PAYLOAD=$(echo -n '{"iss":"'$API_ISSUER_ID'","iat":'$ISSUED_AT',"exp":'$EXPIRES_AT',"aud":"appstoreconnect-v1"}' | base64url)

# Sign token (this requires openssl)
JWT_SIGNATURE=$(echo -n "${JWT_HEADER}.${JWT_PAYLOAD}" | openssl dgst -sha256 -sign "$API_KEY_PATH" | base64url)

JWT_TOKEN="${JWT_HEADER}.${JWT_PAYLOAD}.${JWT_SIGNATURE}"

# Test API connection
echo -e "${YELLOW}📡 Testing App Store Connect API...${NC}"
curl -s -H "Authorization: Bearer $JWT_TOKEN" \
     "https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=com.posta.app" \
     | python3 -m json.tool > /dev/null && echo -e "${GREEN}✅ API connection successful${NC}" || echo -e "${RED}❌ API connection failed${NC}"

# Download certificates
echo -e "${YELLOW}📥 Downloading certificates...${NC}"
mkdir -p ~/Library/MobileDevice/Certificates

# Get distribution certificate
CERT_RESPONSE=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" \
     "https://api.appstoreconnect.apple.com/v1/certificates?filter[certificateType]=DISTRIBUTION")

echo "$CERT_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'data' in data and len(data['data']) > 0:
    for cert in data['data']:
        print(f\"Found certificate: {cert['attributes']['displayName']}\")
else:
    print('No distribution certificates found')
"

echo
echo -e "${GREEN}✅ Setup script complete${NC}"
echo
echo "Next steps:"
echo "1. Open Xcode and add your Apple ID in Settings → Accounts"
echo "2. Download signing certificates through Xcode"
echo "3. Run ./scripts/deploy-simple.sh"
echo
echo "Or use GitHub Actions which handles everything automatically"