#import <Cordova/CDVPlugin.h>
@import GoogleSignIn;  // Modificado para usar módulos

NS_ASSUME_NONNULL_BEGIN

@interface GooglePlus : CDVPlugin

// Propriedades
@property (nonatomic, copy, nullable) NSString* callbackId;
@property (nonatomic, assign) BOOL isSigningIn;
@property (nonatomic, strong, nullable) GIDSignIn *signInInstance;  // Adicionado para gerenciamento explícito

// Métodos
- (void)isAvailable:(CDVInvokedUrlCommand*)command;
- (void)login:(CDVInvokedUrlCommand*)command;
- (void)trySilentLogin:(CDVInvokedUrlCommand*)command;
- (void)logout:(CDVInvokedUrlCommand*)command;
- (void)disconnect:(CDVInvokedUrlCommand*)command;
- (void)share_unused:(CDVInvokedUrlCommand*)command;

// Adicionado para melhor tratamento do AppDelegate
- (BOOL)handleURL:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
