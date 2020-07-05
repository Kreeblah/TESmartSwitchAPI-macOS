//
//  SwitchAPI.h
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwitchAPI : NSObject {
    NSString* switchHost;
    int switchPort;
    NSInputStream* kvmInputStream;
    NSOutputStream* kvmOutputStream;
}

+ (SwitchAPI*)sharedInstance;
- (BOOL)connectToKvm:(NSString*)connectionHost port:(int)connectionPort;
- (BOOL)disconnectFromKvm;
- (BOOL)isConnected;
- (BOOL)setDisplayTimeoutSeconds:(int)timeoutSeconds;
- (BOOL)setBuzzerEnabled:(BOOL)buzzerEnable;
- (int)getDisplayPort;
- (BOOL)setDisplayPort:(int)portNumber;
- (NSString*)getConfiguredIpAddress;
- (NSString*)getConfiguredNetmask;
- (NSString*)getConfiguredGateway;
- (int)getConfiguredNetworkPort;
- (BOOL)setConfiguredIpAddress:(NSString*)ipAddress;
- (BOOL)setConfiguredNetmask:(NSString*)netmask;
- (BOOL)setConfiguredGateway:(NSString*)gatewayAddress;
- (BOOL)setConfiguredNetworkPort:(int)networkPort;

@end

NS_ASSUME_NONNULL_END
