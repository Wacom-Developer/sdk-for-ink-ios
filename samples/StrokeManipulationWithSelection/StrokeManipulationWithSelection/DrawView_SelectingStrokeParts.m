//
//  DrawView.m
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import "DrawView_SelectingStrokeParts.h"
#import "Stroke.h"
#import <WILLCore/WILLCore.h>

@implementation DrawView_SelectingStrokeParts
{
    WCMRenderingContext * willContext;
    WCMLayer* viewLayer;
    WCMLayer* strokesLayer;
    
    WCMStrokeRenderer * strokeRenderer;
    
    WCMSpeedPathBuilder * pathBuilder;
    int pathStride;
    WCMStrokeBrush * pathBrush;
    WCMMultiChannelSmoothener * pathSmoothener;
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
            
            //When starting a new path, we must reset the smoothener state.
            [pathSmoothener reset];
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
        
        CGRect diryArea;
        if (wcmInputPhase == WCMInputPhaseEnd)
        {
            [strokeRenderer resetAndClearBuffers];
            [self removeSelectedByPath:pathAppendResult.wholePath];
            
            diryArea = strokeRenderer.strokeBounds;
        }
        else
        {
            [strokeRenderer drawPoints:pathAppendResult.addedPath finishStroke:NO];
            [strokeRenderer drawPreliminaryPoints:prelimPath];
            
            diryArea = strokeRenderer.updatedArea;
        }
        
        [self refreshViewInRect:diryArea];
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

-(void) removeSelectedByPath:(WCMFloatVectorPointer*)pts
{
    WCMIntersector* intersector = [[WCMIntersector alloc] init];
    [intersector setTargetAsClosedPathWithPoints:pts andPointsStride:pathStride];
    
    NSMutableArray * newStrokes = [NSMutableArray array];
    
    for (Stroke* s in strokes)
    {
        size_t intervalsCount;
        WCMPathInterval * intervals = [intersector intersectTargetWith:s.points.pointer
                                                andPointStride:s.stride
                                                      andWidth:s.width
                                                         andTs:s.ts andTf:s.tf
                                               andStrokeBounds:s.bounds
                                             andSegmentsBounds:s.segmentsBounds.begin
                                                        intervalsCount:&intervalsCount];
        
        //optimzation: When a single inteval, it covers the whole stroke.
        if (intervalsCount==1)
        {
            WCMPathInterval interval = intervals[0];
            if (!interval.isInside)
            {
                [newStrokes addObject:s];
            }
        }
        else
        {
            for (int i=0;i<intervalsCount;i++)
            {
                WCMPathInterval interval = intervals[i];
                if (!interval.isInside)
                {
                    Stroke * newStroke = [Stroke strokeFromStroke:s andInterval:interval];
                    [newStrokes addObject:newStroke];
                }
            }
        }
    }
    
    strokes = newStrokes;
    [self redrawStrokes];
}

- (void) redrawStrokes
{
    [willContext setTarget:strokesLayer];
    [willContext clearColor:[UIColor clearColor]];
    
    WCMStrokeRenderer * renderer = [willContext strokeRendererWithSize:viewLayer.bounds.size andScaleFactor:viewLayer.scaleFactor];
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