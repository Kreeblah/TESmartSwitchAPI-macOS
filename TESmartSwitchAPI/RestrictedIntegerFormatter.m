//
//  RestrictedIntegerFormatter.m
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import "RestrictedIntegerFormatter.h"

@implementation RestrictedIntegerFormatter

- (void)setMininumValue:(int)minVal maximumValue:(int)maxVal {
    minValue = minVal;
    maxValue = maxVal;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString * _Nullable __autoreleasing *)newString errorDescription:(NSString * _Nullable __autoreleasing *)error {
    if([partialString length] == 0) {
        return YES;
    }
    
    NSScanner* scanner = [NSScanner scannerWithString:partialString];
    
    if(!([scanner scanInt:0] && [scanner isAtEnd])) {
        return NO;
    }
    
    int stringNumericValue = (int)[partialString integerValue];
    
    if(stringNumericValue < minValue || stringNumericValue > maxValue) {
        return NO;
    }
    
    return YES;
}

@end
