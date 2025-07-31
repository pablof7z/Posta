#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Posta Local TestFlight Deployment${NC}"

# Check for required environment variables
if [ -z "$API_KEY_ID" ] || [ -z "$API_ISSUER_ID" ]; then
    echo -e "${RED}❌ Error: Required environment variables not set${NC}"
    echo "Please set the following:"
    echo "  export API_KEY_ID=\"6VZ4NHWMQN\""
    echo "  export API_ISSUER_ID=\"0acdb473-8d3f-4eba-85bc-d2de82234bea\""
    exit 1
fi

# Check for API key file
API_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8"
if [ ! -f "$API_KEY_PATH" ]; then
    echo -e "${RED}❌ Error: API key not found at $API_KEY_PATH${NC}"
    echo "Please ensure your AuthKey_${API_KEY_ID}.p8 file is in place"
    exit 1
fi

# Clean previous build
echo -e "${YELLOW}🧹 Cleaning previous build...${NC}"
rm -rf build/

# Generate project if needed
if [ -f "refresh-project.sh" ]; then
    echo -e "${YELLOW}🔄 Refreshing Xcode project...${NC}"
    ./refresh-project.sh
fi

# Archive
echo -e "${YELLOW}🏗️  Building archive...${NC}"
xcodebuild archive \
    -project Posta.xcodeproj \
    -scheme Posta \
    -configuration Release \
    -archivePath build/Posta.xcarchive \
    -destination "generic/platform=iOS" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="6VZ4NHWMQN" \
    -allowProvisioningUpdates \
    -quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Archive failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archive created successfully${NC}"

# Export IPA
echo -e "${YELLOW}📦 Exporting IPA...${NC}"
xcodebuild -exportArchive \
    -archivePath build/Posta.xcarchive \
    -exportPath build \
    -exportOptionsPlist ExportOptions-TestFlight.plist \
    -allowProvisioningUpdates \
    -quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Export failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ IPA exported successfully${NC}"

# Upload to TestFlight
echo -e "${YELLOW}☁️  Uploading to TestFlight...${NC}"
xcrun altool --upload-app \
    -f build/Posta.ipa \
    -t ios \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully uploaded to TestFlight!${NC}"
    echo -e "${GREEN}📱 The build will be available in TestFlight in 10-30 minutes${NC}"
else
    echo -e "${RED}❌ Upload failed${NC}"
    exit 1
fi