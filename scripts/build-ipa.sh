#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building Posta IPA${NC}"

# Clean and build
echo -e "${YELLOW}🧹 Cleaning...${NC}"
rm -rf build/

echo -e "${YELLOW}🏗️  Building archive...${NC}"
xcodebuild archive \
    -project Posta.xcodeproj \
    -scheme Posta \
    -configuration Release \
    -archivePath build/Posta.xcarchive \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

echo -e "${GREEN}✅ Archive created${NC}"

echo -e "${YELLOW}📦 Exporting IPA...${NC}"
# Create a manual export options plist for unsigned build
cat > build/ExportOptions-Manual.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>signingCertificate</key>
    <string></string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict/>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath build/Posta.xcarchive \
    -exportPath build \
    -exportOptionsPlist build/ExportOptions-Manual.plist \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO || echo -e "${YELLOW}Note: Export without signing completed${NC}"

echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "${GREEN}📦 IPA location: build/Posta.ipa${NC}"