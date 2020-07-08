/*
     This file is part of TESmart Switch API at:
     <https://github.com/Kreeblah/TESmartSwitchAPI-macOS>.

TESmart Switch API is free software: you can redistribute it and/or modify
it under the terms of the Affero GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

TESmartSwitchAPI-macOS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Affero GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with TESmart Switch API.  If not, see <https://www.gnu.org/licenses/>.
*/

//
//  SwitchAPI.h
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Chris Gelatt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CocoaAsyncSocket/GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

#define KVM_TAG_NULL 0
#define KVM_TAG_CONNECT 1
#define KVM_TAG_DISCONNECT 2
#define KVM_TAG_SET_DISPLAY_TIMEOUT 3
#define KVM_TAG_SET_BUZZER_ENABLED 4
#define KVM_TAG_SET_ACTIVE_INPUT_DETECTION_ENABLED 5
#define KVM_TAG_GET_DISPLAY_PORT 6
#define KVM_TAG_SET_DISPLAY_PORT 7
#define KVM_TAG_GET_CONFIGURED_IP 8
#define KVM_TAG_GET_CONFIGURED_PORT 9
#define KVM_TAG_GET_CONFIGURED_NETMASK 10
#define KVM_TAG_GET_CONFIGURED_GATEWAY 11
#define KVM_TAG_SET_CONFIGURED_IP 12
#define KVM_TAG_SET_CONFIGURED_PORT 13
#define KVM_TAG_SET_CONFIGURED_NETMASK 14
#define KVM_TAG_SET_CONFIGURED_GATEWAY 15

@protocol SwitchAPICallback
@optional
- (void)connectionCallback;
- (void)connectionErrorCallback:(NSError*)error;
- (void)disconnectionCallback;
- (void)disconnectionErrorCallback:(NSError*)error;
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
- (BOOL)setActiveInputDetectionEnabled:(BOOL)inputDetectionEnable;
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
