//
//  NSAttributedString+AttributedStringToHTML.h
//  AttributedStringToHTML
//
//  Created by Lin Junjie on 15/2/13.
//  Copyright (c) 2013 Lin Junjie. All rights reserved.
//

#define CSAHTMLElementContent		@"CSAHTMLElementContent"
#define CSAHTMLElementStartTags		@"CSAHTMLElementStartTags"
#define CSAHTMLElementEndTags		@"CSAHTMLElementEndTags"

#define CSASpecialTagAttributesKey	@"CSASpecialTagAttributesKey"
#define CSASpecialTagStartKey		@"CSASpecialTagStartKey"
#define CSASpecialTagEndKey			@"CSASpecialTagEndKey"

#pragma mark - Dictionary Representation Keys

// Contains the plain text string of the attributed string
NSString * const CSAAttributedStringStringKey;

// Contains a dictionary of ranges-as-string as the keys, with the object being
// NSDictionary containing the keys below
NSString * const CSAAttributedStringRangesKey;

// An NSNumber object containing a BOOL indicating whether the text is bold
NSString * const CSAAttributedStringBoldKey;

// An NSNumber object containing a BOOL indicating whether the text is bold
NSString * const CSAAttributedStringUnderlineKey;

// An NSNumber object containing a BOOL indicating whether the text is italic
NSString * const CSAAttributedStringItalicKey;

//
// Provide a dictionary with the following keys to defaultAttrAndBIFonts when
// recreating an attributed string from attributedStringFromDictionary:
// defaultAttributesAndBIFonts:setAttributes:forKeys:
//

// Provide the default attributes to style the attributed string when they do
// not have special formatting
NSString * const CSAAttributedStringDefaultAttributes;

// Provide the corresponding UIFonts as objects to these keys to replace the
// UIFont in CSAAttributedStringDefaultAttributes when styling them as bold,
// italic, or both
NSString * const CSAAttributedStringBoldFont;
NSString * const CSAAttributedStringItalicFont;
NSString * const CSAAttributedStringBoldAndItalicFont;

typedef enum : NSUInteger {
	CSAAttributedStringFormattingNone		= 0,
	CSAAttributedStringFormattingBUI		= 1 << 0,
	CSAAttributedStringFormattingSpecial	= 1 << 1
} CSAAttributedStringFormatting;

#import <Foundation/Foundation.h>
#import "GTMNSString+HTML.h"

@interface NSAttributedString (AttributedStringToHTML)

/// Grabs the HTML for the range of attributed string. Pass in default attributes
/// with font, size, color so that attributes similar to the default attributes
/// will not be styled at all. Pass an array containing dictionaries with
/// CSASpecialTagAttributesKey and CSASpecialTagTagKey to mark text matching
/// attributes in CSASpecialTagAttributesKey with tag in CSASpecialTagTagKey.
/// Provide mergeStartTag and mergeEndTag to merge contiguous tags into one
- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes mergeContiguousStartTag:(NSString *)mergeStartTag contiguousEndTag:(NSString *)mergeEndTag;
- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes;
- (NSString *)HTMLFromRange:(NSRange)range ignoringAttributes:(NSDictionary *)defaultAttributes;


// Returns the HTML string representing the entire HTML Element (tags + content)
- (NSString *)HTMLAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes;
- (NSString *)HTMLAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes;


// Instead of returning an HTML string representing the entire HTMLElement, this
// method meturns an NSDictionary with the opening tags, content and closing
// tags separately
- (NSDictionary *)HTMLElementAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange ignoringAttributes:(NSDictionary *)defaultAttributes useTagsForTextMatchingAttributes:(NSArray *)tagsForAttributes;


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

#pragma mark - Attachments

/// Returns a dictionary of UASTextAttachment objects with their range in the
/// attributed string as keys
- (NSDictionary *)attachmentsWithRangeAsKey;

#pragma mark - 

//
// Creates a dictionary representation of attributed string, with keys:
//
// - CSAAttributedStringString (a plain text representation of the attributed string)
// - CSAAttributedStringRangeAttributes (contains keys that can recreate BUI
//   formatting. Also stores custom keys specified in customKeys for range of
//   string that matching attributes specified attributes
//
// - NSDictionary
//   - NSString (CSAAttributedStringStringKey)
//   - NSDictionary (CSAAttributedStringRangesKey) with NSRange as NSString as keys
//     - NSDictionary with keys:
//       - NSNumber (CSAAttributedStringBoldKey)
//       - NSNumber (CSAAttributedStringUnderlineKey)
//       - NSNumber (CSAAttributedStringItalicKey)
//       - NSString

//	CSAAttributedStringStringKey = "String contents";
//	CSAAttributedStringRangesKey =     {
//		"{0-5}" =         {
//			CSAAttributedStringBoldKey = 1;
//			CSAAttributedStringUnderlineKey = 0;
//			CustomKey = 1;
//		};
//	};
//
// String with attributes that are equivalent (by isEqualToDictionary:) to
// defaultAttributes will not be formatted in the dictionary representation
//
- (NSDictionary *)dictionaryRepresentationWithCustomKeys:(NSArray *)customKeys
										   forAttributes:(NSArray *)attributes
									  ignoringAttributes:(NSDictionary *)defaultAttributes;

//
// Returns an NSAttributedString, styled with attributes specified in
// CSAAttributedStringDefaultAttributes
//
+ (NSAttributedString *)attributedStringFromDictionary:(NSDictionary *)dictionary
						   defaultAttributesAndBIFonts:(NSDictionary *)defaultAttrAndBIFonts
										 setAttributes:(NSArray *)attributes
											   forKeys:(NSArray *)keys;

@end
