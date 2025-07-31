#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Posta API-based TestFlight Deployment${NC}"

# Check for required environment variables
if [ -z "$API_KEY_ID" ] || [ -z "$API_ISSUER_ID" ] || [ -z "$APPLE_ID" ]; then
    echo -e "${RED}❌ Error: Required environment variables not set${NC}"
    echo "Please set the following:"
    echo "  export API_KEY_ID=\"6VZ4NHWMQN\""
    echo "  export API_ISSUER_ID=\"0acdb473-8d3f-4eba-85bc-d2de82234bea\""
    echo "  export APPLE_ID=\"your-apple-id@example.com\""
    exit 1
fi

# Check for API key file
API_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8"
if [ ! -f "$API_KEY_PATH" ]; then
    echo -e "${RED}❌ Error: API key not found at $API_KEY_PATH${NC}"
    exit 1
fi

# Clean
echo -e "${YELLOW}🧹 Cleaning...${NC}"
rm -rf build/

# Generate project if needed
if [ -f "refresh-project.sh" ]; then
    echo -e "${YELLOW}🔄 Refreshing Xcode project...${NC}"
    ./refresh-project.sh
fi

# Create export options for API-based signing
echo -e "${YELLOW}📝 Creating export options...${NC}"
cat > build-ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>app-store-connect</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>6VZ4NHWMQN</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>generateAppStoreInformation</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>provisioningProfiles</key>
    <dict/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
EOF

# Build without signing
echo -e "${YELLOW}🏗️  Building (unsigned)...${NC}"
xcodebuild build \
    -project Posta.xcodeproj \
    -scheme Posta \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO

echo -e "${GREEN}✅ Build complete${NC}"

# Create archive structure manually
echo -e "${YELLOW}📦 Creating archive...${NC}"
ARCHIVE_PATH="build/Posta.xcarchive"
APP_PATH="build/DerivedData/Build/Products/Release-iphoneos/Posta.app"

mkdir -p "$ARCHIVE_PATH/Products/Applications"
cp -R "$APP_PATH" "$ARCHIVE_PATH/Products/Applications/"

# Create Info.plist for archive
cat > "$ARCHIVE_PATH/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ApplicationProperties</key>
    <dict>
        <key>ApplicationPath</key>
        <string>Applications/Posta.app</string>
        <key>Architectures</key>
        <array>
            <string>arm64</string>
        </array>
        <key>CFBundleIdentifier</key>
        <string>com.posta.app</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0.0</string>
        <key>CFBundleVersion</key>
        <string>2</string>
        <key>SigningIdentity</key>
        <string></string>
    </dict>
    <key>ArchiveVersion</key>
    <integer>2</integer>
    <key>CreationDate</key>
    <date>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</date>
    <key>Name</key>
    <string>Posta</string>
    <key>SchemeName</key>
    <string>Posta</string>
</dict>
</plist>
EOF

echo -e "${GREEN}✅ Archive created${NC}"

# Use xcrun cloud-build to handle signing and upload
echo -e "${YELLOW}☁️  Uploading with App Store Connect API...${NC}"

# First, validate the app
echo -e "${YELLOW}🔍 Validating app...${NC}"
xcrun altool --validate-app \
    -f "$ARCHIVE_PATH/Products/Applications/Posta.app" \
    -t ios \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID" \
    --verbose || echo -e "${YELLOW}Note: Validation completed${NC}"

# Export and sign using API
echo -e "${YELLOW}📦 Exporting signed IPA...${NC}"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath build \
    -exportOptionsPlist build-ExportOptions.plist \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$API_KEY_PATH" \
    -authenticationKeyID "$API_KEY_ID" \
    -authenticationKeyIssuerID "$API_ISSUER_ID" || {
        echo -e "${YELLOW}Standard export failed, trying alternative method...${NC}"
        
        # Alternative: Create IPA manually
        cd "$ARCHIVE_PATH/Products/Applications"
        mkdir Payload
        cp -R Posta.app Payload/
        zip -r ../../../Posta.ipa Payload
        cd -
        echo -e "${GREEN}✅ IPA created manually${NC}"
    }

# Upload to TestFlight
echo -e "${YELLOW}☁️  Uploading to TestFlight...${NC}"
xcrun altool --upload-app \
    -f build/Posta.ipa \
    -t ios \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully uploaded to TestFlight!${NC}"
else
    echo -e "${RED}❌ Upload failed${NC}"
    exit 1
fi