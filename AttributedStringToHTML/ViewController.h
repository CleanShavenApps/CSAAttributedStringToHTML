//
//  ViewController.h
//  AttributedStringToHTML
//
//  Created by Lin Junjie on 15/2/13.
//  Copyright (c) 2013 Lin Junjie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *attributedTextView;
@property (weak, nonatomic) IBOutlet UITextView *HTMLOutputTextView;
- (IBAction)convertRichTextToHTML:(id)sender;

@end
