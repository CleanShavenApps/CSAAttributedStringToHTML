//
//  NSAttributedString+AttributedStringToHTML.m
//  AttributedStringToHTML
//
//  Created by Lin Junjie on 15/2/13.
//  Copyright (c) 2013 Lin Junjie. All rights reserved.
//

#import "NSAttributedString+AttributedStringToHTML.h"
#import "UASTextAttachment.h"

NSString * const CSAAttributedStringStringKey = @"CSAAttributedStringStringKey";
NSString * const CSAAttributedStringRangesKey = @"CSAAttributedStringRangesKey";
NSString * const CSAAttributedStringBoldKey = @"CSAAttributedStringBoldKey";
NSString * const CSAAttributedStringUnderlineKey = @"CSAAttributedStringUnderlineKey";
NSString * const CSAAttributedStringItalicKey = @"CSAAttributedStringItalicKey";
NSString * const CSAAttributedStringDefaultAttributes = @"CSAAttributedStringDefaultAttributes";
NSString * const CSAAttributedStringBoldFont = @"CSAAttributedStringBoldFont";
NSString * const CSAAttributedStringItalicFont = @"CSAAttributedStringItalicFont";
NSString * const CSAAttributedStringBoldAndItalicFont = @"CSAAttributedStringBoldAndItalicFont";
NSString * const CSAAttributedStringAttachment = @"CSAAttributedStringAttachment";

@implementation NSAttributedString (AttributedStringToHTML)

NSString *EscapeHTMLEntitiesAndReplaceNewlinesWithBR(NSString* string)
{
	NSString *plainTextEscapedForHTML =
	[string gtm_stringByEscapingForHTMLEmails];
	
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

/// Grabs the HTML for the range of attributed string. Pass in default attributes
/// with font, size, color so that attributes similar to the default attributes
/// will not be styled at all. Pass an array containing dictionaries with
/// CSASpecialTagAttributesKey and CSASpecialTagTagKey to mark text matching
/// attributes in CSASpecialTagAttributesKey with tag in CSASpecialTagTagKey.
/// Provide mergeStartTag and mergeEndTag to merge contiguous tags into one
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

- (void)getIsBold:(BOOL *)isBold isItalic:(BOOL *)isItalic forFont:(UIFont *)font
{
	NSString *lowercaseFontDescription = [[font description] lowercaseString];

	if (isBold != NULL)
	{
		*isBold =
		[lowercaseFontDescription rangeOfString:@"font-weight: bold"].location != NSNotFound;
	}
	
	if (isItalic != NULL)
	{
		*isItalic =
		[lowercaseFontDescription rangeOfString:@"font-style: italic"].location != NSNotFound;
	}	
}

// Instead of returning an HTML string representing the entire HTMLElement, this
// method meturns an NSDictionary with the opening tags, content and closing
// tags separately
- (NSDictionary *)HTMLElementAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes
{
	// Crash proof this when dealing with empty text
	if (index >= self.length)
		return nil;
	
	NSMutableArray *openingTags = [NSMutableArray array];
	NSMutableArray *closingTags = [NSMutableArray array];
	
	NSDictionary *attributes =
	[self attributesAtIndex:index
	  longestEffectiveRange:effectiveRange
					inRange:NSMakeRange(index, self.length - index)];

	NSString *content = EscapeHTMLEntitiesAndReplaceNewlinesWithBR([self.string substringWithRange:*effectiveRange]);
	
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
			BOOL isBold = NO;
			BOOL isItalic = NO;
			
			[self getIsBold:&isBold isItalic:&isItalic forFont:effectiveFont];
			
			if (isBold)
			{
				[openingTags addObject:@"<strong>"];
				[closingTags insertObject:@"</strong>" atIndex:0];
			}
			
			if (isItalic)
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
		
		UASTextAttachment *attachment = attributes[NSAttachmentAttributeName];
		
		if (attachment)
		{

			// Used to locate NSTextAttachemnt in the attributed string and to
			// replace with an empty string so it doesn't appear in HTML
			unichar attachmentChar = NSAttachmentCharacter;
			NSString *attachmentString =
			[NSString stringWithCharacters:&attachmentChar length:1];
			
			// Replace the attachment character
			content =
			[content stringByReplacingOccurrencesOfString:attachmentString
											   withString:@""];


			if (![attachment isKindOfClass:[UASTextAttachment class]])
			{
				NSAssert(0, @"Found an attachment that is not an UASAttachment: %@", attachment);
			}
			
			else if (!attachment.originalImageFromImagePicker)
			{
				DDLogError(@"Found an attachment without original image (possibly deleted from photos, or denied access to photo library");
			}
			
			else
			{
				NSString *imgTag =
				[NSString stringWithFormat:@"<img src='cid:%@' id='%@'>",
				 attachment.contentID,
				 attachment.contentID];
				
				
				if (content.length)
				{
					content = [content stringByAppendingString:imgTag];
				}
				else
				{
					content = imgTag;
				}
			}
			
		}
	}

	return
	@{
   CSAHTMLElementContent : content,
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

- (BOOL)_containsAttributes:(NSDictionary *)attributesToMatch inAttributes:(NSDictionary *)attributesAtIndex
{
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

// Check if the attributed string contains attributes that matches those specified in attributesToMatch at the index, returning the effective range in which this applies. We're not comparing by isEqualToDictionary:, as we expect to match with lesser number of attributes than the full set in attributesToMatch. Thus the lesser attributes you provide in attributesToMatch, the faster this comparison.
- (BOOL)containsAttributes:(NSDictionary *)attributesToMatch atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)effectiveRange seekLongestEffectiveRange:(BOOL)wantsLongest
{
	if (!attributesToMatch.count)
	{
		NSAssert(0, @"Can't determine containsAttributes:atIndex:effectiveRange:seekLongestEffectiveRange: with empty attributesToMatch");
		return NO;
	}

	// Crash proof this when dealing with empty text
	if (index >= self.length)
		return NO;
	
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

	return [self _containsAttributes:attributesToMatch inAttributes:attributesAtIndex];
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

#pragma mark - Attachments

/// Returns a dictionary of UASTextAttachment objects with their range in the
/// attributed string as keys
- (NSDictionary *)attachmentsWithRangeAsKey
{
	NSMutableDictionary *attachmentsDict =
	[NSMutableDictionary dictionary];
	
	[self enumerateAttribute:NSAttachmentAttributeName
					 inRange:NSMakeRange(0, self.length)
					 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
				  usingBlock:^(id value, NSRange range, BOOL *stop)
	 {
		 if ([value isKindOfClass:[UASTextAttachment class]])
		 {
			 UASTextAttachment *attachment = value;
			 
			 if (attachment.originalImageFromImagePicker != nil)
			 {
				 attachmentsDict[NSStringFromRange(range)] = value;
			 }
		 }
	 }];
	
	return [NSDictionary dictionaryWithDictionary:attachmentsDict];
}

#pragma mark - Dictionary Representation

- (NSDictionary *)formattingDictionaryFromAttributes:(NSDictionary *)attributes
									  withCustomKeys:(NSArray *)customKeys
								  matchingAttributes:(NSArray *)customAttributes
{
	if (customKeys.count != customAttributes.count)
	{
		NSAssert(0, @"Need same number of keys (%d) and attributes (%d)",
				 customKeys.count, customAttributes.count);
		return nil;
	}
	
	NSUInteger numberOfCustomKeys = customKeys.count;
	
	NSMutableDictionary *dictionary =
	[NSMutableDictionary dictionaryWithCapacity:numberOfCustomKeys + 1];
	
	for (NSUInteger idx = 0; idx < numberOfCustomKeys; idx++)
	{
		NSDictionary *customAttribute = customAttributes[idx];
		
		if ([self _containsAttributes:customAttribute inAttributes:attributes])
		{
			NSString *customKey = customKeys[idx];
			dictionary[customKey] = @YES;
		}
	}
	
	// Add BUI
	BOOL isUnderlined = [attributes[NSUnderlineStyleAttributeName] boolValue];
	
	UIFont *effectiveFont = attributes[NSFontAttributeName];
	BOOL isBold = NO;
	BOOL isItalic = NO;
	
	[self getIsBold:&isBold isItalic:&isItalic forFont:effectiveFont];
	
	if (isBold)
		dictionary[CSAAttributedStringBoldKey] = @YES;
	
	if (isItalic)
		dictionary[CSAAttributedStringItalicKey] = @YES;
	
	if (isUnderlined)
		dictionary[CSAAttributedStringUnderlineKey] = @(NSUnderlineStyleSingle);
	
	UASTextAttachment *attachment = attributes[NSAttachmentAttributeName];
	
	if (attachment &&
		attachment.originalImageFromImagePicker &&
		attachment.originalMediaInfoFromImagePicker[UIImagePickerControllerReferenceURL])
	{
		dictionary[CSAAttributedStringAttachment] =
		attachment.originalMediaInfoFromImagePicker[UIImagePickerControllerReferenceURL];
	}
	
	return dictionary;
}

- (NSDictionary *)dictionaryRepresentationWithCustomKeys:(NSArray *)customKeys
										   forAttributes:(NSArray *)attributes
									  ignoringAttributes:(NSDictionary *)defaultAttributes
{
	if (customKeys.count != attributes.count)
	{
		NSAssert(0, @"Need same number of keys (%d) and attributes (%d)",
				 customKeys.count, attributes.count);
		return nil;
	}
	
	NSMutableDictionary *representation = [NSMutableDictionary dictionaryWithCapacity:2];
	representation[CSAAttributedStringStringKey] = self.string;
	
	NSMutableDictionary *rangeAttributesDictionary = [NSMutableDictionary dictionary];
	
	[self enumerateAttributesInRange:NSMakeRange(0, self.length)
							 options:0
						  usingBlock:
	 ^(NSDictionary *attrs, NSRange range, BOOL *stop) {
		 
		 @autoreleasepool {
			 BOOL shouldIgnoreAllAttributes =
			 (attrs && defaultAttributes && [attrs isEqualToDictionary:defaultAttributes]);
			 
			 if (!shouldIgnoreAllAttributes)
			 {
				 NSString *rangeString = NSStringFromRange(range);
				 
				 if (rangeString)
				 {
					 NSDictionary *formattingDictionary =
					 [self formattingDictionaryFromAttributes:attrs
											   withCustomKeys:customKeys
										   matchingAttributes:attributes];
					 
					 if (formattingDictionary.count)
						 rangeAttributesDictionary[rangeString] = formattingDictionary;
				 }
			 }
		 }
		 
	 }];
	
	representation[CSAAttributedStringRangesKey] = rangeAttributesDictionary;
	return representation;
}

//
// Returns an NSAttributedString, styled with attributes specified in
// CSAAttributedStringDefaultAttributes
//
+ (NSAttributedString *)attributedStringFromDictionary:(NSDictionary *)dictionary
						   defaultAttributesAndBIFonts:(NSDictionary *)defaultAttrAndBIFonts
										 setAttributes:(NSArray *)customAttributes
											   forKeys:(NSArray *)customKeys
{
	if (!dictionary)
		return nil;
	
	if (customKeys.count != customAttributes.count)
	{
		NSAssert(0, @"Need same number of keys (%d) and attributes (%d)",
				 customKeys.count, customAttributes.count);
		return nil;
	}

	NSString *string = dictionary[CSAAttributedStringStringKey];
	if (!string)
		return nil;

	NSDictionary *defaultAttributes =
	defaultAttrAndBIFonts[CSAAttributedStringDefaultAttributes];
	
	if (!defaultAttributes)
	{
		NSAssert(0, @"Need default attributes at CSAAttributedStringDefaultAttributes");
		return nil;
	}
	
	UIFont *boldFont = defaultAttrAndBIFonts[CSAAttributedStringBoldFont];
	UIFont *italicFont = defaultAttrAndBIFonts[CSAAttributedStringItalicFont];
	UIFont *boldAndItalicFont = defaultAttrAndBIFonts[CSAAttributedStringBoldAndItalicFont];
	
	if (!boldFont || !italicFont || !boldAndItalicFont)
	{
		NSAssert(0, @"Missing CSAAttributedStringBoldFont, CSAAttributedStringItalicFont or CSAAttributedStringBoldAndItalicFont");
		return nil;
	}
	
	///
	NSMutableAttributedString *attributedString =
	[[NSMutableAttributedString alloc] initWithString:string attributes:defaultAttributes];

	NSDictionary *rangeAttributesDictionary = dictionary[CSAAttributedStringRangesKey];
	[rangeAttributesDictionary enumerateKeysAndObjectsUsingBlock:
	 ^(NSString *rangeKey, NSDictionary *attributes, BOOL *stop) {
		 
		 @autoreleasepool {
			 
			 if (attributes.count)
			 {
				 NSRange range = NSRangeFromString(rangeKey);
				 
				 if (range.length)
				 {
					 BOOL didUseCustomAttribute = NO;
					 
					 // Look for custom attributes to set
					 NSUInteger idx = 0;
					 for (NSString *customKey in customKeys)
					 {
						 if (attributes[customKey])
						 {
							 NSDictionary *customAttr = customAttributes[idx];
							 if (customAttr)
							 {
								 [attributedString setAttributes:customAttr range:range];
								 didUseCustomAttribute = YES;
								 break;
							 }
						 }
						 idx++;
					 }
					 
					 // Otherwise set default attributes
					 if (!didUseCustomAttribute)
						 [attributedString setAttributes:defaultAttributes range:range];
					 
					 
					 // BUI formatting
					 BOOL isBold = [attributes[CSAAttributedStringBoldKey] boolValue];
					 BOOL isItalic = [attributes[CSAAttributedStringItalicKey] boolValue];
					 NSNumber *underline = attributes[CSAAttributedStringUnderlineKey];
					 
					 if (isBold && isItalic)
						 [attributedString addAttribute:NSFontAttributeName value:boldAndItalicFont range:range];
					 else if (isBold)
						 [attributedString addAttribute:NSFontAttributeName value:boldFont range:range];
					 else if (isItalic)
						 [attributedString addAttribute:NSFontAttributeName value:italicFont range:range];
					 
					 if (underline)
						 [attributedString addAttribute:NSUnderlineStyleAttributeName value:underline range:range];
					 
				 }
			 }
			 
		 }
	 }];
	
	return attributedString;
}


@end
