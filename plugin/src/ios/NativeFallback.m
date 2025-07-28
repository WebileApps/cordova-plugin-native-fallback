#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVConfigParser.h>
#import <WebKit/WebKit.h>

@interface NativeFallback : CDVPlugin <WKNavigationDelegate>

@property (nonatomic, weak) id<WKNavigationDelegate> originalNavigationDelegate;
@property (nonatomic, strong) NSString *startUrl;

@end

@implementation NativeFallback

- (void)pluginInitialize {
    WKWebView* webView = (WKWebView*)self.webView;
    self.originalNavigationDelegate = webView.navigationDelegate;
    webView.navigationDelegate = self;
    
    // Get the start URL from config.xml
    NSString* configPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"config.xml"];
    NSURL* configUrl = [NSURL fileURLWithPath:configPath];
    
    CDVConfigParser* configParser = [[CDVConfigParser alloc] init];
    NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:configUrl];
    [parser setDelegate:configParser];
    [parser parse];
    
    self.startUrl = configParser.startPage;
    
    // If startUrl doesn't have a scheme, add file:// to it
    if (self.startUrl && ![self.startUrl hasPrefix:@"http://"] && ![self.startUrl hasPrefix:@"https://"] && ![self.startUrl hasPrefix:@"file://"]) {
        self.startUrl = [NSString stringWithFormat:@"file://%@/www/%@", [[NSBundle mainBundle] bundlePath], self.startUrl];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    // Load blank page to hide the error
    [webView loadHTMLString:@"<html><body style='background-color:white;'></body></html>" baseURL:nil];
    
    // Get the failing URL
    NSString *failingUrl = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
    if (!failingUrl) {
        failingUrl = [error.userInfo objectForKey:NSURLErrorFailingURLErrorKey];
        if (failingUrl) {
            failingUrl = [(NSURL*)failingUrl absoluteString];
        }
    }
    
    [self showNativeAlertWithError:error failingUrl:failingUrl];

    if ([self.originalNavigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [self.originalNavigationDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

- (void)showNativeAlertWithError:(NSError *)error failingUrl:(NSString *)failingUrl {
    // Run on main thread to ensure UI updates happen on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create a user-friendly error message that includes some technical details
        NSString *title = @"Connection Error";
        NSString *errorMessage = [error localizedDescription];
        NSString *message = [NSString stringWithFormat:@"Unable to load content: %@", errorMessage];
        
        // Limit message length if too long
        if ([message length] > 100) {
            message = [[message substringToIndex:97] stringByAppendingString:@"..."];
        }
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
            message:message
            preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* retry = [UIAlertAction actionWithTitle: @"Retry" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {
                // Check if webView is still valid
                if (self.webView != nil) {
                    // Use the initial URL from config.xml if available, otherwise use the failing URL
                    NSString *urlToLoad = self.startUrl ? self.startUrl : failingUrl;
                    NSURL *url = [NSURL URLWithString:urlToLoad];
                    if (url) {
                        [((WKWebView*)self.webView) loadRequest:[NSURLRequest requestWithURL:url]];
                    }
                }
            }];
        [alert addAction:retry];

        // Get root view controller safely
        UIViewController* root = UIApplication.sharedApplication.delegate.window.rootViewController;
        if (root != nil) {
            // Check if view controller can present
            if (root.presentedViewController) {
                // If another view controller is already presented, dismiss it first
                [root.presentedViewController dismissViewControllerAnimated:NO completion:^{
                    [root presentViewController:alert animated:YES completion:nil];
                }];
            } else {
                [root presentViewController:alert animated:YES completion:nil];
            }
        }
    });
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