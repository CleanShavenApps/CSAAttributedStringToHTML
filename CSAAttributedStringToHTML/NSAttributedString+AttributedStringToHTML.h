//
//  NSAttributedString+AttributedStringToHTML.h
//  AttributedStringToHTML
//
//  Created by Lin Junjie on 15/2/13.
//  Copyright (c) 2013 Lin Junjie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTMNSString+HTML.h"

// The attributes dictionary we want to match...
#define CSACustomAttributesDictionaryKey	@"CSACustomAttributesDictionaryKey"
// ... that would cause the matching text to be wrapped in the
// opening and closing HTML tags below
#define CSACustomAttributesOpenTagKey		@"CSACustomAttributesOpenTagKey"
#define CSACustomAttributesCloseTagKey		@"CSACustomAttributesCloseTagKey"

@interface NSAttributedString (AttributedStringToHTML)

// Grabs the HTML for the range of attributed string. Pass in default attributes
// with font, size, color so that attributes similar to the default attributes
// will not be styled at all.
- (NSString *)HTMLFromRange:(NSRange)range
		 ignoringAttributes:(NSDictionary *)defaultAttributes;

// Same as above, but pass in an array of NSDictionaries containing the 3 keys above
- (NSString *)HTMLFromRange:(NSRange)range
		 ignoringAttributes:(NSDictionary *)defaultAttributes
	customTagsForAttributes:(NSArray *)customAttributesList;

// Used by HTMLFromRange:ignoringAttributes:customTagsForAttributes: in loop
- (NSString *)HTMLAtIndex:(NSUInteger)index
	longestEffectiveRange:(NSRangePointer)effectiveRange
	   ignoringAttributes:(NSDictionary *)defaultAttributes
  customTagsForAttributes:(NSArray *)customAttributesList;

@end
