//
//  DrawView.m
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import "DrawView_InkEngineSetup.h"
#import <WILLCore/WILLCore.h>

@implementation DrawView_InkEngineSetup
{
    WCMRenderingContext * willContext;
    WCMLayer* viewLayer;
}

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initWillContext];
        [self refreshView];
    }
    return self;
}

- (void) initWillContext
{
    if (!willContext)
    {
        self.contentScaleFactor = [UIScreen mainScreen].scale;
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        EAGLContext* eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!eaglContext || ![EAGLContext setCurrentContext:eaglContext])
        {
            NSLog(@"Unable to create EAGLContext!");
            return;
        }
        
        willContext = [WCMRenderingContext contextWithEAGLContext:eaglContext];
        viewLayer = [willContext layerFromEAGLDrawable:(id<EAGLDrawable>)self.layer withScaleFactor:self.contentScaleFactor];
        
        [willContext setTarget:viewLayer];
        [willContext clearColor:[UIColor whiteColor]];
        
        float controlPoints[] = {10,300,10, 100,100,20, 300,250,40, 300,600,50};
        
        WCMStrokeRenderer * strokeRenderer = [willContext  strokeRendererWithSize:viewLayer.bounds.size andScaleFactor:viewLayer.scaleFactor];
        strokeRenderer.color = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0];
        strokeRenderer.brush = [willContext solidColorBrush];
        strokeRenderer.stride = 3;
        [strokeRenderer drawPoints:[[WCMFloatVectorPointer alloc] initWithBegin:controlPoints andEnd:controlPoints+12] finishStroke:YES];
        [strokeRenderer blendStrokeInLayer:viewLayer withBlendMode:WCMBlendModeNormal];
    }
}

-(void) refreshView
{
    [viewLayer present];
}

@end