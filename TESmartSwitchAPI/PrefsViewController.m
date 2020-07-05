//
//  PrefsViewController.m
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import "PrefsViewController.h"
#import "SwitchAPI.h"

@implementation PrefsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableDictionary* appDefaults = [[NSMutableDictionary alloc] initWithCapacity:10];
    [appDefaults setObject:@"192.168.1.10" forKey:@"kvmHost"];
    [appDefaults setObject:@(5000) forKey:@"kvmNetworkPort"];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    NSTextField* ipTextField = (NSTextField*) [self.view viewWithTag:1];
    [ipTextField bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.kvmHost" options:nil];
    
    NSTextField* portTextField = (NSTextField*) [self.view viewWithTag:2];
    [portTextField bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.kvmNetworkPort" options:nil];
    
    if(apiObj == nil) {
        apiObj = [SwitchAPI sharedInstance];
    }
}

- (IBAction)GetKvmConfiguration:(id)sender {
    BOOL isConnected = [apiObj isConnected];
    
    if(!isConnected) {
        if(![apiObj connectToKvm:[[NSUserDefaults standardUserDefaults] stringForKey:@"kvmHost"] port:(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"kvmNetworkPort"]]) {
            return;
        }
    }

    NSTextField* ipTextField = (NSTextField*) [self.view viewWithTag:3];
    [ipTextField setStringValue:[apiObj getConfiguredIpAddress]];
    
    NSTextField* portTextField = (NSTextField*) [self.view viewWithTag:4];
    [portTextField setStringValue:[@([apiObj getConfiguredNetworkPort]) stringValue]];
    
    NSTextField* netmaskTextField = (NSTextField*) [self.view viewWithTag:5];
    [netmaskTextField setStringValue:[apiObj getConfiguredNetmask]];
    
    NSTextField* gatewayTextField = (NSTextField*) [self.view viewWithTag:6];
    [gatewayTextField setStringValue:[apiObj getConfiguredGateway]];
    
    if(!isConnected) {
        [apiObj disconnectFromKvm];
    }
}

- (IBAction)SetKvmConfiguration:(id)sender {
    BOOL isConnected = [apiObj isConnected];
    
    if(!isConnected) {
        if(![apiObj connectToKvm:[[NSUserDefaults standardUserDefaults] stringForKey:@"KvmHost"] port:(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"KvmNetworkPort"]]) {
            return;
        }
    }

    NSTextField* ipTextField = (NSTextField*) [self.view viewWithTag:3];
    [apiObj setConfiguredIpAddress:[ipTextField stringValue]];
    
    NSTextField* portTextField = (NSTextField*) [self.view viewWithTag:4];
    [apiObj setConfiguredNetworkPort:[portTextField intValue]];
    
    NSTextField* netmaskTextField = (NSTextField*) [self.view viewWithTag:5];
    [apiObj setConfiguredGateway:[netmaskTextField stringValue]];
    
    NSTextField* gatewayTextField = (NSTextField*) [self.view viewWithTag:6];
    [apiObj setConfiguredGateway:[gatewayTextField stringValue]];
    
    if(!isConnected) {
        [apiObj disconnectFromKvm];
    }
}

@end
