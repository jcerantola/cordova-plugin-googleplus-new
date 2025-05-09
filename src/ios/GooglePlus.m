#import "GooglePlus.h"
#import <Cordova/CDV.h>
#import <GoogleSignIn/GoogleSignIn.h>

@implementation GooglePlus {
    GIDConfiguration *_gidConfig;
}

- (void)pluginInitialize {
    NSString *clientID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CLIENT_ID"];
    if (clientID) {
        _gidConfig = [[GIDConfiguration alloc] initWithClientID:clientID];
    }
}

- (void)login:(CDVInvokedUrlCommand *)command {
    if (!_gidConfig) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Missing CLIENT_ID"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    __weak typeof(self) weakSelf = self;

    [GIDSignIn.sharedInstance signInWithConfiguration:_gidConfig
                         presentingViewController:self.viewController
                                         callback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
        CDVPluginResult *result;

        if (error) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        } else {
            NSDictionary *userInfo = @{
                @"email": user.profile.email ?: @"",
                @"userId": user.userID ?: @"",
                @"displayName": user.profile.name ?: @"",
                @"givenName": user.profile.givenName ?: @"",
                @"familyName": user.profile.familyName ?: @"",
                @"idToken": user.authentication.idToken ?: @"",
                @"serverAuthCode": user.serverAuthCode ?: @""
            };
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userInfo];
        }

        [weakSelf.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)trySilentLogin:(CDVInvokedUrlCommand *)command {
    if (!_gidConfig) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Missing CLIENT_ID"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [GIDSignIn.sharedInstance restorePreviousSignInWithCallback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
        CDVPluginResult *result;

        if (error || !user) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No previous session"];
        } else {
            NSDictionary *userInfo = @{
                @"email": user.profile.email ?: @"",
                @"userId": user.userID ?: @"",
                @"displayName": user.profile.name ?: @"",
                @"givenName": user.profile.givenName ?: @"",
                @"familyName": user.profile.familyName ?: @"",
                @"idToken": user.authentication.idToken ?: @"",
                @"serverAuthCode": user.serverAuthCode ?: @""
            };
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userInfo];
        }

        [weakSelf.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)logout:(CDVInvokedUrlCommand *)command {
    [GIDSignIn.sharedInstance signOut];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)disconnect:(CDVInvokedUrlCommand *)command {
    [GIDSignIn.sharedInstance disconnectWithCallback:^(NSError * _Nullable error) {
        CDVPluginResult *result;
        if (error) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        } else {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)share_unused:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Not implemented"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
