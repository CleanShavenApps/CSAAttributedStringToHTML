//
//  NSAttributedString+AttributedStringToHTML.h
//  AttributedStringToHTML
//
//  Created by Lin Junjie on 15/2/13.
//  Copyright (c) 2013 Lin Junjie. All rights reserved.
//

#define CSASpecialTagAttributesKey	@"CSASpecialTagAttributesKey"
#define CSASpecialTagOpenKey		@"CSASpecialTagOpenKey"
#define CSASpecialTagCloseKey		@"CSASpecialTagCloseKey"

#import <Foundation/Foundation.h>
#import "GTMNSString+HTML.h"

@interface NSAttributedString (AttributedStringToHTML)

// Grabs the HTML for the range of attributed string. Pass in default attributes
// with font, size, color so that attributes similar to the default attributes
// will not be styled at all. Pass an array containing dictionaries with
// CSASpecialTagAttributesKey and CSASpecialTagTagKey to mark text matching
// attributes in CSASpecialTagAttributesKey, with opening and closing tags in
// CSASpecialTagOpenKey and CSASpecialTagCloseKey
- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes;
- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes;

- (NSString *)HTMLAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes;
- (NSString *)HTMLAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes;

//
// Search through the text in the _range_ for any attributed text that contains matching attributes
//
// Returns YES if at least some text contains attributes matching this
- (BOOL)containsTextWithAttributes:(NSDictionary *)attributes inRange:(NSRange)range;

// Returns YES if the entire range contains text with such attributes
- (BOOL)fullyContainsTextWithAttributes:(NSDictionary *)attributes inRange:(NSRange)range;


//
// Look only at the text at the _index_ for any attributed text that contains matching attributes
//

// Check if the attributed string contains attributes that matches those specified in attributesToMatch at the index, returning the effective range in which this applies. We're not comparing by isEqualToDictionary:, as we expect to match with lesser number of attributes than the full set in attributesToMatch. Thus the lesser attributes you provide in attributesToMatch, the faster this comparison.
- (BOOL)containsAttributes:(NSDictionary *)attributesToMatch atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)effectiveRange;

// The longest effective range version of the above method, less efficient performance wise
- (BOOL)containsAttributes:(NSDictionary *)attributesToMatch atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)longestEffectiveRange;

@end
