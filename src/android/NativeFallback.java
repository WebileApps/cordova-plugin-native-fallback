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