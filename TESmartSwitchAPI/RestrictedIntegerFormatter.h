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
//  RestrictedIntegerFormatter.h
//  TESmart Switch API
//
//  Created by Chris Gelatt on 7/5/20.
//  Copyright © 2020 Chris Gelatt. All rights reserved.
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
