package com.example.nativefallback;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.engine.SystemWebViewClient;
import org.apache.cordova.engine.SystemWebViewEngine;

import android.app.AlertDialog;
import android.os.Build;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;

public class NativeFallback extends CordovaPlugin {

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        if (webView.getEngine() instanceof SystemWebViewEngine) {
            SystemWebViewEngine engine = (SystemWebViewEngine) webView.getEngine();
            
            WebView androidWebView = (WebView) engine.getView();

            androidWebView.setWebViewClient(new SystemWebViewClient(engine) {
                
                @Override
                public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (request.isForMainFrame()) {
                            showNativeErrorDialog();
                        }
                    }
                }

                @Override
                @SuppressWarnings("deprecation")
                public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                        showNativeErrorDialog();
                    }
                }
            });
        }
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
}
