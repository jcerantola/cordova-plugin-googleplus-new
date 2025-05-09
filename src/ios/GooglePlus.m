#import "GooglePlus.h"
@import GoogleUtilities;  // Adicionado para melhor integração

@implementation GooglePlus {
    GIDSignIn *_signInInstance;  // Instância própria para evitar conflitos
}

#pragma mark - Plugin Lifecycle

- (void)pluginInitialize {
    NSLog(@"GooglePlus pluginInitialize");
    _signInInstance = [GIDSignIn sharedInstance];
    _signInInstance.presentingViewController = self.viewController;
    
    // Configuração adicional para coexistência com Firebase
    if ([GIDSignIn respondsToSelector:@selector(setSharedInstance:)]) {
        [GIDSignIn performSelector:@selector(setSharedInstance:) withObject:_signInInstance];
    }
}

#pragma mark - URL Handling

- (BOOL)handleURL:(NSURL*)url {
    return [_signInInstance handleURL:url];
}

#pragma mark - Public Methods

- (void)isAvailable:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)login:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    NSDictionary* options = command.arguments[0];
    
    NSString *reversedClientId = [self getReversedClientId];
    if (!reversedClientId) {
        [self sendErrorResult:@"Could not find REVERSED_CLIENT_ID url scheme in app .plist"];
        return;
    }

    GIDConfiguration *config = [[GIDConfiguration alloc] 
        initWithClientID:[self reverseUrlScheme:reversedClientId]
        serverClientID:options[@"webClientId"] ?: @""
        hostedDomain:options[@"hostedDomain"] ?: @""
        openIDRealm:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [_signInInstance signInWithConfiguration:config
                       presentingViewController:[self viewController]
                                     callback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
            [self handleSignInResultWithUser:user error:error];
        }];
    });
}

#pragma mark - Authentication Handlers

- (void)trySilentLogin:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    
    [_signInInstance restorePreviousSignInWithCallback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
        [self handleSignInResultWithUser:user error:error];
    }];
}

- (void)handleSignInResultWithUser:(GIDGoogleUser *)user error:(NSError *)error {
    if (error || !user) {
        [self sendErrorResult:error ? error.localizedDescription : @"Unknown error"];
        return;
    }
    
    NSDictionary *authData = @{
        @"email": user.profile.email ?: @"",
        @"idToken": user.authentication.idToken ?: @"",
        @"accessToken": user.authentication.accessToken ?: @"",
        @"refreshToken": user.authentication.refreshToken ?: @"",
        @"serverAuthCode": user.serverAuthCode ?: @"",
        @"userId": user.userID ?: @"",
        @"displayName": user.profile.name ?: @"",
        @"givenName": user.profile.givenName ?: @"",
        @"familyName": user.profile.familyName ?: @"",
        @"imageUrl": user.profile.hasImage ? [[user.profile imageURLWithDimension:120] absoluteString] : @""
    };
    
    [self sendSuccessResult:authData];
}

#pragma mark - Logout Methods

- (void)logout:(CDVInvokedUrlCommand*)command {
    [_signInInstance signOut];
    [self sendSuccessResult:@"logged out" forCommand:command];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command {
    [_signInInstance disconnectWithCallback:^(NSError * _Nullable error) {
        if (error) {
            [self sendErrorResult:error.localizedDescription forCommand:command];
        } else {
            [self sendSuccessResult:@"disconnected" forCommand:command];
        }
    }];
}

#pragma mark - Helper Methods

- (NSString *)reverseUrlScheme:(NSString *)scheme {
    return [[[scheme componentsSeparatedByString:@"."] reverseObjectEnumerator].allObjects componentsJoinedByString:@"."];
}

- (NSString *)getReversedClientId {
    for (NSDictionary *dict in [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"]) {
        if ([dict[@"CFBundleURLName"] isEqualToString:@"REVERSED_CLIENT_ID"]) {
            return [dict[@"CFBundleURLSchemes"] firstObject];
        }
    }
    return nil;
}

- (void)sendSuccessResult:(id)message {
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message] 
                                callbackId:self.callbackId];
}

- (void)sendErrorResult:(NSString *)message {
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message]
                                callbackId:self.callbackId];
}

- (void)sendSuccessResult:(id)message forCommand:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message]
                                callbackId:command.callbackId];
}

- (void)sendErrorResult:(NSString *)message forCommand:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message]
                                callbackId:command.callbackId];
}

@end
