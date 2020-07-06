//
//  IPAddressFormatter.m
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Kreeblah. All rights reserved.
//

#import "IPAddressFormatter.h"

@implementation IPAddressFormatter

- (NSString*)stringForObjectValue:(id)obj {
    return obj;
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString * _Nullable __autoreleasing *)error {
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString * _Nullable __autoreleasing *)newString errorDescription:(NSString * _Nullable __autoreleasing *)error {
    if([partialString length] == 0) {
        return YES;
    }
    
    NSRange searchRange = NSMakeRange(0, [partialString length]);
//    NSString* ipv4Pattern = @"^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$";
    NSString* ipv4Pattern = @"^(25[0-5]\\.|2[0-4][0-9]\\.|[01]?[0-9][0-9]?\\.){0,3}?((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))?$";
    NSError* searchError = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:ipv4Pattern options:0 error:&searchError];
    unsigned long regexMatches = [regex numberOfMatchesInString:partialString options:0 range:searchRange];
    
    if(regexMatches == 0) {
        return NO;
    }
    
    return YES;
}

@end
