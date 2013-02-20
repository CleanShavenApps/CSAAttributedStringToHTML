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

- (NSDictionary *)_HTMLElementByRemovingTag:(NSString *)tagName
									fromKey:(NSString *)key
							  ofHTMLElement:(NSDictionary *)HTMLElement
{
	NSArray *currentTagsInKey = HTMLElement[key];
	
	if (!currentTagsInKey.count)
		return HTMLElement;
	
	NSMutableDictionary *adjustedHTMLElement =
	[NSMutableDictionary dictionaryWithDictionary:HTMLElement];
	
	NSMutableArray *adjustedTags = [NSMutableArray arrayWithArray:currentTagsInKey];
	[adjustedTags removeObject:tagName];
	
	adjustedHTMLElement[key] = adjustedTags;
	
	return adjustedHTMLElement;
}

// Grabs the HTML for the range of attributed string. Pass in default attributes
// with font, size, color so that attributes similar to the default attributes
// will not be styled at all. Pass an array containing dictionaries with
// CSASpecialTagAttributesKey and CSASpecialTagTagKey to mark text matching
// attributes in CSASpecialTagAttributesKey with tag in CSASpecialTagTagKey.
// Provide mergerStartTag and mergeEndTag to merge contiguous tags into one
- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes mergeContiguousStartTag:(NSString *)mergeStartTag contiguousEndTag:(NSString *)mergeEndTag
{
	NSMutableString *HTML = [NSMutableString string];
	
	NSUInteger location = range.location;
	NSRange effectiveRange = NSMakeRange(0, 0);
		
	NSDictionary *lastHTMLElement = nil;
	NSDictionary *currHTMLElement = nil;
	
	BOOL hasNonBreakingTags = mergeStartTag != nil && mergeEndTag != nil;
	
	while (location < NSMaxRange(range))
	{
		currHTMLElement =
		[self HTMLElementAtIndex:location longestEffectiveRange:&effectiveRange ignoringAttributes:defaultAttributes useTagsForTextMatchingAttributes:tagsForAttributes];
		
		NSArray *currStartTags = currHTMLElement[CSAHTMLElementStartTags];
		
		// Current start tag contains a non-breaking tag
		if (hasNonBreakingTags && [currStartTags containsObject:mergeStartTag])
		{
			// Last end tag contains a non-breaking tag
			if ([lastHTMLElement[CSAHTMLElementEndTags] containsObject:mergeEndTag])
			{
				// 1) Remove non-breaking end tag from lastHTMLElement
				lastHTMLElement =
				[self _HTMLElementByRemovingTag:mergeEndTag
										fromKey:CSAHTMLElementEndTags
								  ofHTMLElement:lastHTMLElement];
				
				// 2) Remove non-breaking start tag from currHTMLElement
				currHTMLElement =
				[self _HTMLElementByRemovingTag:mergeStartTag
										fromKey:CSAHTMLElementStartTags
								  ofHTMLElement:currHTMLElement];
			}
		}
		
		// Append the last element
		[HTML appendString:
		 [self HTMLElementStringFromHTMLElementDictionary:lastHTMLElement]];
				
		// Replace last HTML element with the current one
		lastHTMLElement = currHTMLElement;
		location = NSMaxRange(effectiveRange);
	}
	
	if (location > 0)
	{
		// Append the last one we didn't manage to append
		[HTML appendString:
		 [self HTMLElementStringFromHTMLElementDictionary:lastHTMLElement]];
	}
	
	return HTML;
}

- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes
{
	return [self HTMLFromRange:range ignoringAttributes:defaultAttributes useTagsForTextMatchingAttributes:tagsForAttributes mergeContiguousStartTag:nil contiguousEndTag:nil];
}

- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes
{
	return [self HTMLFromRange:range ignoringAttributes:defaultAttributes useTagsForTextMatchingAttributes:nil mergeContiguousStartTag:nil contiguousEndTag:nil];
}

// Instead of returning an HTML string representing the entire HTMLElement, this
// method meturns an NSDictionary with the opening tags, content and closing
// tags separately
- (NSDictionary *)HTMLElementAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes
{
	NSMutableArray *openingTags = [NSMutableArray array];
	NSMutableArray *closingTags = [NSMutableArray array];
	
	NSDictionary *attributes =
	[self attributesAtIndex:index
	  longestEffectiveRange:effectiveRange
					inRange:NSMakeRange(index, self.length - index)];
	
	BOOL shouldIgnoreAllAttributes =
	(attributes && [attributes isEqualToDictionary:defaultAttributes]);
	
	UIFont *defaultFont = defaultAttributes[NSFontAttributeName];
	
	if (!shouldIgnoreAllAttributes)
	{
		// Puts in tags for these special attributes
		if (tagsForAttributes)
		{
			for (NSDictionary *item in tagsForAttributes)
			{
				NSDictionary *specialAttributes = item[CSASpecialTagAttributesKey];
				NSString *specialOpeningTag = item[CSASpecialTagStartKey];
				NSString *specialClosingTag = item[CSASpecialTagEndKey];
				
				if (!specialAttributes || !specialOpeningTag || !specialClosingTag)
					continue;
				
				if ([self containsTextWithAttributes:specialAttributes inRange:*effectiveRange])
				{
					// if ([previousTags containsObject:item])
					// {
					//		// Remove
					// }
					
					[openingTags addObject:specialOpeningTag];
					[closingTags insertObject:specialClosingTag atIndex:0];
				}
			}
		}
		
		UIFont *effectiveFont = attributes[NSFontAttributeName];
		//		UIColor *color = attributes[NSForegroundColorAttributeName];
		BOOL isUnderlined = [attributes[NSUnderlineStyleAttributeName] boolValue];
		
		if (effectiveFont && ![effectiveFont isEqual:defaultFont])
		{
			NSString *lowercaseFontDescription = [[effectiveFont description] lowercaseString];
			
			if ([lowercaseFontDescription rangeOfString:@"font-weight: bold"].location != NSNotFound)
			{
				[openingTags addObject:@"<strong>"];
				[closingTags insertObject:@"</strong>" atIndex:0];
			}
			
			else if ([lowercaseFontDescription rangeOfString:@"font-style: italic"].location != NSNotFound)
			{
				[openingTags addObject:@"<em>"];
				[closingTags insertObject:@"</em>" atIndex:0];
			}
		}
		
		if (isUnderlined)
		{
			[openingTags addObject:@"<u>"];
			[closingTags insertObject:@"</u>" atIndex:0];
		}
	}

	return
	@{
   CSAHTMLElementContent : EscapeHTMLEntitiesAndReplaceNewlinesWithBR([self.string substringWithRange:*effectiveRange]),
   CSAHTMLElementStartTags : openingTags,
   CSAHTMLElementEndTags : closingTags
   };
	
}

- (NSString *)HTMLElementStringFromHTMLElementDictionary:(NSDictionary *)HTMLElement
{
	if (!HTMLElement)
		return @"";
	
	NSString *startTags = [HTMLElement[CSAHTMLElementStartTags] componentsJoinedByString:@""];
	NSString *content = HTMLElement[CSAHTMLElementContent];
	NSString *endTags = [HTMLElement[CSAHTMLElementEndTags] componentsJoinedByString:@""];
	
	if (!startTags)
		startTags = @"";
	
	if (!content)
		content = @"";
	
	if (!endTags)
		endTags = @"";
	
	return [NSString stringWithFormat:@"%@%@%@", startTags, content, endTags];
}

- (NSString *)HTMLAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes
{
	NSDictionary *HTMLElement =
	[self HTMLElementAtIndex:index longestEffectiveRange:effectiveRange
		  ignoringAttributes:defaultAttributes useTagsForTextMatchingAttributes:tagsForAttributes];

	return [self HTMLElementStringFromHTMLElementDictionary:HTMLElement];
}

- (NSString *)HTMLAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes
{
	return [self HTMLAtIndex:index longestEffectiveRange:effectiveRange ignoringAttributes:defaultAttributes useTagsForTextMatchingAttributes:nil];
}

#pragma mark -

// Check if the attributed string contains attributes that matches those specified in attributesToMatch at the index, returning the effective range in which this applies. We're not comparing by isEqualToDictionary:, as we expect to match with lesser number of attributes than the full set in attributesToMatch. Thus the lesser attributes you provide in attributesToMatch, the faster this comparison.
- (BOOL)containsAttributes:(NSDictionary *)attributesToMatch atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)effectiveRange seekLongestEffectiveRange:(BOOL)wantsLongest
{
	if (!attributesToMatch.count)
	{
		NSAssert(0, @"Can't determine containsAttributes:atIndex:effectiveRange:seekLongestEffectiveRange: with empty attributesToMatch");
		return NO;
	}
	
	NSDictionary *attributesAtIndex = nil;
	
	if (wantsLongest)
	{
		attributesAtIndex =
		[self attributesAtIndex:index
		  longestEffectiveRange:effectiveRange
						inRange:NSMakeRange(index, self.length - index)];
	}
	else
	{
		attributesAtIndex = [self attributesAtIndex:index effectiveRange:effectiveRange];
	}
	
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

- (BOOL)containsAttributes:(NSDictionary *)attributesToMatch atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)effectiveRange
{
	return [self containsAttributes:attributesToMatch atIndex:index effectiveRange:effectiveRange seekLongestEffectiveRange:NO];
}

- (BOOL)containsAttributes:(NSDictionary *)attributesToMatch atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange
{
	return [self containsAttributes:attributesToMatch atIndex:index effectiveRange:effectiveRange seekLongestEffectiveRange:YES];
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
