#import "AppDelegate.h"
#import "objc/runtime.h"
#import "GooglePlus.h"
#import <GoogleSignIn/GoogleSignIn.h>

@implementation GooglePlus

- (void)pluginInitialize
{
    NSLog(@"GooglePlus pluginInitialize");
}

- (void)isAvailable:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)login:(CDVInvokedUrlCommand*)command {
    _callbackId = command.callbackId;
    NSDictionary* options = command.arguments[0];
    NSString *reversedClientId = [self getReversedClientId];

    if (reversedClientId == nil) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not find REVERSED_CLIENT_ID url scheme in app .plist"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
        return;
    }

    NSString *clientId = [self reverseUrlScheme:reversedClientId];
    NSString *serverClientId = options[@"webClientId"];
    NSString *hostedDomain = options[@"hostedDomain"];

    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientId
                                                          serverClientID:serverClientId
                                                            hostedDomain:hostedDomain
                                                              openIDRealm:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *presentingVC = [self viewController];

        [GIDSignIn.sharedInstance signInWithConfiguration:config
                                presentingViewController:presentingVC
                                                callback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
            [self handleSignInCompleteWithUser:user error:error];
        }];
    });
}

- (void)trySilentLogin:(CDVInvokedUrlCommand*)command {
    _callbackId = command.callbackId;

    [GIDSignIn.sharedInstance restorePreviousSignInWithCallback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
        [self handleSignInCompleteWithUser:user error:error];
    }];
}

- (void)handleSignInCompleteWithUser:(GIDGoogleUser * _Nullable)user error:(NSError * _Nullable)error {
    if (error || user == nil) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription ?: @"Unknown error"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
        return;
    }

    NSDictionary *result = @{
        @"email": user.profile.email ?: @"",
        @"idToken": user.authentication.idToken ?: @"",
        @"serverAuthCode": user.serverAuthCode ?: @"",
        @"accessToken": user.authentication.accessToken ?: @"",
        @"refreshToken": user.authentication.refreshToken ?: @"",
        @"userId": user.userID ?: @"",
        @"displayName": user.profile.name ?: @"",
        @"givenName": user.profile.givenName ?: @"",
        @"familyName": user.profile.familyName ?: @"",
        @"imageUrl": user.profile.hasImage ? [[user.profile imageURLWithDimension:120] absoluteString] : @""
    };

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_callbackId];
}

- (void)logout:(CDVInvokedUrlCommand*)command {
    [GIDSignIn.sharedInstance signOut];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"logged out"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command {
    [GIDSignIn.sharedInstance disconnectWithCallback:^(NSError * _Nullable error) {
        CDVPluginResult *pluginResult;
        if (error) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"disconnected"];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (NSString*)reverseUrlScheme:(NSString*)scheme {
    NSArray* originalArray = [scheme componentsSeparatedByString:@"."];
    NSArray* reversedArray = [[originalArray reverseObjectEnumerator] allObjects];
    return [reversedArray componentsJoinedByString:@"."];
}

- (NSString*)getReversedClientId {
    NSArray* URLTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    if (URLTypes != nil) {
        for (NSDictionary* dict in URLTypes) {
            NSString *urlName = dict[@"CFBundleURLName"];
            if ([urlName isEqualToString:@"REVERSED_CLIENT_ID"]) {
                NSArray* URLSchemes = dict[@"CFBundleURLSchemes"];
                if (URLSchemes != nil && URLSchemes.count > 0) {
                    return URLSchemes[0];
                }
            }
        }
    }
    return nil;
}

@end
