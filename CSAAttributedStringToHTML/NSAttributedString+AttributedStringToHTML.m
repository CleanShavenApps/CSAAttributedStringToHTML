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

// Function adapted from https://github.com/erica/uicolor-utilities
NSString *UIColorToHexString(UIColor *color)
{
	CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
	NSString *result = nil;

	if (model != kCGColorSpaceModelRGB && model != kCGColorSpaceModelMonochrome)
		return nil;
	
	CGFloat r, g, b, w = 0.0f;
	
	switch (model)
	{
		case kCGColorSpaceModelRGB:
		{
			[color getRed:&r green:&g blue:&b alpha:NULL];
			result = [NSString stringWithFormat:@"%02X%02X%02X",
					  (int) (r * 0xFF), (int) (g * 0xFF), (int) (b * 0xFF)];
			break;
		}
		case kCGColorSpaceModelMonochrome:
		{
			[color getWhite:&w alpha:NULL];
			result = [NSString stringWithFormat:@"%02X%02X%02X",
					  (int) (w * 0xFF), (int) (w * 0xFF), (int) (w * 0xFF)];
			break;
		}
		default:
			break;
	}
	
	return result;
}

#pragma mark -

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

#pragma mark -

// Check if the attributed string contains attributes that matches those specified in attributesToMatch at the index, returning the effective range in which this applies. We're not comparing by isEqualToDictionary:, as we expect to match with lesser number of attributes than the full set in attributesToMatch. Thus the lesser attributes you provide in attributesToMatch, the faster this comparison.
- (BOOL)containsAttributes:(NSDictionary *)attributesToMatch atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)effectiveRange
{
	if (!attributesToMatch.count)
	{
		NSAssert(0, @"Can't determine if containsAttributes:atIndex:effectiveRange: with empty attributesToMatch");
		return NO;
	}
	
	NSDictionary *attributesAtIndex =
	[self attributesAtIndex:index effectiveRange:effectiveRange];
	
	if (!attributesAtIndex.count)
		return NO;
	
	// Assume YES until proven otherwise
	__block BOOL containsAttributes = YES;
	
	[attributesToMatch enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		// As long as we have one non-matching key, say NO and get out of here
		if (![attributesAtIndex[key] isEqual:obj])
		{
			containsAttributes = NO;
			*stop = YES;
		}
	}];
	
	return containsAttributes;
}

// Returns YES if at least some text contains attributes matching this
- (BOOL)containsTextWithAttributes:(NSDictionary *)attributes inRange:(NSRange)range containsForEntireRange:(NSNumber **)appliesForEntireRange
{
	NSUInteger location = range.location;
	NSRange effectiveRange = NSMakeRange(0, 0);
	
	BOOL containsTextWithAttributesForLoop = NO; // For each loop
	BOOL containsAtLeastSomeTextWithAttributes = NO; // As long as one loop proves true
	BOOL fullyContainsTextWithAttributes = YES;	// Assume YES until proven otherwise
	BOOL needsToGoThroughEntireRange = appliesForEntireRange != NULL;
	
	while (location < NSMaxRange(range))
	{
		containsTextWithAttributesForLoop =
		[self containsAttributes:attributes
						 atIndex:location
				  effectiveRange:&effectiveRange];
		
		if (!containsTextWithAttributesForLoop)
			fullyContainsTextWithAttributes = NO;
		
		// Already contains text with attributes in this loop
		if (containsTextWithAttributesForLoop)
		{
			containsAtLeastSomeTextWithAttributes = YES;
			
			// And we're not expecting an answer whether or not this applies
			// for the entire range, exit now
			if (!needsToGoThroughEntireRange)
			{
				break;
			}
		}
		
		// Else march on ahead! And mark fullyContainsTextWithAttributes as NO
		else
		{
			fullyContainsTextWithAttributes = containsTextWithAttributesForLoop;
		}
		
		location = NSMaxRange(effectiveRange);
	}

	// Wants whether we fully contains text with matching attributes
	if (appliesForEntireRange != NULL)
		*appliesForEntireRange = @(fullyContainsTextWithAttributes);
	
	return containsAtLeastSomeTextWithAttributes;

}

- (BOOL)containsTextWithAttributes:(NSDictionary *)attributes inRange:(NSRange)range
{
	return [self containsTextWithAttributes:attributes inRange:range containsForEntireRange:NULL];
}

// Returns YES if the entire range contains text with such attributes
- (BOOL)fullyContainsTextWithAttributes:(NSDictionary *)attributes inRange:(NSRange)range
{
	NSNumber *fullyContains = nil;
	BOOL containsText = [self containsTextWithAttributes:attributes inRange:range containsForEntireRange:&fullyContains];
	return containsText && [fullyContains boolValue];
}

@end
