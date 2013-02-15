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

// Grabs the HTML for the range of attributed string. Pass in default attributes
// with font, size, color so that attributes similar to the default attributes
// will not be styled at all.
- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes
{
	NSMutableString *HTML = [NSMutableString string];
	
	NSUInteger location = range.location;
	NSRange effectiveRange = NSMakeRange(0, 0);

	while (location < NSMaxRange(range))
	{
		[HTML appendString:
		 [self HTMLAtIndex:location
	 longestEffectiveRange:&effectiveRange
		ignoringAttributes:defaultAttributes]];
		
		location = NSMaxRange(effectiveRange);
	}
	
	return HTML;
}

- (NSString *)HTMLAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes
{
	NSMutableString *HTML = [NSMutableString string];
	NSMutableString *openingTags = [NSMutableString string];
	NSMutableString *closingTags = [NSMutableString string];
		
	NSDictionary *attributes =
	[self attributesAtIndex:index
	  longestEffectiveRange:effectiveRange
					inRange:NSMakeRange(index, self.length - index)];

	BOOL shouldIgnoreAllAttributes =
	(attributes && [attributes isEqualToDictionary:defaultAttributes]);
	
	UIFont *defaultFont = defaultAttributes[NSFontAttributeName];
	
	if (!shouldIgnoreAllAttributes)
	{
		UIFont *effectiveFont = attributes[NSFontAttributeName];
//		UIColor *color = attributes[NSForegroundColorAttributeName];
		BOOL isUnderlined = [attributes[NSUnderlineStyleAttributeName] boolValue];
		
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
	}
	
	[HTML appendString:openingTags];
	[HTML appendString:EscapeHTMLEntitiesAndReplaceNewlinesWithBR([self.string substringWithRange:*effectiveRange])];
	[HTML appendString:closingTags];
	
	return HTML;
}

@end
