# Tutorial 5: Working with rasters

In this tutorial you will load an instance of the UIImage class into WILL, then mask it with a path created by touch input. The tutorial is divided into the following parts:

* [Part 1: Displaying raster images](#part-1-displaying-raster-images)
* [Part 2: Creating image masks](#part-2-creating-image-masks)

Each part builds on the previous part, extending and improving its functionality.

## Prerequisites
This tutorial continues on from Part 1 of Tutorial 1: Drawing with touch.

Source code
You can find the sample project in the following location:
```Xcode: /ios/Samples/RasterManipulation/```

---
---
## Part 1: Displaying raster images

Although the WILL SDK for ink *Rasterizer* module is not a general-purpose 2D drawing engine, it can draw raster images. 
In this tutorial, you will display and mask images using the functionality provided in the SDK.

In Part 1 of this tutorial, you will load and display a raster image. Part 1 of this tutorial continues on from Part 1 of Tutorial 1: Drawing with touch.

### Step 1: Create a layer to hold the raster image

Create a texture-backed ```WCMLayer``` using the size and scale factor of the image:

```objective-c
        imageLayer = [willContext layerWithWidth:img.size.width andHeight:img.size.height andScaleFactor:img.scale andUseTextureStorage:YES];
```
        
### Step 2: Load the raster image

Use the ```writePixelsInCurrentTargetFromUIImage:``` method of the ```WCMRenderingContext``` class to load the raster image to the ```imageLayer```:

```objective-c
        UIImage* img = [UIImage imageNamed:@"img.jpg"];
        [willContext setTarget:imageLayer];
        [willContext writePixelsInCurrentTargetFromUIImage:img];
```

### Step 3: Display the raster image

Update the ```refreshView``` method to draw the imageLayer on the screen:

```objective-c
-(void) refreshView
{
    [willContext setTarget:viewLayer];
    [willContext drawLayer:imageLayer withBlendMode:WCMBlendModeOverride];
    [willContext drawLayer:strokesLayer];
    [viewLayer present];
}
```

---
---
## Part 2: Creating image masks

In Part 2 of this tutorial, you will create an image mask and apply it to an image. You will create the shape of the mask using touch input.

### Step 1: Create a mask

Edit the ```processTouches:``` method to create a mask. 
To do this, when the ```WCMInputPhase``` is set to ```WCMInputPhaseEnd```, pass the ```wholePath``` of the path builder to the ```fillPath``` method of the ```WCMRenderingContext``` class:

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

        CGRect dirtyArea;
        if (wcmInputPhase == WCMInputPhaseEnd)
        {
            [willContext setTarget:maskLayer];
            [willContext clearColor:[UIColor clearColor]];
            [willContext fillPath:pathAppendResult.wholePath.begin
                    andBufferSize:pathAppendResult.wholePath.size
                        andStride:pathStride
                         andColor:[UIColor whiteColor]
                   andAntiAliased:YES];

            dirtyArea = viewLayer.bounds;

            [strokeRenderer clearStrokeBuffer];
        }
        else
        {
            [strokeRenderer drawPoints:pathAppendResult.addedPath finishStroke:NO];
            [strokeRenderer drawPreliminaryPoints:prelimPath];

            dirtyArea = strokeRenderer.updatedArea;
        }

        [self refreshViewInRect:dirtyArea];
    }
}
```

### Step 2: Display the masked area

Update the ```refreshViewInRect``` view method to draw the mask layer over the image layer using the ```WCMBlendModeDirectMultiply``` blend mode from ```WCMBlendMode:```

```objective-c
-(void) refreshViewInRect:(CGRect)rect
{
    [willContext setTarget:viewLayer andClipRect:rect];

    [willContext drawLayer:imageLayer withSourceRect:rect andDestinationRect:rect andBlendMode:WCMBlendModeOverride];

    [willContext drawLayer:maskLayer withSourceRect:rect andDestinationRect:rect andBlendMode:WCMBlendModeDirectMultiply];

    [strokeRenderer blendStrokeUpdatedAreaInLayer:viewLayer withBlendMode:WCMBlendModeNormal];

    [viewLayer present];
}
```

This cuts out the part of the image enclosed by the path. 
Where the mask color is white, blending the mask with this blend mode leaves the current pixels unchanged. 
Where the mask color is black, the existing pixels are set to transparent black.

---
---

