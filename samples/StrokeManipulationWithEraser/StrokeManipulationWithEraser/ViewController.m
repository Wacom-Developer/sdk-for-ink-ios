//
//  ViewController.m
//  StrokeManipulationWithEraser
//
//  Created by Plamen Petkov on 12/1/14.
//
//
#import "Stroke.h"

#import "ViewController.h"

#import "DrawView.h"
#import "DrawView_ErasingStrokes.h"
#import "DrawView_ErasingStrokeParts.h"

@interface ViewController ()

@end

@implementation ViewController
{
    NSArray* drawViewClasses;
    UIView<DrawView>* drawView;
}

- (IBAction) partButtonPressed:(id)sender
{
    UIButton * button = (UIButton*)sender;
    Class drawViewClass = drawViewClasses[button.tag];
    drawView = [[drawViewClass alloc] initWithFrame:self.view.frame];
    
    [self.view addSubview:drawView];
    _backButton.hidden = NO;
    [self.view bringSubviewToFront:_backButton];
    
    [self loadStrokes];
}

- (IBAction) back:(id)sender
{
    [drawView removeFromSuperview];
    _backButton.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    drawViewClasses = @[ [DrawView_ErasingStrokes class],
                         [DrawView_ErasingStrokeParts class]];
}

-(void) loadStrokes
{
    NSString *strokesFilePath = [[NSBundle mainBundle] pathForResource:@"strokes" ofType:@"will"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:strokesFilePath])
    {
        NSData * strokesData = [NSData dataWithContentsOfFile:strokesFilePath];
        NSMutableArray * strokes =  [self decodeStrokesFromWILLData:strokesData];
        
        drawView.strokes = strokes;
        [drawView redrawStrokes];
    }
}

- (NSMutableArray*) decodeStrokesFromWILLData:(NSData*)data
{
    WCMWILLFileFormatDecoder * willDecoder = [[WCMWILLFileFormatDecoder alloc] initWithData:data];
    WCMInkDecoder * decoder = [[WCMInkDecoder alloc] initWithData:willDecoder.inkData];
    
    WCMFloatVector* strokePoints;
    unsigned int strokeStride;
    float strokeWidth;
    UIColor* strokeColor;
    float strokeStartValue;
    float strokeFinishValue;
    WCMBlendMode blendMode;
    
    NSMutableArray * strokes = [[NSMutableArray alloc] init];
    
    while([decoder decodePathToPoints:&strokePoints
                            andStride:&strokeStride
                             andWidth:&strokeWidth
                             andColor:&strokeColor
                                andTs:&strokeStartValue
                                andTf:&strokeFinishValue
                         andBlendMode:&blendMode])
    {
        Stroke * stroke = [Stroke strokeWithPoints:strokePoints
                                         andStride:strokeStride
                                          andWidth:strokeWidth
                                          andColor:strokeColor
                                             andTs:strokeStartValue
                                             andTf:strokeFinishValue
                                      andBlendMode:blendMode];
        [strokes addObject:stroke];
    }
    
    return strokes;
}

@end
