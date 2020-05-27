//
//  ViewController.m
//  DrawingWithtTouch
//
//  Created by Plamen Petkov on 11/28/14.
//
//

#import "ViewController.h"

#import "DrawView_InkEngineSetup.h"
#import "DrawView_BuildingPaths.h"
#import "DrawView_Smoothing.h"
#import "DrawView_TransparentStrokes.h"
#import "DrawView_PreliminaryPath.h"
#import "DrawView_GenerateBezierPath.h"
#import "DrawView_ParticleBrush.h"

@interface ViewController ()

@end


@implementation ViewController
{
    NSArray* drawViewClasses;
    UIView * drawView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    drawViewClasses = @[ [DrawView_InkEngineSetup class],
                         [DrawView_BuildingPaths class],
                         [DrawView_Smoothing class],
                         [DrawView_TransparentStrokes class],
                         [DrawView_PreliminaryPath class],
                         [DrawView_ParticleBrush class],
                         [DrawView_GenerateBezierPath class]
                         ];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
