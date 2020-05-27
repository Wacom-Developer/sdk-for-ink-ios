//
//  DrawView.m
//  DrawingWithTouch
//
//  Created by Plamen Petkov on 9/30/14.
//
//

#import "DrawView.h"
#import "Stroke.h"
#import <WILLCore/WILLCore.h>

@implementation DrawView
{
    WCMRenderingContext * willContext;
    WCMLayer* viewLayer;
    WCMLayer* strokesLayer;
    
    WCMSpeedPathBuilder * pathBuilder;
    int pathStride;
    WCMStrokeBrush * pathBrush;
    WCMMultiChannelSmoothener * pathSmoothener;
    
    NSMutableArray * strokes;
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
        
        [willContext clearColor:[UIColor clearColor]];
        
        [self refreshView];
        
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
        
        pathBrush = [WCMStrokeBrush solidColorBrush];
        
        pathBuilder = [[WCMSpeedPathBuilder alloc] init];
        
        pathStride = [pathBuilder calculateStride];
        
        pathSmoothener = [[WCMMultiChannelSmoothener alloc] initWithChannelsCount:pathStride];
        
        [self refreshView];
    }
}

-(void) refreshView
{
    [willContext setTarget:viewLayer];
    
    [willContext clearColor:[UIColor whiteColor]];
    [willContext drawLayer:strokesLayer];
    
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
        
        if (wcmInputPhase == WCMInputPhaseEnd)
        {
            [self selectedByPath:pathAppendResult.wholePath];
        }
        else
        {
            BOOL isBegginig = pathAppendResult.addedPartStartingIndex == 0;
            BOOL isEnding = wcmInputPhase == WCMInputPhaseEnd;
            [willContext setTarget:strokesLayer];
            [willContext drawStrokeWithBrush:pathBrush
                   andControlPointsBeginning:pathAppendResult.wholePath.begin + pathAppendResult.addedPartStartingIndex
                               andBufferSize:pathAppendResult.addedSize
                                   andStride:pathStride
                                    andWidth:1.5
                                    andColor:[UIColor blueColor]
                        andRoundCapBeginning:isBegginig
                           andRoundCapEnding:isEnding];
        }
        
        [self refreshView];
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

-(void) selectedByPath:(WCMFloatVectorPointer*)pts
{
    WCMIntersector* intersector = [[WCMIntersector alloc] init];
    [intersector setTargetAsClosedPathWithPoints:pts andPointsStride:pathStride];
    
    for (Stroke* s in strokes)
    {
        BOOL intersected = [intersector isIntersectingTarget:s.points.pointer
                                                andPointStride:s.stride
                                                      andWidth:s.width
                                                         andTs:s.ts andTf:s.tf
                                               andStrokeBounds:s.bounds
                                             andSegmentsBounds:s.segmentsBoundsPointer];
        
        s.color = intersected ? [UIColor greenColor] : [UIColor blackColor];
    }
    
    [self drawStrokes];
}

- (void) drawStrokes
{
    [willContext setTarget:strokesLayer];
    [willContext clearColor:[UIColor whiteColor]];
    
    for (Stroke * s in strokes)
    {
        [willContext drawStrokeWithBrush:pathBrush
               andControlPointsBeginning:s.points.begin
                           andBufferSize:s.points.size
                               andStride:s.stride
                                andWidth:s.width
                                andColor:s.color
                    andRoundCapBeginning:YES andRoundCapEnding:YES
                                   andTs:s.ts
                                   andTf:s.tf
                            andLastParticle:NULL andRandomSeed:NULL];
    }
    
    [self refreshView];
}

- (void) decodeStrokesFromNSData:(NSData*)data
{
    WCMInkDecoder * decoder = [[WCMInkDecoder alloc] initWithData:data];
    
    WCMFloatVector* strokePoints;
    unsigned int strokeStride;
    float strokeWidth;
    UIColor* strokeColor;
    float strokeStartValue;
    float strokeFinishValue;
    
    [strokes removeAllObjects];
    while([decoder decodePathToPoints:&strokePoints andStride:&strokeStride
                             andWidth:&strokeWidth andColor:&strokeColor
                                andTs:&strokeStartValue andTf:&strokeFinishValue])
    {
        Stroke * stroke = [Stroke strokeWithPoints:strokePoints
                                         andStride:strokeStride
                                          andWidth:strokeWidth
                                          andColor:strokeColor
                                             andTs:strokeStartValue
                                             andTf:strokeFinishValue];
        [strokes addObject:stroke];
    }
    
    [self drawStrokes];
}

@end