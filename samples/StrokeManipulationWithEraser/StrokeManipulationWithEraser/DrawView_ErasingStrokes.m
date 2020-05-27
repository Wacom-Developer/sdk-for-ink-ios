//
//  DrawView.m
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import "DrawView_ErasingStrokes.h"
#import "Stroke.h"
#import <WILLCore/WILLCore.h>

@implementation DrawView_ErasingStrokes
{
    WCMRenderingContext * willContext;
    WCMLayer* viewLayer;
    WCMLayer* strokesLayer;
    
    WCMSpeedPathBuilder * pathBuilder;
    int pathStride;
    WCMStrokeBrush * pathBrush;
}

@synthesize strokes=strokes;

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
        
        [willContext clearColor:[UIColor clearColor]];
        
        [self refreshViewInRect:viewLayer.bounds];
        
        strokes = [NSMutableArray array];
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
        
        pathBrush = [willContext solidColorBrush];
        
        pathBuilder = [[WCMSpeedPathBuilder alloc] init];
        [pathBuilder setNormalizationConfigWithMinValue:0 andMaxValue:7000];
        [pathBuilder setPropertyConfigWithName:WCMPropertyNameWidth andMinValue:50 andMaxValue:50 andInitialValue:NAN andFinalValue:NAN andFunction:WCMPropertyFunctionPower andParameter:1 andFlip:NO];
        
        pathStride = [pathBuilder calculateStride];
    }
}

-(void) refreshViewInRect:(CGRect)rect
{
    [willContext setTarget:viewLayer andClipRect:rect];
    [willContext clearColor:[UIColor whiteColor]];
    
    [willContext drawLayer:strokesLayer withSourceRect:rect andDestinationRect:rect andBlendMode:WCMBlendModeNormal];
    
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
        
        [self erase:pathAppendResult.addedPath];
        
        [self refreshViewInRect:viewLayer.bounds];
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

-(void) erase:(WCMFloatVectorPointer*)pts
{
    WCMIntersector* intersector = [[WCMIntersector alloc] init];
    [intersector setTargetAsStrokeWithPoints:pts andPointsStride:pathStride andWidth:NAN];
    
    NSMutableArray * newStrokes = [NSMutableArray array];
    
    for (Stroke* s in strokes)
    {
        BOOL intersects = [intersector isIntersectingTarget:s.points.pointer
                                             andPointStride:s.stride
                                                   andWidth:s.width
                                                      andTs:s.ts andTf:s.tf
                                            andStrokeBounds:s.bounds
                                          andSegmentsBounds:s.segmentsBounds.begin];
        
        if (!intersects)
        {
            [newStrokes addObject:s];
        }
    }
    
    strokes = newStrokes;
    [self redrawStrokes];
}

- (void) redrawStrokes
{
    [willContext setTarget:strokesLayer];
    [willContext clearColor:[UIColor clearColor]];
    
    WCMStrokeRenderer * renderer = [willContext strokeRendererWithSize:viewLayer.bounds.size andScaleFactor:viewLayer.scaleFactor ];
    renderer.brush = pathBrush;
    
    for (Stroke * s in strokes)
    {
        renderer.stride = s.stride;
        renderer.width = s.width;
        renderer.color = s.color;
        renderer.ts = s.ts;
        renderer.tf = s.tf;
        
        [renderer resetAndClearBuffers];
        [renderer drawPoints:s.points.pointer finishStroke:YES];
        [renderer blendStrokeInLayer:strokesLayer withBlendMode:s.blendMode];
    }
    
    [self refreshViewInRect:viewLayer.bounds];
}

@end