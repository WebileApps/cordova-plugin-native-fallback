# Cordova Native Fallback Plugin

A Cordova plugin that provides a native UI fallback when your application fails to load its web content due to a network error.

This plugin automatically detects when the Cordova WebView cannot reach a remote URL and displays a native alert dialog, prompting the user to retry the connection. This prevents users from seeing a blank or broken page and provides a much cleaner user experience.

## Supported Platforms

*   Android
*   iOS

## Installation

You can add this plugin to your Cordova project from NPM (once published) or directly from a Git repository.

```bash
# Install from NPM (replace with your actual plugin name if different)
cordova plugin add cordova-plugin-native-fallback

# Or, install directly from a Git repository
cordova plugin add <your-git-repository-url>
```

## How It Works

The plugin works automatically out of the box. Once installed, it hooks into the native WebView's lifecycle on both Android and iOS.

1.  It listens for page loading errors, such as when the device is offline or a server is unreachable.
2.  When an error is detected, it suppresses the default web error page (e.g., "Webpage not available").
3.  Instead, it displays a native alert dialog with a "Network Error" message and a "Retry" button.
4.  If the user taps "Retry", the plugin attempts to reload the original URL that your app was trying to access.

## Usage

This plugin is designed to be zero-configuration. Simply install it, and it will handle network errors automatically.

### Manual Trigger (Optional)

For advanced scenarios where your application has its own logic for detecting content loading failures, you can manually trigger the native error dialog from your JavaScript code.

```javascript
cordova.plugins.nativeFallback.triggerErrorFallback(
  function() { console.log("Fallback success"); },
  function() { console.log("Fallback error"); }
);
```

## Configuration

To ensure the plugin works correctly, you may need to configure the retry URL. By default, it points to a placeholder.

To customize this, you will need to edit the source files directly:

*   **Android:** `src/android/NativeFallback.java`
*   **iOS:** `src/ios/NativeFallback.m`

In both files, find the line containing `https://your.remote.url` and replace it with your application's primary entry point URL.
