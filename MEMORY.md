# Cordova Native Fallback Plugin

This plugin provides a native fallback mechanism for Cordova applications. When the WebView fails to load content due to a network error, this plugin displays a native alert, offering the user a chance to retry the connection. This improves user experience by providing immediate, clear feedback and a recovery path when the application's web-based content cannot be accessed.

## Why This Plugin?

In a standard Cordova application, network errors can lead to a blank or broken-looking webview, which can confuse users. This plugin intercepts these errors and replaces the default webview error with a native UI component. This approach has several advantages:

*   **Improved User Experience:** Native UI elements are familiar and responsive, providing a better experience than a generic web error page.
*   **Clear Communication:** The native dialog clearly explains the problem (a network error) and provides a direct action (retry).
*   **Reliability:** The native code runs outside the context of the webview, so it can function even when the web content fails to load.

## File Structure

```
.
├── plugin.xml
├── src
│   ├── android
│   │   └── NativeFallback.java
│   └── ios
│       └── NativeFallback.m
└── www
    └── native-fallback.js
```

## Setup and Configuration

### 1. `plugin.xml`

This file is the heart of the Cordova plugin. It defines the plugin's structure, dependencies, and how the native code is integrated into the Android and iOS platforms.

```xml
<plugin id="cordova-plugin-native-fallback" version="1.0.0" xmlns="http://apache.org/cordova/ns/plugins/1.0">
  <name>NativeFallback</name>
  <js-module src="www/native-fallback.js" name="NativeFallback">
    <clobbers target="cordova.plugins.nativeFallback" />
  </js-module>

  <platform name="android">
    <source-file src="src/android/NativeFallback.java" target-dir="src/com/example/nativefallback" />
  </platform>

  <platform name="ios">
    <source-file src="src/ios/NativeFallback.m" />
  </platform>
</plugin>
```

**Why?**

*   The `<js-module>` tag makes the JavaScript interface (`www/native-fallback.js`) available in the webview under `cordova.plugins.nativeFallback`.
*   The `<platform>` tags specify the native source files for Android and iOS. Cordova's build system uses this information to copy the files into the respective native projects.

### 2. Android Implementation (`NativeFallback.java`)

This Java class integrates with the Android version of the Cordova application. It extends `CordovaPlugin` and uses a `WebViewClient` to monitor the webview for errors.

```java
package com.example.nativefallback;

import org.apache.cordova.*;
import android.webkit.WebView;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebViewClient;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Handler;

public class NativeFallback extends CordovaPlugin {
    @Override
    public void initialize(final CordovaInterface cordova, final CordovaWebView webView) {
        super.initialize(cordova, webView);

        webView.getEngine().getView().setWebViewClient(new WebViewClient() {
            private Handler handler = new Handler();

            @Override
            public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                showNativeErrorDialog();
            }

            private void showNativeErrorDialog() {
                cordova.getActivity().runOnUiThread(() -> {
                    new AlertDialog.Builder(cordova.getActivity())
                        .setTitle("Network Error")
                        .setMessage("Unable to load content. Please check your connection.")
                        .setPositiveButton("Retry", (dialog, which) -> webView.loadUrl("https://your.remote.url"))
                        .setCancelable(false)
                        .show();
                });
            }
        });
    }
}
```

**Why?**

*   We override the `initialize` method to attach a custom `WebViewClient` to the Cordova webview.
*   `onReceivedError` is a method in `WebViewClient` that gets called when the webview fails to load a resource.
*   Inside `onReceivedError`, we call `showNativeErrorDialog` to display a native Android `AlertDialog`.
*   The "Retry" button in the dialog attempts to reload the original URL.

### 3. iOS Implementation (`NativeFallback.m`)

This Objective-C class provides the same functionality for the iOS platform. It conforms to the `WKNavigationDelegate` protocol to receive navigation events from the `WKWebView`.

```objc
#import <Cordova/CDVPlugin.h>
#import <WebKit/WebKit.h>

 @interface NativeFallback : CDVPlugin <WKNavigationDelegate>
 @end @implementation NativeFallback

- (void)pluginInitialize {
    WKWebView* webView = (WKWebView*)self.webView;
    webView.navigationDelegate = self;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self showNativeAlert];
}

- (void)showNativeAlert {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: @"Network Error"
        message: @"The content could not be loaded. Please check your connection."
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* retry = [UIAlertAction actionWithTitle: @"Retry" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            [((WKWebView*)self.webView) loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: @"https://your.remote.url"]]];
        }];
    [alert addAction:retry];

    UIViewController* root = UIApplication.sharedApplication.delegate.window.rootViewController;
    [root presentViewController:alert animated:YES completion:nil];
}
 @end
```

**Why?**

*   `pluginInitialize` is called when the plugin is first created. Here, we set the current class as the `navigationDelegate` for the `WKWebView`.
*   `webView:didFailProvisionalNavigation:withError:` is a delegate method that is invoked when the webview fails to start loading content.
*   `showNativeAlert` creates and displays a `UIAlertController`, which is the iOS equivalent of the Android `AlertDialog`.
*   The "Retry" action re-initiates the request to the specified URL.

### 4. JavaScript Interface (`native-fallback.js`)

This optional file provides a way to trigger the native functionality from your application's JavaScript code.

```javascript
module.exports = {
  triggerErrorFallback: function (success, error) {
    cordova.exec(success, error, "NativeFallback", "triggerErrorFallback", []);
  }
};
```

**Why?**

*   This allows you to programmatically trigger the native error dialog from your web code if you have application-specific logic that detects a failure.
*   `cordova.exec` is the bridge that allows communication from the JavaScript world to the native Objective-C/Java world.

## How to Use

1.  Add this plugin to your Cordova project:
    ```bash
    cordova plugin add /path/to/cordova-plugin-native-fallback
    ```
2.  Build and run your application for Android or iOS.
3.  Disconnect your device from the internet and launch the app. You should see the native error dialog.
