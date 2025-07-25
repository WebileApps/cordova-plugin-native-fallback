#import <Cordova/CDVPlugin.h>
#import <WebKit/WebKit.h>

@interface NativeFallback : CDVPlugin <WKNavigationDelegate>

@property (nonatomic, weak) id<WKNavigationDelegate> originalNavigationDelegate;

@end

@implementation NativeFallback

- (void)pluginInitialize {
    WKWebView* webView = (WKWebView*)self.webView;
    self.originalNavigationDelegate = webView.navigationDelegate;
    webView.navigationDelegate = self;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self showNativeAlert];

    if ([self.originalNavigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [self.originalNavigationDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
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

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.originalNavigationDelegate respondsToSelector:aSelector]) {
        return self.originalNavigationDelegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector] || [self.originalNavigationDelegate respondsToSelector:aSelector];
}

@end