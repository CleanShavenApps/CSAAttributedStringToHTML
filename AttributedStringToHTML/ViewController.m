//
//  ViewController.m
//  AttributedStringToHTML
//
//  Created by Lin Junjie on 15/2/13.
//  Copyright (c) 2013 Lin Junjie. All rights reserved.
//

#import "ViewController.h"
#import "NSAttributedString+AttributedStringToHTML.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)convertRichTextToHTML:(id)sender {
	self.HTMLOutputTextView.text =
	[self.attributedTextView.attributedText HTMLFromRange:
	 NSMakeRange(0, self.attributedTextView.attributedText.length)
									   ignoringAttributes:
	 self.attributedTextView.typingAttributes];
}
@end
