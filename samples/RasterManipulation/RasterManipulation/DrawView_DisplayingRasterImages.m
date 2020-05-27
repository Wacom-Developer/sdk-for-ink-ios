//
//  DrawView.m
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import "DrawView_DisplayingRasterImages.h"
#import <WILLCore/WILLCore.h>

@implementation DrawView_DisplayingRasterImages
{
    WCMRenderingContext * willContext;
    WCMLayer* viewLayer;
    WCMLayer* imageLayer;
    WCMLayer* strokesLayer;
    
    WCMStrokeRenderer * strokeRenderer;
    
    
    WCMSpeedPathBuilder * pathBuilder;
    int pathStride;
    WCMStrokeBrush * pathBrush;
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
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        EAGLContext* eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!eaglContext || ![EAGLContext setCurrentContext:eaglContext])
        {
            NSLog(@"Unable to create EAGLContext!");
            return;
        }
        
        willContext = [WCMRenderingContext contextWithEAGLContext:eaglContext];
        
        viewLayer = [willContext layerFromEAGLDrawable:(id<EAGLDrawable>)self.layer withScaleFactor:self.contentScaleFactor];
        
        strokesLayer = [willContext layerWithWidth:viewLayer.width andHeight:viewLayer.height andScaleFactor:viewLayer.scaleFactor andUseTextureStorage:YES];
        
        UIImage* img = [UIImage imageNamed:@"img.jpg"];
        imageLayer = [willContext layerWithWidth:img.size.width andHeight:img.size.height andScaleFactor:img.scale andUseTextureStorage:YES];
        [willContext setTarget:imageLayer];
        [willContext writePixelsInCurrentTargetFromUIImage:img];
        
        pathBrush = [willContext solidColorBrush];
        
        pathBuilder = [[WCMSpeedPathBuilder alloc] init];
        
        pathStride = [pathBuilder calculateStride];
        
        pathSmoothener = [[WCMMultiChannelSmoothener alloc] initWithChannelsCount:pathStride];
        
        strokeRenderer = [willContext strokeRendererWithSize:viewLayer.bounds.size andScaleFactor:viewLayer.scaleFactor];
        
        strokeRenderer.brush = pathBrush;
        strokeRenderer.stride = pathStride;
        strokeRenderer.width = 1.25;
        strokeRenderer.color = [UIColor blueColor];
    }
}

-(void) refreshViewInRect:(CGRect)rect
{
    [willContext setTarget:viewLayer andClipRect:rect];
    
    [willContext drawLayer:imageLayer withSourceRect:rect andDestinationRect:rect andBlendMode:WCMBlendModeOverride];
    
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
            
            //When starting a new path, we must reset the smoothener state.
            [pathSmoothener reset];
            
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
        WCMFloatVectorPointer * pointsSmoothed = [pathSmoothener smoothValues:points reachFinalValues:wcmInputPhase == WCMInputPhaseEnd];
        WCMPathAppendResult* pathAppendResult = [pathBuilder addPathPart:pointsSmoothed];
        
        WCMFloatVectorPointer * prelimPoints = [pathBuilder createPreliminaryPath];
        WCMFloatVectorPointer * smoothedPrelimPoints = [pathSmoothener smoothValues:prelimPoints reachFinalValues:YES];
        WCMFloatVectorPointer * prelimPath = [pathBuilder finishPreliminaryPath:smoothedPrelimPoints];
        
        [strokeRenderer drawPoints:pathAppendResult.addedPath finishStroke:NO];
        [strokeRenderer drawPreliminaryPoints:prelimPath];
        
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