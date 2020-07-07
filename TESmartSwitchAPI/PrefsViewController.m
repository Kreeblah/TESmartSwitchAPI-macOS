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
//  PrefsViewController.m
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Chris Gelatt. All rights reserved.
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
    
    if([apiObj isConnected]) {
        [self connectionCallback];
    }
    
    [apiObj registerCallbackObject:self];
}

- (IBAction)ConnectButton:(id)sender {
    if(![apiObj isConnected] && ![apiObj pendingConnection]) {
        [apiObj connectToKvm:[[NSUserDefaults standardUserDefaults] stringForKey:@"kvmHost"] port:(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"kvmNetworkPort"]];
    } else {
        [apiObj disconnectFromKvm];
    }
}

- (void)connectionCallback {
    NSButton* connectButton = (NSButton*) [self.view viewWithTag:7];
    [connectButton setTitle:@"Disconnect"];
    [connectButton sizeToFit];
    
    NSTextField* ipAddressField = (NSTextField*) [self.view viewWithTag:3];
    [ipAddressField setEnabled:YES];
    
    NSTextField* portField = (NSTextField*) [self.view viewWithTag:4];
    [portField setEnabled:YES];
    
    NSTextField* netmaskField = (NSTextField*) [self.view viewWithTag:5];
    [netmaskField setEnabled:YES];
    
    NSTextField* gatewayField = (NSTextField*) [self.view viewWithTag:6];
    [gatewayField setEnabled:YES];
    
    NSButton* getConfigurationButton = (NSButton*) [self.view viewWithTag:8];
    [getConfigurationButton setEnabled:YES];
    
    NSButton* setConfigurationButton = (NSButton*) [self.view viewWithTag:9];
    [setConfigurationButton setEnabled:YES];
}

- (void)disconnectionCallback {
    NSButton* disconnectButton = (NSButton*) [self.view viewWithTag:7];
    [disconnectButton setTitle:@"Connect"];
    [disconnectButton sizeToFit];
    
    NSTextField* ipAddressField = (NSTextField*) [self.view viewWithTag:3];
    [ipAddressField setEnabled:NO];
    
    NSTextField* portField = (NSTextField*) [self.view viewWithTag:4];
    [portField setEnabled:NO];
    
    NSTextField* netmaskField = (NSTextField*) [self.view viewWithTag:5];
    [netmaskField setEnabled:NO];
    
    NSTextField* gatewayField = (NSTextField*) [self.view viewWithTag:6];
    [gatewayField setEnabled:NO];
    
    NSButton* getConfigurationButton = (NSButton*) [self.view viewWithTag:8];
    [getConfigurationButton setEnabled:NO];
    
    NSButton* setConfigurationButton = (NSButton*) [self.view viewWithTag:9];
    [setConfigurationButton setEnabled:NO];
}

- (IBAction)GetKvmConfiguration:(id)sender {
    [apiObj getConfiguredIpAddress];
    sleep(1);
    [apiObj getConfiguredNetworkPort];
    sleep(1);
    [apiObj getConfiguredNetmask];
    sleep(1);
    [apiObj getConfiguredGateway];
}

- (void)getConfiguredIpAddressCallback:(NSString*)ipAddress {
    NSTextField* ipTextField = (NSTextField*) [self.view viewWithTag:3];
    [ipTextField setStringValue:ipAddress];
}

- (void)getConfiguredPortCallback:(NSNumber*)portNumber {
    NSTextField* portTextField = (NSTextField*) [self.view viewWithTag:4];
    [portTextField setStringValue:[portNumber stringValue]];
}

- (void)getConfiguredNetmaskCallback:(NSString*)netmask {
    NSTextField* netmaskTextField = (NSTextField*) [self.view viewWithTag:5];
    [netmaskTextField setStringValue:netmask];
}

- (void)getConfiguredGatewayCallback:(NSString*)gateway {
    NSTextField* gatewayTextField = (NSTextField*) [self.view viewWithTag:6];
    [gatewayTextField setStringValue:gateway];
}

- (IBAction)SetKvmConfiguration:(id)sender {
    NSTextField* ipTextField = (NSTextField*) [self.view viewWithTag:3];
    [apiObj setConfiguredIpAddress:[ipTextField stringValue]];
    
    sleep(1);
    
    NSTextField* portTextField = (NSTextField*) [self.view viewWithTag:4];
    [apiObj setConfiguredNetworkPort:[portTextField intValue]];
    
    sleep(1);
    
    NSTextField* netmaskTextField = (NSTextField*) [self.view viewWithTag:5];
    [apiObj setConfiguredNetmask:[netmaskTextField stringValue]];
    
    sleep(1);
    
    NSTextField* gatewayTextField = (NSTextField*) [self.view viewWithTag:6];
    [apiObj setConfiguredGateway:[gatewayTextField stringValue]];
}

@end
