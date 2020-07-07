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
    if(![obj isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    return obj;
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString * _Nullable __autoreleasing *)error {
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString * _Nullable __autoreleasing *)newString errorDescription:(NSString * _Nullable __autoreleasing *)error {
    if([partialString length] == 0) {
        NSLog(@"Found zero-length IP address string.");
        return YES;
    }
    
    NSLog(@"Searching matches for IP address string: %@", partialString);
    
    NSRange searchRange = NSMakeRange(0, [partialString length]);
    NSString* ipv4Pattern = @"^(25[0-5]\\.|2[0-4][0-9]\\.|[01]?[0-9][0-9]?\\.){0,3}?((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))?$";
    NSError* searchError = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:ipv4Pattern options:0 error:&searchError];
    unsigned long regexMatches = [regex numberOfMatchesInString:partialString options:0 range:searchRange];
    
    NSLog(@"Found %ld matches for IP address string: %@", regexMatches, partialString);
    
    if(regexMatches == 0) {
        return NO;
    }
    
    return YES;
}

@end
