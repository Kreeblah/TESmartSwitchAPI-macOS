//
//  SwitchAPI.h
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CocoaAsyncSocket/GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

#define KVM_TAG_NULL 0
#define KVM_TAG_CONNECT 1
#define KVM_TAG_DISCONNECT 2
#define KVM_TAG_SET_DISPLAY_TIMEOUT 3
#define KVM_TAG_SET_BUZZER_ENABLED 4
#define KVM_TAG_GET_DISPLAY_PORT 5
#define KVM_TAG_SET_DISPLAY_PORT 6
#define KVM_TAG_GET_CONFIGURED_IP 7
#define KVM_TAG_GET_CONFIGURED_PORT 8
#define KVM_TAG_GET_CONFIGURED_NETMASK 9
#define KVM_TAG_GET_CONFIGURED_GATEWAY 10
#define KVM_TAG_SET_CONFIGURED_IP 11
#define KVM_TAG_SET_CONFIGURED_PORT 12
#define KVM_TAG_SET_CONFIGURED_NETMASK 13
#define KVM_TAG_SET_CONFIGURED_GATEWAY 14

@protocol SwitchAPICallback
@optional
- (void)connectionCallback;
- (void)disconnectionCallback;
- (void)portSelectionCallback:(NSNumber*)selectedPortNumber;
- (void)setDisplayPortCallback:(NSNumber*)setPortNumber;
- (void)getConfiguredIpAddressCallback:(NSString*)ipAddress;
- (void)getConfiguredPortCallback:(NSNumber*)portNumber;
- (void)getConfiguredNetmaskCallback:(NSString*)netmask;
- (void)getConfiguredGatewayCallback:(NSString*)gateway;
- (void)setConfiguredIpAddressCallback:(NSString*)ipAddress;
- (void)setConfiguredPortCallback:(NSNumber*)portNumber;
- (void)setConfiguredNetmaskCallback:(NSString*)netmask;
- (void)setConfiguredGatewayCallback:(NSString*)gateway;
@end

@interface SwitchAPI : NSObject <GCDAsyncSocketDelegate> {
    @private NSString* switchHost;
    @private int switchPort;
    @private BOOL pendingConnection;
    @private BOOL isConnected;
    @private dispatch_queue_t mainQueue;
    @private GCDAsyncSocket* kvmSocket;
    @private NSMutableDictionary* callbackDictionary;
    @private NSMutableArray* callbackObjects;
}

struct sCallbackParameters {
    id callbackObject;
    NSString* callbackSelector;
};
typedef struct sCallbackParameters CallbackParameters;

+ (SwitchAPI*)sharedInstance;
- (void)registerCallbackObject:(id)callbackObject;
- (BOOL)connectToKvm:(NSString*)connectionHost port:(int)connectionPort;
- (BOOL)disconnectFromKvm;
- (BOOL)isConnected;
- (BOOL)pendingConnection;
- (BOOL)setDisplayTimeoutSeconds:(int)timeoutSeconds;
- (BOOL)setBuzzerEnabled:(BOOL)buzzerEnable;
- (BOOL)getDisplayPort;
- (BOOL)setDisplayPort:(int)portNumber;
- (BOOL)getConfiguredIpAddress;
- (BOOL)getConfiguredNetmask;
- (BOOL)getConfiguredGateway;
- (BOOL)getConfiguredNetworkPort;
- (BOOL)setConfiguredIpAddress:(NSString*)ipAddress;
- (BOOL)setConfiguredNetmask:(NSString*)netmask;
- (BOOL)setConfiguredGateway:(NSString*)gatewayAddress;
- (BOOL)setConfiguredNetworkPort:(int)networkPort;

@end

NS_ASSUME_NONNULL_END
