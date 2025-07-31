#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Posta TestFlight Deployment${NC}"

# Set credentials
export API_KEY_ID="6VZ4NHWMQN"
export API_ISSUER_ID="0acdb473-8d3f-4eba-85bc-d2de82234bea"

# Build archive (using the successful method from earlier)
echo -e "${YELLOW}🏗️  Building archive...${NC}"
xcodebuild clean archive \
    -project Posta.xcodeproj \
    -scheme Posta \
    -configuration Release \
    -archivePath build/Posta.xcarchive \
    -destination "generic/platform=iOS" \
    DEVELOPMENT_TEAM="6VZ4NHWMQN" \
    CODE_SIGN_STYLE="Manual" \
    CODE_SIGN_IDENTITY="" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    | xcbeautify || {
        echo -e "${YELLOW}Archive build needs signing configuration${NC}"
        echo -e "${YELLOW}Trying with automatic signing...${NC}"
        
        xcodebuild clean archive \
            -project Posta.xcodeproj \
            -scheme Posta \
            -configuration Release \
            -archivePath build/Posta.xcarchive \
            -destination "generic/platform=iOS" \
            -allowProvisioningUpdates \
            | xcbeautify
    }

# Export IPA
echo -e "${YELLOW}📦 Exporting IPA...${NC}"
xcodebuild -exportArchive \
    -archivePath build/Posta.xcarchive \
    -exportPath build \
    -exportOptionsPlist ExportOptions-TestFlight.plist \
    -allowProvisioningUpdates \
    | xcbeautify

# Upload
echo -e "${YELLOW}☁️  Uploading to TestFlight...${NC}"
xcrun altool --upload-app \
    -f build/Posta.ipa \
    -t ios \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID"

echo -e "${GREEN}✅ Upload complete!${NC}"