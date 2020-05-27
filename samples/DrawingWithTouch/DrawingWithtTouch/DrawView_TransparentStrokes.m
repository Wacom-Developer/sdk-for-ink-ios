//
//  DrawView.m
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import "DrawView_TransparentStrokes.h"
#import <WILLCore/WILLCore.h>

@implementation DrawView_TransparentStrokes
{
    WCMRenderingContext * willContext;
    WCMLayer* viewLayer;
    WCMLayer * strokesLayer;
    
    WCMStrokeRenderer * strokeRenderer;
    
    WCMSpeedPathBuilder * pathBuilder;
    
    WCMMultiChannelSmoothener * pathSmoothener;
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
        
        [willContext setTarget:strokesLayer];
        [willContext clearColor:[UIColor clearColor]];
        
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
        
        strokesLayer = [willContext layerWithWidth:viewLayer.bounds.size.width andHeight:viewLayer.bounds.size.height andScaleFactor:viewLayer.scaleFactor andUseTextureStorage:YES];
        
        pathBuilder = [[WCMSpeedPathBuilder alloc] init];
        [pathBuilder setNormalizationConfigWithMinValue:0 andMaxValue:7000];
        [pathBuilder setPropertyConfigWithName:WCMPropertyNameWidth andMinValue:2 andMaxValue:15 andInitialValue:NAN andFinalValue:NAN andFunction:WCMPropertyFunctionPower andParameter:1 andFlip:NO];
        
        int pathStride = [pathBuilder calculateStride];
        
        pathSmoothener = [[WCMMultiChannelSmoothener alloc] initWithChannelsCount:pathStride];
        
        strokeRenderer =  [willContext strokeRendererWithSize:viewLayer.bounds.size andScaleFactor:viewLayer.scaleFactor];
        
        strokeRenderer.brush = [willContext solidColorBrush];
        strokeRenderer.stride = pathStride;
        strokeRenderer.color = [UIColor blackColor];
    }
}

-(void) refreshViewInRect:(CGRect)rect
{
    [willContext setTarget:viewLayer andClipRect:rect];
    [willContext clearColor:[UIColor whiteColor]];
    
    [willContext drawLayer:strokesLayer withSourceRect:rect andDestinationRect:rect andBlendMode:WCMBlendModeNormal];
    
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
            
            [pathSmoothener reset];
            
            strokeRenderer.color = [UIColor colorWithRed:(float)rand()/RAND_MAX green:(float)rand()/RAND_MAX blue:(float)rand()/RAND_MAX alpha:0.5];
            [strokeRenderer resetAndClearBuffers];
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
        WCMFloatVectorPointer * smoothedPoints = [pathSmoothener smoothValues:points reachFinalValues:wcmInputPhase == WCMInputPhaseEnd];
        WCMPathAppendResult* pathAppendResult = [pathBuilder addPathPart:smoothedPoints];
        
        [strokeRenderer drawPoints:pathAppendResult.addedPath finishStroke:wcmInputPhase == WCMInputPhaseEnd];
        
        if (wcmInputPhase == WCMInputPhaseEnd)
        {
            [strokeRenderer blendStrokeInLayer:strokesLayer withBlendMode:WCMBlendModeNormal];
        }
        
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