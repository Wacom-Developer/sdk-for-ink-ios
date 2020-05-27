//
//  DrawView.m
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import "DrawView_BuildingPaths.h"
#import <WILLCore/WILLCore.h>

@implementation DrawView_BuildingPaths
{
    WCMRenderingContext * willContext;
    WCMLayer* viewLayer;
    
    WCMStrokeRenderer * strokeRenderer;
    
    WCMSpeedPathBuilder * pathBuilder;
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
        
        [self refreshViewInRect:viewLayer.bounds];
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
        
        pathBuilder = [[WCMSpeedPathBuilder alloc] init];
        [pathBuilder setNormalizationConfigWithMinValue:0 andMaxValue:7000];
        [pathBuilder setPropertyConfigWithName:WCMPropertyNameWidth andMinValue:2 andMaxValue:15 andInitialValue:NAN andFinalValue:NAN andFunction:WCMPropertyFunctionPower andParameter:1 andFlip:NO];
        
        strokeRenderer = [willContext strokeRendererWithSize:viewLayer.bounds.size andScaleFactor:viewLayer.scaleFactor];
        
        strokeRenderer.brush = [willContext solidColorBrush];
        strokeRenderer.stride = [pathBuilder calculateStride];
        strokeRenderer.color = [UIColor blackColor];
    }
}

-(void) refreshViewInRect:(CGRect)rect
{
    [willContext setTarget:viewLayer andClipRect:rect];
    [willContext clearColor:[UIColor whiteColor]];
    
    [strokeRenderer blendStrokeUpdatedAreaInLayer:viewLayer withBlendMode:WCMBlendModeNormal];
    
    [viewLayer present];
}

- (void) processTouches:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    
    if (touch.phase != UITouchPhaseStationary)
    {
        CGPoint location = [touch locationInView:self];
        WCMInputPhase wcmInputPhase;
        
        if (touch.phase == UITouchPhaseBegan)
        {
            wcmInputPhase = WCMInputPhaseBegin;
        }
        else if (touch.phase == UITouchPhaseMoved)
        {
            wcmInputPhase = WCMInputPhaseMove;
        }
        else if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled)
        {
            wcmInputPhase = WCMInputPhaseEnd;
        }
        
        WCMFloatVectorPointer * points = [pathBuilder addPointWithPhase:wcmInputPhase andX:location.x andY:location.y andTimestamp:touch.timestamp];
        WCMPathAppendResult* pathAppendResult = [pathBuilder addPathPart:points];
        
        [strokeRenderer drawPoints:pathAppendResult.addedPath finishStroke:wcmInputPhase == WCMInputPhaseEnd];
        
        [self refreshViewInRect:strokeRenderer.updatedArea];
    }
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouches:touches withEvent:event];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouches:touches withEvent:event];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouches:touches withEvent:event];
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouches:touches withEvent:event];
}

@end