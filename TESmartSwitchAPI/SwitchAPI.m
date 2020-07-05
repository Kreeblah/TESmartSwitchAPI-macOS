//
//  SwitchAPI.m
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import "SwitchAPI.h"

@implementation SwitchAPI

+ (SwitchAPI*)sharedInstance
{
    static SwitchAPI* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (BOOL)connectToKvm:(NSString*)connectionHost port:(int)connectionPort {
    if(connectionHost == nil || connectionHost.length == 0 || connectionPort < 1 || connectionPort > 65535 || switchHost != nil || switchPort != 0 || kvmInputStream != nil || kvmOutputStream != nil) {
        return NO;
    }
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)connectionHost, connectionPort, &readStream, &writeStream);
    
    NSInputStream* inputStream = (__bridge NSInputStream*)readStream;
    NSOutputStream* outputStream = (__bridge NSOutputStream*)writeStream;
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
    [inputStream open];
    [outputStream open];
    
    sleep(3);
    
    if([inputStream streamStatus] == 7 || [outputStream streamStatus] == 7) {
        [inputStream close];
        [outputStream close];
        
        return NO;
    }
    
    kvmInputStream = inputStream;
    kvmOutputStream = outputStream;
    
    switchHost = connectionHost;
    switchPort = connectionPort;

    return YES;
}

- (BOOL)disconnectFromKvm {
    if(switchHost == nil || switchPort == 0 || kvmInputStream == nil || kvmOutputStream == nil) {
        return NO;
    }
    
    [kvmInputStream close];
    [kvmOutputStream close];
    
    kvmInputStream = nil;
    kvmOutputStream = nil;
    
    switchHost = nil;
    switchPort = 0;
    
    return YES;
}

- (BOOL)isConnected {
    return (kvmInputStream != nil && kvmOutputStream != nil && switchHost != nil && switchPort != 0);
}

- (BOOL)setDisplayTimeoutSeconds:(int)timeoutSeconds {
    if(timeoutSeconds < 0 || timeoutSeconds > 255 || switchHost == nil || switchHost.length == 0 || switchPort < 1 || switchPort > 65535) {
        return NO;
    }
    
    NSMutableData* portCommand = [NSMutableData dataWithLength:6];
    
    ((char*)[portCommand mutableBytes])[0] = 0xaa;
    ((char*)[portCommand mutableBytes])[1] = 0xbb;
    ((char*)[portCommand mutableBytes])[2] = 0x03;
    ((char*)[portCommand mutableBytes])[3] = 0x03;
    ((char*)[portCommand mutableBytes])[4] = timeoutSeconds;
    ((char*)[portCommand mutableBytes])[5] = 0xee;
    
    [self runKvmCommand:portCommand hasData:NO];
    
    return YES;
}

- (BOOL)setBuzzerEnabled:(BOOL)buzzerEnable {
    if(switchHost == nil || switchHost.length == 0 || switchPort < 1 || switchPort > 65535) {
        return NO;
    }
    
    NSMutableData* portCommand = [NSMutableData dataWithLength:6];
    
    ((char*)[portCommand mutableBytes])[0] = 0xaa;
    ((char*)[portCommand mutableBytes])[1] = 0xbb;
    ((char*)[portCommand mutableBytes])[2] = 0x03;
    ((char*)[portCommand mutableBytes])[3] = 0x02;
    if(buzzerEnable) {
        ((char*)[portCommand mutableBytes])[4] = 0x01;
    } else {
        ((char*)[portCommand mutableBytes])[4] = 0x00;
    }
    ((char*)[portCommand mutableBytes])[5] = 0xee;
    
    [self runKvmCommand:portCommand hasData:NO];
    
    return YES;
}

- (int)getDisplayPort {
    if(switchHost == nil || switchHost.length == 0 || switchPort < 1 || switchPort > 65535) {
        return -1;
    }
    
    NSMutableData* portCommand = [NSMutableData dataWithLength:6];
    
    ((char*)[portCommand mutableBytes])[0] = 0xaa;
    ((char*)[portCommand mutableBytes])[1] = 0xbb;
    ((char*)[portCommand mutableBytes])[2] = 0x03;
    ((char*)[portCommand mutableBytes])[3] = 0x10;
    ((char*)[portCommand mutableBytes])[4] = 0x00;
    ((char*)[portCommand mutableBytes])[5] = 0xee;

    NSData* returnData = [self runKvmCommand:portCommand hasData:YES];
    
    if(returnData == nil) {
        return -1;
    }
    
    unsigned char* returnBytes = (unsigned char *)[returnData bytes];
    
    if(returnBytes[0] == 0xaa && returnBytes[1] == 0xbb && returnBytes[2] == 0x03 && returnBytes[3] == 0x11 && (returnBytes[5] == returnBytes[4] + 0x16)) {
        return (returnBytes[4] + 1);
    }
    
    return -1;
}

- (BOOL)setDisplayPort:(int)portNumber {
    if(portNumber < 1 || portNumber > 16 || switchHost == nil || switchHost.length == 0 || switchPort < 1 || switchPort > 65535) {
        return NO;
    }
    
    NSMutableData* portCommand = [NSMutableData dataWithLength:6];
    
    ((char*)[portCommand mutableBytes])[0] = 0xaa;
    ((char*)[portCommand mutableBytes])[1] = 0xbb;
    ((char*)[portCommand mutableBytes])[2] = 0x03;
    ((char*)[portCommand mutableBytes])[3] = 0x01;
    ((char*)[portCommand mutableBytes])[4] = portNumber;
    ((char*)[portCommand mutableBytes])[5] = 0xee;
    
    NSData* returnData = [self runKvmCommand:portCommand hasData:YES];
    
    if(returnData == nil) {
        return NO;
    }
    
    unsigned char * returnBytes = (unsigned char *)[returnData bytes];
    
    if(returnBytes[0] == 0xaa && returnBytes[1] == 0xbb && returnBytes[2] == 0x03 && returnBytes[3] == 0x11 && returnBytes[4] == (portNumber - 1) && returnBytes[5] == (0x15 + portNumber)) {
        return YES;
    }
    
    return NO;
}

- (NSString*)getConfiguredIpAddress {
    NSString* returnString = [self doIpCommand:@"IP?" confirmHeader:@"IP:" hasData:YES];
    
    //It sends an extra packet containing only a semicolon with this request,
    //so we can discard it.
    [kvmInputStream read:[[NSMutableData dataWithLength:1] mutableBytes] maxLength:1];
    return returnString;
}

- (NSString*)getConfiguredNetmask {
    NSString* returnString = [self doIpCommand:@"MA?" confirmHeader:@"MA:" hasData:YES];
    
    //It sends an extra packet containing only a semicolon with this request,
    //so we can discard it.
    [kvmInputStream read:[[NSMutableData dataWithLength:1] mutableBytes] maxLength:1];
    return returnString;
}

- (NSString*)getConfiguredGateway {
    NSString* returnString = [self doIpCommand:@"GW?" confirmHeader:@"GW:" hasData:YES];
    
    //It sends an extra packet containing only a semicolon with this request,
    //so we can discard it.
    [kvmInputStream read:[[NSMutableData dataWithLength:1] mutableBytes] maxLength:1];
    return returnString;
}

- (int)getConfiguredNetworkPort {
    if(switchHost.length == 0 || switchPort < 1 || switchPort > 65535 || kvmInputStream == nil || kvmOutputStream == nil) {
        return 0;
    }
    
    NSMutableData* portCommand = [NSMutableData dataWithLength:3];
    ((char*)[portCommand mutableBytes])[0] = 'P';
    ((char*)[portCommand mutableBytes])[1] = 'T';
    ((char*)[portCommand mutableBytes])[2] = '?';
    
    NSData* returnData = [self runKvmCommand:portCommand hasData:YES];
    
    if(returnData == nil) {
        return NO;
    }
    
    unsigned char * returnBytes = (unsigned char *)[returnData bytes];
    
    if(returnBytes[0] == 'P' && returnBytes[1] == 'T' && returnBytes[2] == ':' && returnBytes[8] == ';') {
        return (10000 * (returnBytes[3] - '0')) + (1000 * (returnBytes[4] - '0')) + (100 * (returnBytes[5] - '0')) + (10 * (returnBytes[6] - '0')) + (returnBytes[7] - '0');
    }

    return 0;
}

- (BOOL)setConfiguredIpAddress:(NSString*)ipAddress {
    if([self doIpCommand:[[@"IP:" stringByAppendingString:ipAddress] stringByAppendingString:@";"] confirmHeader:@"OK" hasData:NO] != nil) {
        return YES;
    }
    
    return NO;
}

- (BOOL)setConfiguredNetmask:(NSString*)netmask {
    if([self doIpCommand:[[@"MA:" stringByAppendingString:netmask] stringByAppendingString:@";"] confirmHeader:@"OK" hasData:NO] != nil) {
        return YES;
    }
    
    return NO;
}

- (BOOL)setConfiguredGateway:(NSString*)gatewayAddress {
    if([self doIpCommand:[[@"GW:" stringByAppendingString:gatewayAddress] stringByAppendingString:@";"] confirmHeader:@"OK" hasData:NO] != nil) {
        return YES;
    }
    
    return NO;
}

- (BOOL)setConfiguredNetworkPort:(int)networkPort {
    if([self doIpCommand:[[@"PT:" stringByAppendingString:[@(networkPort) stringValue]] stringByAppendingString:@";"] confirmHeader:@"OK" hasData:NO] != nil) {
        return YES;
    }
    
    return NO;
}

- (NSString*)doIpCommand:(NSString*)commandString confirmHeader:(NSString*)confirmHeader hasData:(BOOL)hasData {
    if(switchHost.length == 0 || switchPort < 1 || switchPort > 65535 || kvmInputStream == nil || kvmOutputStream == nil) {
        return nil;
    }
    
    NSData* portCommand = [NSData dataWithBytesNoCopy:(void *)[commandString UTF8String] length:[commandString length] freeWhenDone:NO];
    
    if(portCommand == nil) {
        return nil;
    }
    
    if(hasData) {
        return [self getIpStringFromReturnBytes:(unsigned char *)[[self runKvmCommand:portCommand hasData:YES] bytes] confirmHeader:confirmHeader];
    } else {
        return [[NSString alloc] initWithData:portCommand encoding:NSUTF8StringEncoding];
    }
    
}

- (NSString*)getIpStringFromReturnBytes:(unsigned char *)dataArray confirmHeader:(NSString*)confirmHeader {
    if(dataArray[0] == [confirmHeader characterAtIndex:0] && dataArray[1] == [confirmHeader characterAtIndex:1] && dataArray[2] == [confirmHeader characterAtIndex:2]) {
        NSMutableString* returnString = [[NSMutableString alloc] init];
        if(dataArray[3] != '0') {
            [returnString appendFormat:@"%c", dataArray[3]];
        }
        
        if(dataArray[4] != '0') {
            [returnString appendFormat:@"%c", dataArray[4]];
        }
        
        [returnString appendFormat:@"%c.", dataArray[5]];
        
        if(dataArray[7] != '0') {
            [returnString appendFormat:@"%c", dataArray[7]];
        }
        
        if(dataArray[8] != '0') {
            [returnString appendFormat:@"%c", dataArray[8]];
        }
        
        [returnString appendFormat:@"%c.", dataArray[9]];
        
        if(dataArray[11] != '0') {
            [returnString appendFormat:@"%c", dataArray[11]];
        }
        
        if(dataArray[12] != '0') {
            [returnString appendFormat:@"%c", dataArray[12]];
        }
        
        [returnString appendFormat:@"%c.", dataArray[13]];
        
        if(dataArray[15] != '0') {
            [returnString appendFormat:@"%c", dataArray[15]];
        }
        
        if(dataArray[16] != '0') {
            [returnString appendFormat:@"%c", dataArray[16]];
        }
        
        [returnString appendFormat:@"%c", dataArray[17]];
        
        return returnString;
    }
    
    return nil;
}

- (NSData*)runKvmCommand:(NSData*)command hasData:(BOOL)hasData {
    if([kvmInputStream streamStatus] == NSStreamStatusError || [kvmOutputStream streamStatus] == NSStreamStatusError) {
        return nil;
    }

    [kvmOutputStream write:[command bytes] maxLength:[command length]];

    if(hasData) {
        NSMutableData* recvBuff = [NSMutableData dataWithLength:256];
        
        [kvmInputStream read:[recvBuff mutableBytes] maxLength:256];
        
        return recvBuff;
    } else {
        return nil;
    }
}

@end
