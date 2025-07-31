# Manual TestFlight Deployment

Since automatic deployment requires Xcode account configuration, here's how to deploy manually:

## Prerequisites

1. **Configure Xcode Account**:
   - Open Xcode
   - Go to Settings → Accounts
   - Add your Apple ID (the one associated with developer account)
   - Download certificates

## Option 1: Using Xcode UI

1. Open `Posta.xcodeproj` in Xcode
2. Select "Posta" scheme and "Any iOS Device" as destination
3. Product → Archive
4. Once complete, Organizer window will open
5. Select the archive and click "Distribute App"
6. Choose "App Store Connect" → Next
7. Choose "Upload" → Next
8. Follow the prompts to upload

## Option 2: Using Command Line (after Xcode account setup)

```bash
# Set credentials
export API_KEY_ID="6VZ4NHWMQN"
export API_ISSUER_ID="0acdb473-8d3f-4eba-85bc-d2de82234bea"

# Run deployment
./deploy.sh
```

## Option 3: Using GitHub Actions

The easiest way is to let GitHub Actions handle it:

1. Push your changes:
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```

2. Or create a release tag:
   ```bash
   git tag v1.0.2 -m "Release v1.0.2"
   git push origin v1.0.2
   ```

GitHub Actions will automatically build and deploy to TestFlight.

## Troubleshooting

### "No Account for Team" Error
- Open Xcode → Settings → Accounts
- Add your Apple ID
- Select team "6VZ4NHWMQN"

### "No profiles found" Error
- In Xcode, select the project
- Go to Signing & Capabilities
- Ensure "Automatically manage signing" is checked
- Select your team

### API Key Issues
- Ensure AuthKey_6VZ4NHWMQN.p8 is in ~/.appstoreconnect/private_keys/
- Check that the key hasn't expired
- Verify the issuer ID is correct

## API Credentials

- **API Key ID**: 6VZ4NHWMQN
- **API Issuer ID**: 0acdb473-8d3f-4eba-85bc-d2de82234bea
- **Team ID**: 6VZ4NHWMQN
- **Bundle ID**: com.posta.app