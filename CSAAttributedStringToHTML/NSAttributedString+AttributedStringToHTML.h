//
//  NSAttributedString+AttributedStringToHTML.h
//  AttributedStringToHTML
//
//  Created by Lin Junjie on 15/2/13.
//  Copyright (c) 2013 Lin Junjie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTMNSString+HTML.h"

@interface NSAttributedString (AttributedStringToHTML)

- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes;
- (NSString *)HTMLAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes;

// Returns YES if at least some text contains attributes matching this
- (BOOL)containsTextWithAttributes:(NSDictionary *)attributes inRange:(NSRange)range;

// Returns YES if the entire range contains text with such attributes
- (BOOL)fullyContainsTextWithAttributes:(NSDictionary *)attributes inRange:(NSRange)range;

@end
