# CI/CD Setup for Posta

This document explains how to set up GitHub Actions for automatic TestFlight deployment.

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository settings (Settings → Secrets and variables → Actions):

### 1. `APP_STORE_CONNECT_API_KEY_BASE64`
The base64-encoded content of your App Store Connect API key (.p8 file).

To encode your key:
```bash
base64 -i /path/to/AuthKey_6VZ4NHWMQN.p8 | pbcopy
```

### 2. `APP_STORE_API_KEY_ID`
Your App Store Connect API Key ID.
- Current value: `6VZ4NHWMQN`

### 3. `APP_STORE_API_ISSUER_ID`
Your App Store Connect API Issuer ID.
- Current value: `0acdb473-8d3f-4eba-85bc-d2de82234bea`

## Workflows

### 1. Build and Test (`build.yml`)
- **Triggers**: Push to main/develop, Pull requests to main
- **Actions**: 
  - Builds the app
  - Runs tests (if available)
  - Checks code quality

### 2. Deploy to TestFlight (`testflight.yml`)
- **Triggers**: 
  - Push to main branch
  - Git tags starting with 'v' (e.g., v1.0.0)
  - Manual trigger with version bump option
- **Actions**:
  - Builds release version
  - Exports IPA
  - Uploads to TestFlight

## Manual Deployment

To manually trigger a TestFlight deployment:

1. Go to Actions tab in GitHub
2. Select "Deploy to TestFlight"
3. Click "Run workflow"
4. Choose version bump type (patch/minor/major) or leave empty
5. Click "Run workflow"

## Local Testing

To test the build locally:
```bash
./build.sh
```

To deploy to TestFlight locally (requires credentials):
```bash
export API_KEY_ID="6VZ4NHWMQN"
export API_ISSUER_ID="0acdb473-8d3f-4eba-85bc-d2de82234bea"
./deploy.sh
```

## Troubleshooting

### Build Failures
- Ensure Xcode project is up to date: `./refresh-project.sh`
- Check that Swift version matches: Should be 5.9
- Verify NDKSwift dependency is on master branch

### Upload Failures
- Verify all secrets are correctly set in GitHub
- Ensure API key hasn't expired
- Check that the team ID matches your developer account

## Security Notes

- Never commit API keys or certificates to the repository
- Rotate API keys periodically
- Use GitHub's secret scanning to detect accidental commits