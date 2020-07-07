//
//  PrefsViewController.h
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SwitchAPI.h"

NS_ASSUME_NONNULL_BEGIN

@interface PrefsViewController : NSViewController <SwitchAPICallback> {
    @private SwitchAPI* apiObj;
}

@end

NS_ASSUME_NONNULL_END
