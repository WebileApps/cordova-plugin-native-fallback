package com.example.nativefallback;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.engine.SystemWebViewClient;
import org.apache.cordova.engine.SystemWebViewEngine;
import org.apache.cordova.ConfigXmlParser;

import android.app.AlertDialog;
import android.os.Build;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.net.Uri;

public class NativeFallback extends CordovaPlugin {
    
    private String startUrl;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        
        // Get the start URL from config.xml
        ConfigXmlParser parser = new ConfigXmlParser();
        parser.parse(cordova.getActivity());
        startUrl = parser.getLaunchUrl();

        if (webView.getEngine() instanceof SystemWebViewEngine) {
            SystemWebViewEngine engine = (SystemWebViewEngine) webView.getEngine();
            
            WebView androidWebView = (WebView) engine.getView();

            androidWebView.setWebViewClient(new SystemWebViewClient(engine) {
                
                @Override
                public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (request.isForMainFrame()) {
                            // Get error details
                            String errorMessage = error.getDescription().toString();
                            int errorCode = error.getErrorCode();
                            String failingUrl = request.getUrl().toString();
                            
                            // Load custom blank page to hide the error without triggering app exit
                            String blankHtml = "<html><body style='background-color:#FFFFFF;'></body></html>";
                            // Use "data:" as baseUrl to avoid triggering Cordova's exit mechanism
                            // while still maintaining a valid URL context
                            view.loadDataWithBaseURL("data:text/html,", blankHtml, "text/html", "UTF-8", null);
                            showNativeErrorDialog(errorCode, errorMessage, failingUrl);
                        }
                    }
                }

                @Override
                @SuppressWarnings("deprecation")
                public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                        // Load custom blank page to hide the error without triggering app exit
                        String blankHtml = "<html><body style='background-color:#FFFFFF;'></body></html>";
                        // Use "data:" as baseUrl to avoid triggering Cordova's exit mechanism
                        // while still maintaining a valid URL context
                        view.loadDataWithBaseURL("data:text/html,", blankHtml, "text/html", "UTF-8", null);
                        showNativeErrorDialog(errorCode, description, failingUrl);
                    }
                }
            });
        }
    }

    private void showNativeErrorDialog(int errorCode, String errorMessage, String failingUrl) {
        cordova.getActivity().runOnUiThread(() -> {
            // Check if activity is finishing to prevent window leak
            if (cordova.getActivity() == null || cordova.getActivity().isFinishing()) {
                return;
            }
            
            try {
                // Create a user-friendly error message that includes some technical details
                String title = "Connection Error";
                String message = "Unable to load content: " + errorMessage;
                
                // Limit message length if too long
                if (message.length() > 100) {
                    message = message.substring(0, 97) + "...";
                }
                
                new AlertDialog.Builder(cordova.getActivity())
                    .setTitle(title)
                    .setMessage(message)
                    .setPositiveButton("Retry", (dialog, which) -> {
                        // Check if webView is still valid before using it
                        if (webView != null) {
                            // Use the initial URL from config.xml if available, otherwise use the failing URL
                            String urlToLoad = startUrl != null ? startUrl : failingUrl;
                            webView.loadUrl(urlToLoad);
                        }
                    })
                    .setCancelable(false)
                    .show();
            } catch (Exception e) {
                // Handle potential exceptions when showing dialog
                System.err.println("Error showing dialog: " + e.getMessage());
            }
        });
    }
}
