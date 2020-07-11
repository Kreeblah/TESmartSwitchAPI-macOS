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
//  IPAddressFormatter.m
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Chris Gelatt. All rights reserved.
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
        return YES;
    }
    
    NSRange searchRange = NSMakeRange(0, [partialString length]);
    NSString* ipv4Pattern = @"^(25[0-5]\\.|2[0-4][0-9]\\.|1[0-9][0-9]\\.|[1-9][0-9]\\.|[0-9]\\.){0,3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])?$";
    NSError* searchError = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:ipv4Pattern options:0 error:&searchError];
    unsigned long regexMatches = [regex numberOfMatchesInString:partialString options:0 range:searchRange];
    
    if(regexMatches != 1) {
        return NO;
    }
    
    return YES;
}

@end
