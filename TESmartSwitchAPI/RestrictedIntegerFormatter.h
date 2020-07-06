//
//  RestrictedIntegerFormatter.h
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RestrictedIntegerFormatter : NSNumberFormatter {
    int minValue;
    int maxValue;
}

- (void)setMininumValue:(int)minVal maximumValue:(int)maxVal;
- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString * _Nullable __autoreleasing *)newString errorDescription:(NSString * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
