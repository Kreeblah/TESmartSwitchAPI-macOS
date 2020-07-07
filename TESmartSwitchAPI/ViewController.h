//
//  ViewController.h
//  TESmartSwitchAPI
//
//  Created by Chris Gelatt on 7/4/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SwitchAPI.h"

@interface ViewController : NSViewController <SwitchAPICallback> {
    @private int currentPort;
    @private SwitchAPI* apiObj;
}

- (void)connectionCallback;
- (void)disconnectionCallback;
- (void)portSelectionCallback:(NSNumber*)newPortNumber;

@end

