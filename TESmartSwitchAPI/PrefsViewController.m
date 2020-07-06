//
//  PrefsViewController.m
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import "PrefsViewController.h"
#import "SwitchAPI.h"
#import "IPAddressFormatter.h"
#import "RestrictedIntegerFormatter.h"

@implementation PrefsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableDictionary* appDefaults = [[NSMutableDictionary alloc] initWithCapacity:10];
    [appDefaults setObject:@"192.168.1.10" forKey:@"kvmHost"];
    [appDefaults setObject:@(5000) forKey:@"kvmNetworkPort"];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    NSTextField* connectionIpTextField = (NSTextField*) [self.view viewWithTag:1];
    [connectionIpTextField bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.kvmHost" options:nil];
    
    NSTextField* connectionPortTextField = (NSTextField*) [self.view viewWithTag:2];
    [connectionPortTextField bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.kvmNetworkPort" options:nil];
    
    NSTextField* configurationIpAddressTextField = (NSTextField*) [self.view viewWithTag:3];
    NSTextField* configurationPortTextField = (NSTextField*) [self.view viewWithTag:4];
    NSTextField* configurationNetmaskTextField = (NSTextField*) [self.view viewWithTag:5];
    NSTextField* configurationGatewayTextField = (NSTextField*) [self.view viewWithTag:6];
    
    IPAddressFormatter* ipAddrFormatter = [[IPAddressFormatter alloc] init];
    
    [configurationIpAddressTextField setFormatter:ipAddrFormatter];
    [configurationNetmaskTextField setFormatter:ipAddrFormatter];
    [configurationGatewayTextField setFormatter:ipAddrFormatter];
    
    RestrictedIntegerFormatter* restrictedIntFormatter = [[RestrictedIntegerFormatter alloc] init];
    
    [restrictedIntFormatter setMininumValue:0 maximumValue:65535];
    
    [connectionPortTextField setFormatter:restrictedIntFormatter];
    [configurationPortTextField setFormatter:restrictedIntFormatter];
    
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
