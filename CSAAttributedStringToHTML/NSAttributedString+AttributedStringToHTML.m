//
//  NSAttributedString+AttributedStringToHTML.m
//  AttributedStringToHTML
//
//  Created by Lin Junjie on 15/2/13.
//  Copyright (c) 2013 Lin Junjie. All rights reserved.
//

#import "NSAttributedString+AttributedStringToHTML.h"

@implementation NSAttributedString (AttributedStringToHTML)

NSString *EscapeHTMLEntitiesAndReplaceNewlinesWithBR(NSString* string)
{
	NSString *plainTextEscapedForHTML =
	[string gtm_stringByEscapingForHTML];
	
	NSString *plainTextWithBRTags =
	[plainTextEscapedForHTML stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"];
	
	return plainTextWithBRTags;
}

NSString *WrapEscapedContentWithTags(NSString* escapedContent, NSString *openingTags, NSString *closingTags)
{
	return [NSString stringWithFormat:@"%@%@%@", openingTags, escapedContent, closingTags];
}

// Grabs the HTML for the range of attributed string. Pass in default attributes
// with font, size, color so that attributes similar to the default attributes
// will not be styled at all.
- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes
{
	return [self HTMLFromRange:range
			ignoringAttributes:defaultAttributes
	   customTagsForAttributes:nil];
}

- (NSString *)HTMLFromRange:(NSRange)range
		 ignoringAttributes:(NSDictionary *)defaultAttributes
	customTagsForAttributes:(NSArray *)customAttributesList
{
	NSMutableString *HTML = [NSMutableString string];
	
	NSUInteger location = range.location;
	NSRange effectiveRange = NSMakeRange(0, 0);

	while (location < NSMaxRange(range))
	{
		[HTML appendString:
		 [self HTMLAtIndex:location
	 longestEffectiveRange:&effectiveRange
		ignoringAttributes:defaultAttributes
   customTagsForAttributes:customAttributesList]];
		
		location = NSMaxRange(effectiveRange);
	}
	
	return HTML;
}

- (NSString *)HTMLAtIndex:(NSUInteger)index
	longestEffectiveRange:(NSRangePointer)effectiveRange
	   ignoringAttributes:(NSDictionary *)defaultAttributes
  customTagsForAttributes:(NSArray *)customAttributesList
{		
	NSDictionary *attributesAtIndex =
	[self attributesAtIndex:index
	  longestEffectiveRange:effectiveRange
					inRange:NSMakeRange(index, self.length - index)];

	
	NSString *escapedContent =
	EscapeHTMLEntitiesAndReplaceNewlinesWithBR([self.string substringWithRange:*effectiveRange]);

	
	// If we're ignoring attributes, return just the escaped content
	BOOL shouldIgnoreAllAttributes =
	(attributesAtIndex && [attributesAtIndex isEqualToDictionary:defaultAttributes]);
		
	if (shouldIgnoreAllAttributes)
		return escapedContent;
	

	// Check to see if we should wrap this with custom tags
	for (NSDictionary *customAttributeDictionary in customAttributesList)
	{
		NSDictionary *customAttributes = customAttributeDictionary[CSACustomAttributesDictionaryKey];
		if (customAttributes && [customAttributes isEqualToDictionary:attributesAtIndex])
		{
#warning Return here. How about formatted content within custom attributes?!
		}
	}
	
	
	// Else, wrap the content with any necessary formatting
	NSMutableString *openingTags = [NSMutableString string];
	NSMutableString *closingTags = [NSMutableString string];
	
	UIFont *defaultFont = defaultAttributes[NSFontAttributeName];
	UIFont *effectiveFont = attributesAtIndex[NSFontAttributeName];
	//		UIColor *color = attributes[NSForegroundColorAttributeName];
	BOOL isUnderlined = [attributesAtIndex[NSUnderlineStyleAttributeName] boolValue];
	
	if (effectiveFont && ![effectiveFont isEqual:defaultFont])
	{
		NSString *lowercaseFontDescription = [[effectiveFont description] lowercaseString];
		
		if ([lowercaseFontDescription rangeOfString:@"font-weight: bold"].location != NSNotFound)
		{
			[openingTags appendString:@"<strong>"];
			[closingTags insertString:@"</strong>" atIndex:0];
		}
		
		else if ([lowercaseFontDescription rangeOfString:@"font-style: italic"].location != NSNotFound)
		{
			[openingTags appendString:@"<em>"];
			[closingTags insertString:@"</em>" atIndex:0];
		}
	}
	
	if (isUnderlined)
	{
		[openingTags appendString:@"<u>"];
		[closingTags insertString:@"</u>" atIndex:0];
	}
	
	return WrapEscapedContentWithTags(escapedContent, openingTags, closingTags);
}

@end
