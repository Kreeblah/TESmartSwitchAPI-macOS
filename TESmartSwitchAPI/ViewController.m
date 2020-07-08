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
//  ViewController.m
//  TESmartSwitchAPI
//
//  Created by Chris Gelatt on 7/4/20.
//  Copyright © 2020 Chris Gelatt. All rights reserved.
//

#import "ViewController.h"
#import "SwitchAPI.h"
#import "RestrictedIntegerFormatter.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableDictionary* appDefaults = [[NSMutableDictionary alloc] initWithCapacity:10];
    [appDefaults setObject:@"192.168.1.10" forKey:@"kvmHost"];
    [appDefaults setObject:@(5000) forKey:@"kvmNetworkPort"];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    NSTextField* timeoutValue = (NSTextField*) [self.view viewWithTag:20];
    RestrictedIntegerFormatter* restrictedIntFormatter = [[RestrictedIntegerFormatter alloc] init];
    
    [restrictedIntFormatter setMininumValue:0 maximumValue:255];
    
    [timeoutValue setFormatter:restrictedIntFormatter];
    
    if(apiObj == nil) {
        apiObj = [SwitchAPI sharedInstance];
    }
    
    [apiObj registerCallbackObject:self];
}

- (IBAction)ConnectButton:(id)sender {
    if(![apiObj isConnected] && ![apiObj pendingConnection]) {
        NSButton* connectButton = (NSButton*) [self.view viewWithTag:22];
        [connectButton setTitle:@"Disconnect"];
        [connectButton sizeToFit];
        
        [apiObj connectToKvm:[[NSUserDefaults standardUserDefaults] stringForKey:@"kvmHost"] port:(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"kvmNetworkPort"]];
    } else {
        NSButton* disconnectButton = (NSButton*) [self.view viewWithTag:22];
        [disconnectButton setTitle:@"Connect"];
        [disconnectButton sizeToFit];
        
        [apiObj disconnectFromKvm];
    }
}

- (void)connectionCallback {
    [self enableKvmButtons:YES];
    
    [apiObj getDisplayPort];
    
    NSButton* connectButton = (NSButton*) [self.view viewWithTag:22];
    [connectButton setTitle:@"Disconnect"];
    [connectButton sizeToFit];
}

- (void)disconnectionCallback {
    [self enableKvmButtons:NO];
    currentPort = 0;

    NSButton* disconnectButton = (NSButton*) [self.view viewWithTag:22];
    [disconnectButton setTitle:@"Connect"];
    [disconnectButton sizeToFit];
}

- (IBAction)EnableBuzzer:(id)sender {
    [apiObj setBuzzerEnabled:YES];
}

- (IBAction)DisableBuzzer:(id)sender {
    [apiObj setBuzzerEnabled:NO];
}

- (IBAction)EnableActiveInputDetection:(id)sender {
    [apiObj setActiveInputDetectionEnabled:YES];
}

- (IBAction)DisableActiveInputDetection:(id)sender {
    [apiObj setActiveInputDetectionEnabled:NO];
}

- (IBAction)PortSelect:(id)sender {
    [apiObj setDisplayPort:(int)[sender tag]];
}

- (void)portSelectionCallback:(NSNumber*)selectedPortNumber {
    if(selectedPortNumber > 0) {
        currentPort = [selectedPortNumber intValue];
        [self setPortButton:currentPort];
    }
}

- (IBAction)SetDisplayTimeout:(id)sender {
    NSTextField* timeoutValueField = (NSTextField*) [self.view viewWithTag:20];
    [apiObj setDisplayTimeoutSeconds:(int)[timeoutValueField integerValue]];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)setPortButton:(int)portNumber {
    if(portNumber < 1 || portNumber > 16) {
        return;
    }
    
    NSArray* buttonArray = [self getPortButtonRefs];
    
    for(NSButton* tempButton in buttonArray) {
        [tempButton setState:NSControlStateValueOff];
    }
    
    [buttonArray[portNumber - 1] setState:NSControlStateValueOn];
}

- (void)enableKvmButtons:(bool)kvmButtonEnableBool {
    NSArray* buttonArray = [self getPortButtonRefs];
    
    for(NSButton* tempButton in buttonArray) {
        [tempButton setEnabled:kvmButtonEnableBool];
    }
    
    NSButton* enableBuzzerButton = (NSButton*) [self.view viewWithTag:17];
    [enableBuzzerButton setEnabled:kvmButtonEnableBool];
    
    NSButton* disableBuzzerButton = (NSButton*) [self.view viewWithTag:18];
    [disableBuzzerButton setEnabled:kvmButtonEnableBool];
    
    NSTextField* timeoutLabel = (NSTextField*) [self.view viewWithTag:19];
    [timeoutLabel setEnabled:kvmButtonEnableBool];
    
    NSTextField* timeoutValue = (NSTextField*) [self.view viewWithTag:20];
    [timeoutValue setEnabled:kvmButtonEnableBool];
    
    NSButton* timeoutSubmit = (NSButton*) [self.view viewWithTag:21];
    [timeoutSubmit setEnabled:kvmButtonEnableBool];
    
    NSButton* activeInputDetectionEnable = (NSButton*) [self.view viewWithTag:23];
    [activeInputDetectionEnable setEnabled:kvmButtonEnableBool];
    
    NSButton* activeInputDetectionDisable = (NSButton*) [self.view viewWithTag:24];
    [activeInputDetectionDisable setEnabled:kvmButtonEnableBool];
}

- (NSArray<NSButton*>*)getPortButtonRefs {
    NSMutableArray<NSButton*>* buttonArray = [[NSMutableArray alloc] init];
    
    NSButton* port1Button = (NSButton*) [self.view viewWithTag:1];
    NSButton* port2Button = (NSButton*) [self.view viewWithTag:2];
    NSButton* port3Button = (NSButton*) [self.view viewWithTag:3];
    NSButton* port4Button = (NSButton*) [self.view viewWithTag:4];
    NSButton* port5Button = (NSButton*) [self.view viewWithTag:5];
    NSButton* port6Button = (NSButton*) [self.view viewWithTag:6];
    NSButton* port7Button = (NSButton*) [self.view viewWithTag:7];
    NSButton* port8Button = (NSButton*) [self.view viewWithTag:8];
    NSButton* port9Button = (NSButton*) [self.view viewWithTag:9];
    NSButton* port10Button = (NSButton*) [self.view viewWithTag:10];
    NSButton* port11Button = (NSButton*) [self.view viewWithTag:11];
    NSButton* port12Button = (NSButton*) [self.view viewWithTag:12];
    NSButton* port13Button = (NSButton*) [self.view viewWithTag:13];
    NSButton* port14Button = (NSButton*) [self.view viewWithTag:14];
    NSButton* port15Button = (NSButton*) [self.view viewWithTag:15];
    NSButton* port16Button = (NSButton*) [self.view viewWithTag:16];
    
    [buttonArray addObject:port1Button];
    [buttonArray addObject:port2Button];
    [buttonArray addObject:port3Button];
    [buttonArray addObject:port4Button];
    [buttonArray addObject:port5Button];
    [buttonArray addObject:port6Button];
    [buttonArray addObject:port7Button];
    [buttonArray addObject:port8Button];
    [buttonArray addObject:port9Button];
    [buttonArray addObject:port10Button];
    [buttonArray addObject:port11Button];
    [buttonArray addObject:port12Button];
    [buttonArray addObject:port13Button];
    [buttonArray addObject:port14Button];
    [buttonArray addObject:port15Button];
    [buttonArray addObject:port16Button];

    return buttonArray;
}

@end
