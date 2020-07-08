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
//  SwitchAPI.m
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Chris Gelatt. All rights reserved.
//

#import "SwitchAPI.h"
#import "CocoaAsyncSocket/GCDAsyncSocket.h"

@implementation SwitchAPI

- (id)init
{
    self = [super init];
    
    pendingConnection = NO;
    isConnected = NO;
    mainQueue = dispatch_get_main_queue();
    kvmSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    callbackDictionary = [[NSMutableDictionary alloc] init];
    callbackObjects = [[NSMutableArray alloc] init];
    
    return self;
}

+ (SwitchAPI*)sharedInstance
{
    static SwitchAPI* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)registerCallbackObject:(id)callbackObject {
    [callbackObjects addObject:callbackObject];
}

- (BOOL)connectToKvm:(NSString*)connectionHost port:(int)connectionPort {
    if(isConnected || pendingConnection) {
        return NO;
    }
    
    NSLog(@"Connecting to KVM at %@ on port %d", connectionHost, connectionPort);
    
    NSError* err = nil;
    if(![kvmSocket connectToHost:connectionHost onPort:connectionPort error:&err]) {
        NSLog(@"Connection error: %@", err);
        return NO;
    }
    
    pendingConnection = YES;
    
    return YES;
}

- (BOOL)disconnectFromKvm {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    [kvmSocket disconnect];
    
    return YES;
}

- (BOOL)isConnected {
    return isConnected;
}

- (BOOL)pendingConnection {
    return pendingConnection;
}

- (BOOL)setDisplayTimeoutSeconds:(int)timeoutSeconds {
    if(timeoutSeconds < 0 || timeoutSeconds > 255 || (!isConnected && !pendingConnection)) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:6];
    
    ((char*)[kvmCommand mutableBytes])[0] = 0xaa;
    ((char*)[kvmCommand mutableBytes])[1] = 0xbb;
    ((char*)[kvmCommand mutableBytes])[2] = 0x03;
    ((char*)[kvmCommand mutableBytes])[3] = 0x03;
    ((char*)[kvmCommand mutableBytes])[4] = timeoutSeconds;
    ((char*)[kvmCommand mutableBytes])[5] = 0xee;
    
    [self runKvmCommand:kvmCommand responseLength:0 dataTag:KVM_TAG_SET_DISPLAY_TIMEOUT];
    
    return YES;
}

- (BOOL)setBuzzerEnabled:(BOOL)buzzerEnable {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:6];
    
    ((char*)[kvmCommand mutableBytes])[0] = 0xaa;
    ((char*)[kvmCommand mutableBytes])[1] = 0xbb;
    ((char*)[kvmCommand mutableBytes])[2] = 0x03;
    ((char*)[kvmCommand mutableBytes])[3] = 0x02;
    if(buzzerEnable) {
        ((char*)[kvmCommand mutableBytes])[4] = 0x01;
    } else {
        ((char*)[kvmCommand mutableBytes])[4] = 0x00;
    }
    ((char*)[kvmCommand mutableBytes])[5] = 0xee;
    
    [self runKvmCommand:kvmCommand responseLength:0 dataTag:KVM_TAG_SET_BUZZER_ENABLED];
    
    return YES;
}

- (BOOL)setActiveInputDetectionEnabled:(BOOL)inputDetectionEnable {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:6];
    
    ((char*)[kvmCommand mutableBytes])[0] = 0xaa;
    ((char*)[kvmCommand mutableBytes])[1] = 0xbb;
    ((char*)[kvmCommand mutableBytes])[2] = 0x03;
    ((char*)[kvmCommand mutableBytes])[3] = 0x81;
    if(inputDetectionEnable) {
        ((char*)[kvmCommand mutableBytes])[4] = 0x01;
    } else {
        ((char*)[kvmCommand mutableBytes])[4] = 0x00;
    }
    ((char*)[kvmCommand mutableBytes])[5] = 0xee;
    
    [self runKvmCommand:kvmCommand responseLength:0 dataTag:KVM_TAG_SET_ACTIVE_INPUT_DETECTION_ENABLED];
    
    return YES;
}

- (BOOL)getDisplayPort {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:6];
    
    ((char*)[kvmCommand mutableBytes])[0] = 0xaa;
    ((char*)[kvmCommand mutableBytes])[1] = 0xbb;
    ((char*)[kvmCommand mutableBytes])[2] = 0x03;
    ((char*)[kvmCommand mutableBytes])[3] = 0x10;
    ((char*)[kvmCommand mutableBytes])[4] = 0x00;
    ((char*)[kvmCommand mutableBytes])[5] = 0xee;

    [self runKvmCommand:kvmCommand responseLength:6 dataTag:KVM_TAG_GET_DISPLAY_PORT];
    
    return YES;
}

- (void)getDisplayPortCallback:(NSData*)returnData {
    if(returnData == nil) {
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(portSelectionCallback:)]) {
                [testCallback performSelector:@selector(portSelectionCallback:) withObject:@(0)];
            }
        }
        return;
    }
    
    unsigned char* returnBytes = (unsigned char *)[returnData bytes];
    
    if(returnBytes[0] == 0xaa && returnBytes[1] == 0xbb && returnBytes[2] == 0x03 && returnBytes[3] == 0x11 && (returnBytes[5] == returnBytes[4] + 0x16)) {
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(portSelectionCallback:)]) {
                [testCallback performSelector:@selector(portSelectionCallback:) withObject:@(returnBytes[4] + 1)];
            }
        }
    } else {
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(portSelectionCallback:)]) {
                [testCallback performSelector:@selector(portSelectionCallback:) withObject:@(0)];
            }
        }
    }
    
}

- (BOOL)setDisplayPort:(int)portNumber {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:6];
    
    ((char*)[kvmCommand mutableBytes])[0] = 0xaa;
    ((char*)[kvmCommand mutableBytes])[1] = 0xbb;
    ((char*)[kvmCommand mutableBytes])[2] = 0x03;
    ((char*)[kvmCommand mutableBytes])[3] = 0x01;
    ((char*)[kvmCommand mutableBytes])[4] = portNumber;
    ((char*)[kvmCommand mutableBytes])[5] = 0xee;
    
    [self runKvmCommand:kvmCommand responseLength:6 dataTag:KVM_TAG_SET_DISPLAY_PORT];
    
    return YES;
}

- (void)setDisplayPortCallback:(NSData*)returnData {
    if(returnData == nil) {
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(setDisplayPortCallback:)]) {
                [testCallback performSelector:@selector(setDisplayPortCallback:) withObject:@(0)];
            }
        }
        return;
    }
    
    unsigned char * returnBytes = (unsigned char *)[returnData bytes];
    
    if(returnBytes[0] == 0xaa && returnBytes[1] == 0xbb && returnBytes[2] == 0x03 && returnBytes[3] == 0x11 && (returnBytes[4] == (returnBytes[5] - 0x16))) {
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(setDisplayPortCallback:)]) {
                [testCallback performSelector:@selector(setDisplayPortCallback:) withObject:@(returnBytes[4] + 1)];
            }
        }
    } else {
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(setDisplayPortCallback:)]) {
                [testCallback performSelector:@selector(setDisplayPortCallback:) withObject:@(0)];
            }
        }
    }
}

- (BOOL)getConfiguredIpAddress {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:3];
    ((char*)[kvmCommand mutableBytes])[0] = 'I';
    ((char*)[kvmCommand mutableBytes])[1] = 'P';
    ((char*)[kvmCommand mutableBytes])[2] = '?';
    
    [self runKvmCommand:kvmCommand responseLength:19 dataTag:KVM_TAG_GET_CONFIGURED_IP];
    
    return YES;
}

- (void)getConfiguredIpAddressCallback:(NSData*)returnData {
    if(returnData == nil) {
        return;
    }
    
    //It sends an extra packet containing only a semicolon with this request,
    //so we can discard it.
    //[kvmSocket readDataToLength:1 withTimeout:5 tag:KVM_TAG_NULL];
    
    NSString* returnString = [self getIpStringFromReturnBytes:(unsigned char*)[returnData bytes] confirmHeader:@"IP:"];
    
    for(id testCallback in callbackObjects) {
        if([testCallback respondsToSelector:@selector(getConfiguredIpAddressCallback:)]) {
            [testCallback performSelector:@selector(getConfiguredIpAddressCallback:) withObject:returnString];
        }
    }
}

- (BOOL)getConfiguredNetmask {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:3];
    ((char*)[kvmCommand mutableBytes])[0] = 'M';
    ((char*)[kvmCommand mutableBytes])[1] = 'A';
    ((char*)[kvmCommand mutableBytes])[2] = '?';
    
    [self runKvmCommand:kvmCommand responseLength:19 dataTag:KVM_TAG_GET_CONFIGURED_NETMASK];
    
    return YES;
}

- (void)getConfiguredNetmaskCallback:(NSData*)returnData {
    if(returnData == nil) {
        return;
    }
    
    //It sends an extra packet containing only a semicolon with this request,
    //so we can discard it.
    //[kvmSocket readDataToLength:1 withTimeout:5 tag:KVM_TAG_NULL];
    
    NSString* returnString = [self getIpStringFromReturnBytes:(unsigned char*)[returnData bytes] confirmHeader:@"MA:"];
    
    for(id testCallback in callbackObjects) {
        if([testCallback respondsToSelector:@selector(getConfiguredNetmaskCallback:)]) {
            [testCallback performSelector:@selector(getConfiguredNetmaskCallback:) withObject:returnString];
        }
    }
}

- (BOOL)getConfiguredGateway {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:3];
    ((char*)[kvmCommand mutableBytes])[0] = 'G';
    ((char*)[kvmCommand mutableBytes])[1] = 'W';
    ((char*)[kvmCommand mutableBytes])[2] = '?';
    
    [self runKvmCommand:kvmCommand responseLength:19 dataTag:KVM_TAG_GET_CONFIGURED_GATEWAY];
    
    return YES;
}

- (void)getConfiguredGatewayCallback:(NSData*)returnData {
    if(returnData == nil) {
        return;
    }
    
    //It sends an extra packet containing only a semicolon with this request,
    //so we can discard it.
    //[kvmSocket readDataToLength:1 withTimeout:5 tag:KVM_TAG_NULL];
    
    NSString* returnString = [self getIpStringFromReturnBytes:(unsigned char*)[returnData bytes] confirmHeader:@"GW:"];
    
    for(id testCallback in callbackObjects) {
        if([testCallback respondsToSelector:@selector(getConfiguredGatewayCallback:)]) {
            [testCallback performSelector:@selector(getConfiguredGatewayCallback:) withObject:returnString];
        }
    }
}

- (BOOL)getConfiguredNetworkPort {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:3];
    ((char*)[kvmCommand mutableBytes])[0] = 'P';
    ((char*)[kvmCommand mutableBytes])[1] = 'T';
    ((char*)[kvmCommand mutableBytes])[2] = '?';
    
    [self runKvmCommand:kvmCommand responseLength:9 dataTag:KVM_TAG_GET_CONFIGURED_PORT];
    
    return YES;
}

- (void)getConfiguredNetworkPortCallback:(NSData*)returnData {
    if(returnData == nil) {
        return;
    }
    
    unsigned char * returnBytes = (unsigned char *)[returnData bytes];
    
    int byteOffset = 0;
    if(returnBytes[0] == ';') {
        byteOffset = 1;
    }
    
    if(returnBytes[0 + byteOffset] == 'P' && returnBytes[1 + byteOffset] == 'T' && returnBytes[2 + byteOffset] == ':' && returnBytes[8 - (8 * byteOffset)] == ';') {
        NSNumber* portNumber = @((10000 * (returnBytes[3] - '0')) + (1000 * (returnBytes[4] - '0')) + (100 * (returnBytes[5] - '0')) + (10 * (returnBytes[6] - '0')) + (returnBytes[7] - '0'));
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(getConfiguredPortCallback:)]) {
                [testCallback performSelector:@selector(getConfiguredPortCallback:) withObject:portNumber];
            }
        }
    } else {
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(getConfiguredPortCallback:)]) {
                [testCallback performSelector:@selector(getConfiguredPortCallback:) withObject:@(0)];
            }
        }
    }
}

- (BOOL)setConfiguredIpAddress:(NSString*)ipAddress {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:([ipAddress length] + 4)];
    ((char*)[kvmCommand mutableBytes])[0] = 'I';
    ((char*)[kvmCommand mutableBytes])[1] = 'P';
    ((char*)[kvmCommand mutableBytes])[2] = ':';
    for(int i=0; i<[ipAddress length]; i++) {
        ((char*)[kvmCommand mutableBytes])[i + 3] = [ipAddress characterAtIndex:i];
    }
    ((char*)[kvmCommand mutableBytes])[[ipAddress length] + 3] = ';';
    
    [self runKvmCommand:kvmCommand responseLength:2 dataTag:KVM_TAG_SET_CONFIGURED_IP];
    
    return YES;
}

- (void)setConfiguredIpAddressCallback:(NSData*)returnData {
    if(returnData == NULL) {
        return;
    }
    
    for(id testCallback in callbackObjects) {
        if([testCallback respondsToSelector:@selector(setConfiguredIpAddressCallback:)]) {
            [testCallback performSelector:@selector(setConfiguredIpAddressCallback:) withObject:[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding]];
        }
    }
}

- (BOOL)setConfiguredNetmask:(NSString*)netmask {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:([netmask length] + 4)];
    ((char*)[kvmCommand mutableBytes])[0] = 'M';
    ((char*)[kvmCommand mutableBytes])[1] = 'A';
    ((char*)[kvmCommand mutableBytes])[2] = ':';
    for(int i=0; i<[netmask length]; i++) {
        ((char*)[kvmCommand mutableBytes])[i + 3] = [netmask characterAtIndex:i];
    }
    ((char*)[kvmCommand mutableBytes])[[netmask length] + 3] = ';';
    
    [self runKvmCommand:kvmCommand responseLength:2 dataTag:KVM_TAG_SET_CONFIGURED_NETMASK];

    return YES;
}

- (void)setConfiguredNetmaskCallback:(NSData*)returnData {
    if(returnData == NULL) {
        return;
    }
    
    for(id testCallback in callbackObjects) {
        if([testCallback respondsToSelector:@selector(setConfiguredNetmaskCallback:)]) {
            [testCallback performSelector:@selector(setConfiguredNetmaskCallback:) withObject:[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding]];
        }
    }
}

- (BOOL)setConfiguredGateway:(NSString*)gatewayAddress {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:([gatewayAddress length] + 4)];
    ((char*)[kvmCommand mutableBytes])[0] = 'G';
    ((char*)[kvmCommand mutableBytes])[1] = 'W';
    ((char*)[kvmCommand mutableBytes])[2] = ':';
    for(int i=0; i<[gatewayAddress length]; i++) {
        ((char*)[kvmCommand mutableBytes])[i + 3] = [gatewayAddress characterAtIndex:i];
    }
    ((char*)[kvmCommand mutableBytes])[[gatewayAddress length] + 3] = ';';
    
   [self runKvmCommand:kvmCommand responseLength:2 dataTag:KVM_TAG_SET_CONFIGURED_GATEWAY];

    return YES;
}

- (void)setConfiguredGatewayCallback:(NSData*)returnData {
    if(returnData == NULL) {
        return;
    }
    
    for(id testCallback in callbackObjects) {
        if([testCallback respondsToSelector:@selector(setConfiguredGatewayCallback:)]) {
            [testCallback performSelector:@selector(setConfiguredGatewayCallback:) withObject:[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding]];
        }
    }
}

- (BOOL)setConfiguredNetworkPort:(int)networkPort {
    if(!isConnected && !pendingConnection) {
        return NO;
    }
    
    NSString* networkPortString = [@(networkPort) stringValue];
    
    NSMutableData* kvmCommand = [NSMutableData dataWithLength:([networkPortString length] + 4)];
    ((char*)[kvmCommand mutableBytes])[0] = 'P';
    ((char*)[kvmCommand mutableBytes])[1] = 'T';
    ((char*)[kvmCommand mutableBytes])[2] = ':';
    for(int i=0; i<[networkPortString length]; i++) {
        ((char*)[kvmCommand mutableBytes])[i + 3] = [networkPortString characterAtIndex:i];
    }
    ((char*)[kvmCommand mutableBytes])[[networkPortString length] + 3] = ';';
    
    [self runKvmCommand:kvmCommand responseLength:2 dataTag:KVM_TAG_SET_CONFIGURED_PORT];

    return YES;
}

- (void)setConfiguredNetworkPortCallback:(NSData*)returnData {
    if(returnData == NULL) {
        return;
    }
    
    for(id testCallback in callbackObjects) {
        if([testCallback respondsToSelector:@selector(setConfiguredPortCallback:)]) {
            [testCallback performSelector:@selector(setConfiguredPortCallback:) withObject:[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding]];
        }
    }
}

- (NSString*)getIpStringFromReturnBytes:(unsigned char *)dataArray confirmHeader:(NSString*)confirmHeader {
    
    int byteOffset = 0;
    
    if(dataArray[0] == ';') {
        byteOffset = 1;
    }
    
    if(dataArray[0 + byteOffset] == [confirmHeader characterAtIndex:0] && dataArray[1 + byteOffset] == [confirmHeader characterAtIndex:1] && dataArray[2 + byteOffset] == [confirmHeader characterAtIndex:2]) {
        NSMutableString* returnString = [[NSMutableString alloc] init];
        if(dataArray[3 + byteOffset] != '0') {
            [returnString appendFormat:@"%c", dataArray[3 + byteOffset]];
        }
        
        if(dataArray[4 + byteOffset] != '0') {
            [returnString appendFormat:@"%c", dataArray[4 + byteOffset]];
        }
        
        [returnString appendFormat:@"%c.", dataArray[5 + byteOffset]];
        
        if(dataArray[7 + byteOffset] != '0') {
            [returnString appendFormat:@"%c", dataArray[7 + byteOffset]];
        }
        
        if(dataArray[8 + byteOffset] != '0') {
            [returnString appendFormat:@"%c", dataArray[8 + byteOffset]];
        }
        
        [returnString appendFormat:@"%c.", dataArray[9 + byteOffset]];
        
        if(dataArray[11 + byteOffset] != '0') {
            [returnString appendFormat:@"%c", dataArray[11 + byteOffset]];
        }
        
        if(dataArray[12 + byteOffset] != '0') {
            [returnString appendFormat:@"%c", dataArray[12 + byteOffset]];
        }
        
        [returnString appendFormat:@"%c.", dataArray[13 + byteOffset]];
        
        if(dataArray[15 + byteOffset] != '0') {
            [returnString appendFormat:@"%c", dataArray[15 + byteOffset]];
        }
        
        if(dataArray[16 + byteOffset] != '0') {
            [returnString appendFormat:@"%c", dataArray[16 + byteOffset]];
        }
        
        [returnString appendFormat:@"%c", dataArray[17 + byteOffset]];
        
        return returnString;
    }
    
    return nil;
}

- (void)runKvmCommand:(NSData*)command responseLength:(unsigned int)responseLength dataTag:(long)dataTag {
    if(!isConnected && !pendingConnection) {
        return;
    }

    [kvmSocket writeData:command withTimeout:5 tag:dataTag];

    if(responseLength > 0) {
        [kvmSocket readDataToLength:responseLength withTimeout:5 tag:dataTag];
    }
}

- (void)socket:(GCDAsyncSocket*)sock didWriteDataWithTag:(long)tag {
    return;
}

- (void)socket:(GCDAsyncSocket*)sock didConnectToHost:(nonnull NSString *)host port:(uint16_t)port {
    NSLog(@"Connected to KVM at %@ on port %d", host, port);
    
    switchHost = host;
    switchPort = port;
    
    pendingConnection = NO;
    isConnected = YES;
    
    for(id testCallback in callbackObjects) {
        if([testCallback respondsToSelector:@selector(connectionCallback)]) {
            [testCallback performSelector:@selector(connectionCallback)];
        }
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    NSLog(@"Disconnected from KVM");
    
    switchHost = NULL;
    switchPort = 0;
    
    pendingConnection = NO;
    isConnected = NO;
    
    if(error == NULL) {
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(disconnectionCallback)]) {
                [testCallback performSelector:@selector(disconnectionCallback)];
            }
        }
    } else {
        for(id testCallback in callbackObjects) {
            if([testCallback respondsToSelector:@selector(disconnectionErrorCallback:)]) {
                [testCallback performSelector:@selector(disconnectionErrorCallback:) withObject:error];
            }
        }
    }
}

- (void)socket:(GCDAsyncSocket*)sender didReadData:(nonnull NSData *)data withTag:(long)tag {
    
    if(tag == KVM_TAG_GET_DISPLAY_PORT) {
        [self getDisplayPortCallback:data];
    } else if(tag == KVM_TAG_SET_DISPLAY_PORT) {
        [self setDisplayPortCallback:data];
    } else if(tag == KVM_TAG_GET_CONFIGURED_IP) {
        [self getConfiguredIpAddressCallback:data];
    } else if(tag == KVM_TAG_GET_CONFIGURED_NETMASK) {
        [self getConfiguredNetmaskCallback:data];
    } else if(tag == KVM_TAG_GET_CONFIGURED_GATEWAY) {
        [self getConfiguredGatewayCallback:data];
    } else if(tag == KVM_TAG_GET_CONFIGURED_PORT) {
        [self getConfiguredNetworkPortCallback:data];
    } else if(tag == KVM_TAG_SET_CONFIGURED_IP) {
        [self setConfiguredIpAddressCallback:data];
    } else if(tag == KVM_TAG_SET_CONFIGURED_NETMASK) {
        [self setConfiguredNetmaskCallback:data];
    } else if(tag == KVM_TAG_SET_CONFIGURED_GATEWAY) {
        [self setConfiguredGatewayCallback:data];
    } else if(tag == KVM_TAG_SET_CONFIGURED_PORT) {
        [self setConfiguredNetworkPortCallback:data];
    } else if(tag == KVM_TAG_NULL) {
        return;
    }
}

@end
