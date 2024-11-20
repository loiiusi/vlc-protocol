// https://www.cocoawithlove.com/2010/09/minimalist-cocoa-programming.html
#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate

- (void)showError:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"VLC Protocol Error"];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
    [NSApp terminate:nil];
}

- (void)showInfo:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"VLC Protocol Info"];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (BOOL)isVLCInstalled {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/VLC.app"];
}

- (NSString *)decodeURL:(NSString *)url {
    return [[url 
        stringByReplacingOccurrencesOfString:@"+" withString:@" "]
        stringByRemovingPercentEncoding];
}

- (void)logMessage:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    fprintf(stderr, "[VLC-Protocol] %s\n", [message UTF8String]);
}

- (NSString *)repairBrokenUrl:(NSString *)url {
    [self logMessage:@"Original URL: %@", url];
    
    // First decode the URL to handle any encoding
    // 不需要解码，因为以前的URL并没有编码
    // url = [self decodeURL:url];
    // [self logMessage:@"Decoded URL: %@", url];
    
    // Fix Chrome 130+ format
    if ([url hasPrefix:@"http//"]) {
        url = [url stringByReplacingCharactersInRange:NSMakeRange(0, 6) withString:@"http://"];
        [self logMessage:@"Fixed HTTP URL: %@", url];
    } else if ([url hasPrefix:@"https//"]) {
        url = [url stringByReplacingCharactersInRange:NSMakeRange(0, 7) withString:@"https://"];
        [self logMessage:@"Fixed HTTPS URL: %@", url];
    }
    
    return url;
}

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent {
    [self logMessage:@"Received URL request"];
    
    // Check if VLC is installed
    if (![self isVLCInstalled]) {
        [self showError:@"VLC is not installed in /Applications. Please install VLC media player first."];
        return;
    }
    
    // Get input data
    NSString *input = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSString *url;
    
    if ([input hasPrefix:@"vlc://weblink?"]) {
        // Handle weblink format: vlc://weblink?url=http://...
        NSString *query = [input substringFromIndex:14];  
        [self logMessage:@"Query part: %@", query];
        
        // 直接检查url=参数
        if ([query hasPrefix:@"url="]) {
            url = [query substringFromIndex:4];
            // URL解码
            url = [self decodeURL:url];
            [self logMessage:@"Found URL: %@", url];
        } else {
            [self showError:[NSString stringWithFormat:@"Invalid weblink format. URL parameter is missing. Query: %@", query]];
            return;
        }
    } else if ([input hasPrefix:@"vlc://"]) {
        url = [input substringFromIndex:6];
    } else if ([input hasPrefix:@"vlc:"]) {
        url = [input substringFromIndex:4];
    } else {
        [self showError:@"Invalid URL format. Must start with 'vlc://' or 'vlc://weblink?url='."];
        return;
    }
    
    // First repair URL if needed
    url = [self repairBrokenUrl:url];
    
    // Then check protocol
    if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
        [self showError:@"Only HTTP and HTTPS protocols are supported."];
        return;
    }

    // Launch VLC
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSURL *app = [NSURL fileURLWithPath:@"/Applications/VLC.app"];
    NSArray *arguments = [NSArray arrayWithObjects: @"--open", url, nil];
    NSMutableDictionary *config = [[NSMutableDictionary alloc] init];
    [config setObject:arguments forKey:NSWorkspaceLaunchConfigurationArguments];
    
    NSError *error = nil;
    if (![ws launchApplicationAtURL:app options:NSWorkspaceLaunchNewInstance configuration:config error:&error]) {
        [self showError:[NSString stringWithFormat:@"Failed to launch VLC: %@", [error localizedDescription]]];
        return;
    }
    
    [NSApp terminate:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Close this program if it wasn't launched using a link (i.e. launched normally)
    [NSApp terminate:nil];
}

@end

int main() {
    // Make sure the shared application is created
    [NSApplication sharedApplication];

    AppDelegate *appDelegate = [AppDelegate new];
    NSAppleEventManager *sharedAppleEventManager = [NSAppleEventManager new];
    [sharedAppleEventManager setEventHandler:appDelegate
                               andSelector:@selector(handleAppleEvent:withReplyEvent:)
                             forEventClass:kInternetEventClass
                                andEventID:kAEGetURL];

    [NSApp setDelegate:appDelegate];
    [NSApp run];
    return 0;
}
