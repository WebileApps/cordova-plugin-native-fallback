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