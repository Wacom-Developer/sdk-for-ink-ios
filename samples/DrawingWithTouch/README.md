# Tutorial 1: Drawing with touch

In this tutorial, you will use WILL SDK for ink to draw strokes produced by the user's touch input. 
The tutorial is divided into the following parts: 

* [Part 1: Setting up the ink engine](#part-1-setting-up-the-ink-engine)
* [Part 2: Building paths from touch input](#part-2-building-paths-from-touch-input)
* [Part 3: Smoothing paths](#part-3-smoothing-paths)
* [Part 4: Drawing semi-transparent strokes](#part-4-drawing-semi-transparent-strokes)
* [Part 5: Drawing preliminary paths](#part-5-drawing-preliminary-paths)
* [Part 6: Using a particle brush](#part-6-using-a-particle-brush)
* [Part 7: Generating a Bezier path](#part-7-generating-a-bezier-path)

Each part builds on the previous part, extending and improving the functionality.

## Prerequisites

You will need WILL SDK for ink to complete this tutorial. For more information see Getting started with WILL SDK for ink for iOS.

## Source code
You can find the sample project in the following location:
```Xcode: /ios/Samples/DrawingWithTouch```

---
---
## Part 1: Setting up the ink engine

WILL SDK for ink provides a 2D drawing engine that focuses primarily on inking. 
It relies on OpenGL 2.0 and acts as a wrapper on the ```EAGLContext``` object.

You can use WILL SDK for ink for both onscreen and offscreen rendering. 
When you draw to an instance of the ```UIView``` class added to the screen, you perform an onscreen rendering. 
Alternatively, you can render in a texture that does not display on the screen. 
Instead, you can read the pixels of the texture and create a ```UIImage``` object from it. 
You can also do this in a thread that is not the main thread.

The most important class is the ```WCMRenderingContext```.


In Part 1 of this tutorial, you will set up a rendering environment and draw a stroke on the screen in an instance of the ```UIView``` class.

### Step 1: Create a view to hold strokes

Create a subclass of the ```UIView``` class. 
The view must be backed by a ```CAEAGLLayer``` object to integrate it with the ```WCMRenderingContext```.

```objective-c
@interface DrawView : UIView
@end
```

```objective-c
@implementation DrawView
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
    if (self) {
        [self initWillContext];
        [self refreshView];
    }
    return self;
}
@end
```

Create the ```EAGLContext``` and configure the ```CAEAGLLayer``` in a method invoked from the ```initWithFrame:```.

Set the value of ```eaglLayer.opaque = YES;```. This setting means that the view will be opaque. You can create a transparent view by setting it to ```NO```, but doing so has a slight negative effect on performance.

Set the value of ```kEAGLDrawablePropertyRetainedBacking``` to ```YES```. This setting means that you want to retain the content of the layer’s render buffer between frames. With this, you can re-render only those screen areas that are modified.

The ```kEAGLDrawablePropertyColorFormat``` parameter specifies the color format of the view’s layer.

The ```EAGLContext``` is created using the ```kEAGLRenderingAPIOpenGLES2``` constant because this is the minimum requirement of the OpenGL version needed by WILL SDK for ink.

For more information on the ```EAGLContext``` configuration, see the iOS documentation.

### Step 2: Create a rendering context to draw strokes to the view

After you have created the ```EAGLContext```, use it to create an instance of the ```WCMRenderingContext``` class.

Use the view's layer to create an instance of the ```WCMLayer``` class.

Set the layer scale factor to be the contentScaleFactor of the view. This setting means that you render in the layer that measures the coordinate space of the view using points rather than pixels. The setting also means that the layer will have the necessary number of pixels.

The ```WCMLayer``` is now associated with the ```UIView```. All drawings to that layer will be displayed in the ```WCMLayer```.

```objective-c
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
    }
}
```

### Step 3: Create a method to refresh the screen contents

Create a ```refreshView:``` method that calls the ```[viewLayer present]```. This call displays the content in the ```viewLayer``` on the screen.

```
-(void) refreshView
{
    [viewLayer present];
}
```

### Step 4: Draw a static stroke

Draw a static stroke by adding the following code to the end of the ```initWillContext:``` method:

```objective-c
    [willContext setTarget:viewLayer];
        [willContext clearColor:[UIColor whiteColor]];

        float controlPoints[] = {10,300,10, 100,100,20, 300,250,40, 300,600,50};

        WCMStrokeRenderer * strokeRenderer = [willContext  strokeRendererWithSize:viewLayer.bounds.size andScaleFactor:viewLayer.scaleFactor];
        strokeRenderer.color = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0];
        strokeRenderer.brush = [willContext solidColorBrush];
        strokeRenderer.stride = 3;
        [strokeRenderer drawPoints:[[WCMFloatVectorPointer alloc] initWithBegin:controlPoints andEnd:controlPoints+12] finishStroke:YES];
        [strokeRenderer blendStrokeInLayer:viewLayer withBlendMode:WCMBlendModeNormal];
```

Some of the key points in the first three lines of code are as follows:

- ```[willContext setTarget:viewLayer];``` sets the ```viewLayer``` as the target for all rendering operations.
- ```[willContext clearColor:[UIColor whiteColor]];``` clears the view with white color.
- The controlPoints array defines four points, each with three fields: X, Y, and Width.

**Note:** These are the control points of the Catmull-Rom spline. This spline is similar to the Cubic Bezier curve (in fact, you can convert between the two). The key difference is that all control points of the Catmull-Rom spline lie on the curve, while the control points of the Cubic Bezier curve do not.

The next line creates an instance of the ```WCMStrokeRenderer``` class. You need this class to draw a stroke. Create this class using the willContext method.

The ```strokeRenderer``` creates an internal ```bufferLayer``` that is used to perform the stroke rendering. This means that the size of the buffer layer limits the size of the strokes drawn by the ```strokeRenderer```. Create the ```strokeRenderer``` using the size and the scale factor of the ```viewLayer```, and configure it as follows:

- *color* determines the color of the stroke.
- *brush* determines how the stroke is rendered. Use the simplest option: a solid color fill brush (solidColorBrush).
- *stride* defines the offset from one control point to the next. In this tutorial, the stride is 3 because each control point has three fields: X, Y, and Width.

Finally, the stroke drawing process consists of two steps:

The ```[strokeRenderer drawPoints: finishStroke:]``` method renders the strokes in the ```bufferLayer``` of the ```strokeRenderer```.
The ```[strokeRenderer blendStrokeInLayer: withBlendMode:]``` method blends the content of the buffer layer (the stroke) in the layer that you want.
The stroke displays on the screen.

---
---
## Part 2: Building paths from touch input

In Part 2 of this tutorial, you will construct a builder that creates paths based on touch input. 

### Step 1: Create a path builder

The path builder is the component that calculates the geometry of the strokes using the touch input. 
In this tutorial, you use the ```WCMSpeedPathBuilder``` class. 
With this class, the width of the stroke changes depending on the speed at which the user moves their finger.

Create the path builder, as follows:

```objective-c
    WCMSpeedPathBuilder * pathBuilder;
```

Configure the path builder so that it produces paths with variable widths depending on the speed. 
To do this, add the following code to the ```initWillContext```: method:

```objective-c
        pathBuilder = [[WCMSpeedPathBuilder alloc] init];
        [pathBuilder setNormalizationConfigWithMinValue:0 andMaxValue:7000];
        [pathBuilder setPropertyConfigWithName:WCMPropertyNameWidth andMinValue:2 andMaxValue:15 andInitialValue:NAN andFinalValue:NAN andFunction:WCMPropertyFunctionPower andParameter:1 andFlip:NO];
```

The path builder is configured to produce strokes with a width between 2 and 15. 
It does not assume any particular unit of measurement. 
For this tutorial, you feed the path builder with coordinates measured in iOS points, which is the most common usage. 
The width of the strokes produced will also be in points.

The configuration specifies that when the touch is stationary, the stroke has the minimum width of 2 points. 
When the touch speed increases to 7,000 points per second, the width of the stroke becomes 15 points. 
Speed values above that value are capped to 7,000 points per second.

The *andFunction:WCMPropertyFunctionPower andParameter:1" parameters specify that the width increases linearly as the speed increases. 
The *andFlip:NO* parameter specifies that the minimum width applies to the minimum speed, and the maximum width applies to the maximum speed.

### Step 2: Create a member variable of the WCMStrokeRenderer class

Create a member variable of the ```WCMStrokeRenderer``` class using the following code:

```objective-c
    WCMStrokeRenderer * strokeRenderer;
```

Add the following code to the ```initWillContext```: method:

```objective-c
        strokeRenderer = [willContext strokeRendererWithSize:viewLayer.bounds.size andScaleFactor:viewLayer.scaleFactor];

        strokeRenderer.brush = [willContext solidColorBrush];
        strokeRenderer.stride = [pathBuilder calculateStride];
        strokeRenderer.color = [UIColor blackColor];
```
        
### Step 3: Manage the touch events

Add the following code to handle the touch events:

```objective-c
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
```

### Step 4: Manage the event processing

Add the following code to handle the event processing:

```objective-c
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
```

The ```[pathBuilder addPointWithPhase:wcmInputPhase andX:location.x andY:location.y andTimestamp:touch.timestamp]``` method call calculates a set of points that represent the stroke geometry (the position and width). 
You can modify the list that is returned (for example, in the next part of this tutorial you will smooth out noise in the input). 
For now, add it to the current path using the ```[pathBuilder addPathPart:points]``` call.

**Note:** After the calls to the path builder, the control points of the stroke are stored in the ```pathAppendResult``` object. 
The wholePath property contains the whole path build up to this point. 
You use the addedPath property because you want to draw only the part added during this event loop.

### Step 5: Change the screen update method

Change the ```refreshView:``` method to ```refreshViewInRect:```. 
This setting allows you to update only the area of the screen that has been changed (using the ```updatedArea``` property of the ```strokeRenderer```). 
This setting is an important performance optimization.

```objective-c
-(void) refreshViewInRect:(CGRect)rect
{
    [willContext setTarget:viewLayer andClipRect:rect];
    [willContext clearColor:[UIColor whiteColor]];

    [strokeRenderer blendStrokeUpdatedAreaInLayer:viewLayer withBlendMode:WCMBlendModeNormal];

    [viewLayer present];
}
```

Use the ```[strokeRenderer blendStrokeUpdatedAreaInLayer:viewLayer withBlendMode:WCMBlendModeNormal]``` method to blend only the area where the stroke is updated. 
The stroke is updated by the ```[WCMStrokeRenderer drawPoints:finishStroke:]``` call.

You might notice that the strokes are jagged. 
This is due to the noise in the input data from the user’s touch input. 
In the next part of this tutorial, you will solve this issue.

---
---
## Part 3: Smoothing paths

To smooth out your strokes, you need the ```WCMMultiChannelSmoothener``` class. 
The smoothing process changes the stroke geometry by modifying its points.

In Part 3 of this tutorial, you will create a smoothener to soften the jagged edges on strokes. 

### Step 1: Create the smoothener

Create an instance of the ```WCMMultiChannelSmoothener``` class in the ```initWillContext``` method:

```objective-c
    WCMMultiChannelSmoothener * pathSmoothener;
```

```objective-c
- (void) initWillContext
{
        ...
        int pathStride = [pathBuilder calculateStride];
        pathSmoothener = [[WCMMultiChannelSmoothener alloc] initWithChannelsCount:pathStride];
}
```

### Step 2: Update the touch event processing to smooth strokes

Update the ```processTouches:withEvent:``` method.

First, reset the smoothener when begining a new stroke:

```objective-c
        if (touch.phase == UITouchPhaseBegan)
        {
            ...
            //When starting a new path, we must reset the smoothener state.
            [pathSmoothener reset];
        }
```

Smooth out the points returned by the ```addPointWithPhase:``` method. 
The path builder is designed so that you can modify the points returned by ```addPointWithPhase:``` before you add them to the path using the ```addPathPart:``` method.

```objective-c
        WCMFloatVectorPointer * points = [pathBuilder addPointWithPhase:wcmInputPhase andX:location.x andY:location.y andTimestamp:touch.timestamp];
        WCMFloatVectorPointer * smoothedPoints = [pathSmoothener smoothValues:points reachFinalValues:wcmInputPhase == WCMInputPhaseEnd];
        WCMPathAppendResult* pathAppendResult = [pathBuilder addPathPart:smoothedPoints];
```

Use the ```[pathSmoothener smoothValues:points reachFinalValues:wcmInputPhase == WCMInputPhaseEnd]``` call. 
This call returns a new instance of the ```WCMFloatVectorPointer``` class that contains the smoothed values.

After implementing the smoothener, the strokes look much cleaner.

**Note:** When the ```reachFinalValues:``` parameter is set to ```NO```, the smoothener returns a set of smoothed values that are different to the original values. 
When the parameter is set to ```YES```, the class returns a series of several values, the last of which is equal to the original value. 
Set the parameter to ```YES``` only when the touch has ended. 
This configuration means that the stroke will finish at the actual position of the touch.

---
---
## Part 4: Drawing semi-transparent strokes

Up to this point, your strokes have been completely opaque and the same color. 
This allowed you to store them all in the buffer layer of the ```WCMStrokeRenderer``` class. 
However, the ```WCMStrokeRenderer``` class is intended to draw a single stroke only and to be cleared before drawing another stroke. 
Because the ```WCMStrokeRenderer``` uses special blending rules (modes), drawing strokes with different colors will have unexpected results.

In Part 4 of this tutorial, you will enable the use of semi-transparent strokes and strokes of different colors.

### Step 1: Create a new layer to store completed strokes

Because the ```strokeRenderer``` instance stores only the current stroke, you need an additional layer to store all completed strokes:

```objective-c
    WCMLayer * strokesLayer;
```

Add the following code to the ```initWillContext``` method:

```objective-c
    strokesLayer = [willContext layerWithWidth:viewLayer.bounds.size.width andHeight:viewLayer.bounds.size.height andScaleFactor:viewLayer.scaleFactor andUseTextureStorage:YES];
```

Update the ```refreshViewInRect:``` method as follows:

```objective-c
-(void) refreshViewInRect:(CGRect)rect
{
    [willContext setTarget:viewLayer andClipRect:rect];
    [willContext clearColor:[UIColor whiteColor]];

    [willContext drawLayer:strokesLayer withSourceRect:rect andDestinationRect:rect andBlendMode:WCMBlendModeNormal];

    [strokeRenderer blendStrokeUpdatedAreaInLayer:viewLayer withBlendMode:WCMBlendModeNormal];

    [viewLayer present];
}
```

The method now draws the ```strokesLayer``` first, then blends the current stroke to the layer.

### Step 2: Update the touch event processing to draw each new stroke in a random color

Update the touch event processing to do the following:

- When you begin a new stroke, call the ```[strokeRenderer clearStrokeBuffer]``` method. 
  This clears the internal buffer so it is ready for a stroke. 
- Set a random color for every new stroke. 
- When the stroke finishes, add it to the ```strokesLayer``` using the ```[strokeRenderer blendStrokeInLayer:strokesLayer withBlendMode:WCMBlendModeNormal]``` call.

To do this, update the ```processTouches:``` method as follows:

```objective-c
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
            [strokeRenderer clearStrokeBuffer];
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
```

You might notice that the stroke lags behind the touch. This is an inevitable result of the smoothing process because the smoothener needs to wait a moment before it decides the slope of the stroke trajectory. In the next part of this tutorial, you will work around this issue.

---
---
## Part 5: Drawing preliminary paths

In Part 4 of this tutorial, the path smoothener caused the path position to lag behind the actual touch position. 
You can mask this issue by using the ```[WCMPathBuilder drawPreliminaryPoints:]``` method to continue the path to the actual touch position. 
This portion of the path will be drawn as a preliminary path in an internal layer. 
On the next rendering cycle, the preliminary path will be overridden with the new one.

In Part 5 of this tutorial, you will create preliminary paths to mask the lag caused by path smoothing.

### Step 1: Call the ```createPreliminaryPath``` method

In the ```processTouches:``` method, call the ```createPreliminaryPath``` method of the path builder using the following code:

```objective-c
WCMFloatVectorPointer * prelimPoints = [pathBuilder createPreliminaryPath];
```

### Step 2: Smooth the result

Smooth the result by setting the ```reachFinalValues:``` parameter of the ```smoothValues:``` method to ```YES```. 
With this setting, the smoothener will create a list of values, the last of which will be equal to the target value.

```objective-c
WCMFloatVectorPointer * smoothedPrelimPoints = [pathSmoothener smoothValues:prelimPoints reachFinalValues:YES];
```

### Step 3: Call the ```finishPreliminaryPath``` method

Call the ```finishPreliminaryPath:``` method. 
You have the control points of the preliminary path in the ```WCMFloatVectorPointer``` object.

```objective-c
WCMFloatVectorPointer * prelimPath = [pathBuilder finishPreliminaryPath:smoothedPrelimPoints];
```

### Step 4: Call the ```[strokeRenderer drawPreliminaryPoints:]``` method

Call the ```[strokeRenderer drawPreliminaryPoints:]``` method with the ```prelimPath``` list.

```objective-c
objectiveC

[strokeRenderer drawPreliminaryPoints:prelimPath];
```

The updated ```processTouches:``` method is as follows:

```objective-c
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
            [strokeRenderer clearStrokeBuffer];
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

        WCMFloatVectorPointer * prelimPoints = [pathBuilder createPreliminaryPath];
        WCMFloatVectorPointer * smoothedPrelimPoints = [pathSmoothener smoothValues:prelimPoints reachFinalValues:YES];
        WCMFloatVectorPointer * prelimPath = [pathBuilder finishPreliminaryPath:smoothedPrelimPoints];

        [strokeRenderer drawPoints:pathAppendResult.addedPath finishStroke:wcmInputPhase == WCMInputPhaseEnd];
        [strokeRenderer drawPreliminaryPoints:prelimPath];

        if (wcmInputPhase == WCMInputPhaseEnd)
        {
            [strokeRenderer blendStrokeInLayer:strokesLayer withBlendMode:WCMBlendModeNormal];
        }

        [self refreshViewInRect:strokeRenderer.updatedArea];
    }
}
```
Creating the preliminary path increases the code complexity slightly. 
It also increases the cost of rendering because you now have two draw stroke calls and an additional transfer of pixels between the buffer layers of the ```WCMStrokeRenderer``` object. 
The benefit is that the lag is eliminated, which is important for a good user experience.

---
---
## Part 6: Using a particle brush

Drawing a solid color stroke is useful, but you might want to do more. 
WILL SDK for ink provides an advanced stroke rendering method. 
It can produce very expressive strokes at the cost of being more computationally expensive. 
It draws a large number of small textures (called particles) scattered along the path of the stroke. 
This is configured using the ```WCMStrokeBrush``` class.

In Part 6 of this tutorial, you will create a particle brush. This part builds on Part 4 of this tutorial.

### Step 1: Create a new particle brush

Create a new particle brush using the following code:

```objective-c
        pathBrush = [willContext particleBrushWithFillImage:[UIImage imageNamed:@"fill.png"]
                                                 andShapeImage:[UIImage imageNamed:@"shape.png"]
                                                    andSpacing:0.15
                                                 andScattering:0.05
                                                  andBlendMode:WCMBlendModeNormal
                                                andRotation:WCMStrokeBrushRotationRandom];
```
This brush draws a large number of small images (```shape.png```) along the path of the stroke. 
The small images are then filled by repeating the ```fill.png``` image.

The distance between the particles is controlled by the ```spacing``` parameter. 
In this example, the value of 0.15 means that the particles are offset by 15% of their width.

The sideways spread of the particles is controlled by the ```scattering``` parameter. 
A value of 0 means no spreading. A value of 0.05, as in this example, means that the particles spread a random amount between 0% to 5% of their width.

The rotation of the ```shape.png``` texture is controlled by the ```rotation``` parameter. 
The value of ```WCMStrokeBrushRotationRandom``` means that the texture rotates randomly. 
The alternative is the value ```WCMStrokeBrushRotationTrajectory```, which means that each particle rotates so that it is oriented in the direction of the stroke.

### Step 2: Set a variable stroke opacity

To vary the opacity of the stroke, update the path builder so that it calculates the ```alpha``` values for the opacity at each control point.

```objective-c
        pathBuilder = [[WCMSpeedPathBuilder alloc] init];
        [pathBuilder setNormalizationConfigWithMinValue:10 andMaxValue:1400];
        [pathBuilder setPropertyConfigWithName:WCMPropertyNameWidth andMinValue:18 andMaxValue:28 andInitialValue:NAN andFinalValue:NAN andFunction:WCMPropertyFunctionPower andParameter:1 andFlip:NO];
        [pathBuilder setPropertyConfigWithName:WCMPropertyNameAlpha andMinValue:0.1 andMaxValue:0.6 andInitialValue:NAN andFinalValue:NAN andFunction:WCMPropertyFunctionPower andParameter:1 andFlip:YES];
```
The key call is ```setPropertyConfigWithName:WCMPropertyNameAlpha```. 
This call tells the path builder to calculate the opacity values. 
Since you use the ```WCMSpeedPathBuilder``` class, the opacity will vary from minValue to maxValue depending on the speed at which the stroke is drawn. 
The andFunction:WCMPropertyFunctionPower andParameter:1 parameters make the values change linearly. 
The andFlip:YES parameter specifies high opacity for low speeds and low opacity for high speeds.

Strokes rendered like this have a random nature. 
If you render the same control points a second time, the stroke will be slightly different. 
If you need the strokes to look the same each time they are rendered, you can use the *rngSeed* property of the ```WCMStrokeRenderer``` class. 
This field is the seed of the random number generator that is used. 
The ```WCMStrokeRenderer``` class updates this value each time you draw new points. 
You can save this value and later reset it so the stroke will be rendered exactly the same as the first time.

---
---
## Part 7: Generating a Bezier path

The paths that WILL SDK for ink generates are Catmull-Rom splines that have a variable width. 
WILL SDK for ink can render them efficiently, but you might need to represent the shape of the stroke in a more standard way: a list of Bezier curves defining the boundaries of the stroke. 
If you have this representation, you can render the stroke using Quartz or use it to produce an SVG or PDF document.

WILL SDK for ink provides the utility class ```WCMBezierPathUtils``` that produces an instance of the ```UIBezierPath``` class from a set of WILL paths.

In Part 7 of this tutorial, you will generate a Bezier path from your stroke. 
This part continues on from Part 5 of this tutorial.

### Step 1: Define a method to create and display Bezier paths based on strokes

Create an instance of ```WCMBezierPathUtils```.
 
Call the ```[pathUtils addPathPoints:points andStride:[pathBuilder calculateStride] andWidth:NAN]``` method using the path points that represent the stroke. 
It is possible to combine many WILL paths into a single ```UIBezierPath``` instance by calling ```addPathPoints:andStride:andWidth:``` multiple times. 
However, in this tutorial, you create a new ```UIBezierPath``` instance for each stroke.

Call the ```[pathUtils createUIBezierPath]``` method, which produces the ```UIBezierPath```. 

Display the path by creating a ```CAShapeLayer``` instance and adding it as a sublayer of the view.

The completed ```generateBezierPath:``` method is as follows:

```objective-c
-(void) generateBezierPath:(WCMFloatVectorPointer*)points
{
    WCMBezierPathUtils * pathUtils = [[WCMBezierPathUtils alloc] init];
    [pathUtils addPathPoints:points andStride:[pathBuilder calculateStride] andWidth:NAN];
    UIBezierPath * bezierPath = [pathUtils createUIBezierPath];

    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    [shapeLayer setPath:bezierPath.CGPath];
    shapeLayer.fillColor = [UIColor redColor].CGColor;
    shapeLayer.position = CGPointMake(0, 0);
    [[self layer] addSublayer:shapeLayer];

    NSLog(@"%@", points);
    NSLog(@"%@", bezierPath);
}
```

You can expect very small differences between the original path (rendered with WILL) and the ```UIBezierPath``` instance. 
These differences are mainly in the anti-aliasing.

### Step 2: Update the touch processing method to generate the Bezier path

When a stroke is finished, generate a Bezier path. 
To do this, add a single line of code in the ```- (void) processTouches:(NSSet *)touches withEvent:(UIEvent *)event``` method of the code sample from Part 5.

Add the code as follows:

```objective-c
- (void) processTouches:(NSSet *)touches withEvent:(UIEvent *)event
{
    ...
    if (wcmInputPhase == WCMInputPhaseEnd)
    {
        ...

        [self generateBezierPath:pathAppendResult.wholePath];
    }
    ...
}
```

---
---


