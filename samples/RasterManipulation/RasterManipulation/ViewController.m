//
//  ViewController.m
//  RasterManipulation
//
//  Created by Plamen Petkov on 12/3/14.
//
//

#import "ViewController.h"

#import "DrawView_DisplayingRasterImages.h"
#import "DrawView_ImageMasking.h"

@implementation ViewController
{
    NSArray* drawViewClasses;
    UIView* drawView;
}

- (IBAction) partButtonPressed:(id)sender
{
    UIButton * button = (UIButton*)sender;
    Class drawViewClass = drawViewClasses[button.tag];
    drawView = [[drawViewClass alloc] initWithFrame:self.view.frame];
    
    [self.view addSubview:drawView];
    _backButton.hidden = NO;
    [self.view bringSubviewToFront:_backButton];
}

- (IBAction) back:(id)sender
{
    [drawView removeFromSuperview];
    _backButton.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    drawViewClasses = @[ [DrawView_DisplayingRasterImages class],
                         [DrawView_ImageMasking class]];
}

@end
