# Tutorial 4: Selecting strokes

In this tutorial, you will make changes in a collection of strokes. 
First, you will implement a selection tool to select whole strokes; next, you will use the WILL *Manipulation* module to remove and redraw parts of strokes. 
The tutorial is divided into the following parts: 

* [Part 1: Selecting whole strokes](#part-1-selecting-whole-strokes)
* [Part 2: Selecting parts of strokes](#part-2-selecting-parts-of-strokes)

Each part builds on the previous part, extending and improving its functionality.

## Prerequisites
This tutorial continues on from Part 1 of Tutorial 3: Erasing strokes.

## Source code
You can find the sample project in the following location:
```Xcode: /ios/Samples/StrokeManipulationWithSelection```

---
---
### Part 1: Selecting whole strokes

In this tutorial, you will modify the path builder to select whole strokes and parts of strokes. 
This tutorial builds on Part 1 of Tutorial 3: Erasing strokes.

In Part 1 of this tutorial, you will select whole strokes and change their colors.

### Step 1: Modify the path builder to draw a stroke of constant width

To define a path builder configuration for a stroke with a constant width, remove all property configurations for the ```pathBuilder``` class:

```
    pathBuilder = [[WCMSpeedPathBuilder alloc] init];
```

### Step 2: Select strokes

Update the ```processTouches:withEvent:``` method to do the following:

* Set the target of the intersection to be the area enclosed by the whole path as calculated by the path builder.
* Call the method ```[self selectedByPath:pathAppendResult.wholePath]``` (which is defined in the next step) when the stroke is finished.

The code for this step is as follows:

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

        CGRect diryArea;
        if (wcmInputPhase == WCMInputPhaseEnd)
        {
            [strokeRenderer clearStrokeBuffer];
            [self selectedByPath:pathAppendResult.wholePath];

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
```

### Step 3: Change the color of the selected strokes

Create a ```WCMIntersector``` instance to do the following:

* Calculate whether a stroke intersects the selection area. 
  Use the ```setTargetAsClosedPathWithPoints:``` method to tell the ```intersector``` that the target is the space enclosed by the whole path as calculated by the ```pathBuilder```.
* For each stroke that intersects the target, change its color to green. 
  Otherwise, change the stroke color to black.

The code for this step is as follows:

```
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

    [self redrawStrokes];
}
```

**Note:** In this case, because the ```pathBuilder``` does not have a width configuration, the path produced does not have a width property (its stride is 2), and the ```intersector``` does not need the width of the path when using the ```setTargetAsClosedPathWithPoints:``` method. 
If a path has a width property, the property is ignored.

---
---
## Part 2: Selecting parts of strokes

In Part 1 of this tutorial, you selected whole strokes; in Part 2 you will select parts of strokes inside a selection area and remove them.

### Step 1: Find intersections with strokes

Use the ```intersectTarget:``` method to find intersections with drawn paths. 
This method returns an array of path ```intervals:``` each interval is either totally inside or totally outside the area.


### Step 2: Remove selected stroke intervals

Update the ```removeSelectedByPath:``` method to remove intervals that are inside the target. 
For intervals outside the target, create new strokes to replace them.

The code for this is as follows:

```objective-c
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
                                             andSegmentsBounds:s.segmentsBoundsPointer
                                                        intervalsCount:&intervalsCount];

        //optimzation: When a single interval, it covers the whole stroke.
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
                    Stroke * newStroke = [Stroke strokeFromStroke:s
                                                        fromIndex:interval.fromIndex
                                                          toIndex:interval.toIndex
                                                           withTs:interval.fromT
                                                            andTf:interval.toT];
                    [newStrokes addObject:newStroke];
                }
            }
        }
    }

    strokes = newStrokes;
    [self redrawStrokes];
}
```

---
---

