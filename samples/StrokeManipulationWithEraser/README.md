# Tutorial 3: Erasing strokes

In this tutorial, you will make changes in a collection of strokes by implementing an Eraser tool. 
First, you will implement the tool so that it removes strokes from the collection. 
Next, you will learn how to remove only parts of the strokes using the WILL *Manipulation* module. 
The tutorial is divided into the following parts:

* [Part 1: Extending the stroke model](#part-1-extending-the-stroke-model)
* [Part 2: Creating an eraser](#part-2-creating-an-eraser)
* [Part 3: Erasing parts of strokes](#part-3-erasing-parts-of-strokes)

Each part builds on the previous part, extending and improving its functionality.

## Prerequisites
This tutorial continues on from Part 2 of Tutorial 2: Encoding and decoding strokes.

## Source code
You can find the sample project in the following location:
```Xcode: /ios/Samples/StrokeEraser```

---
---
## Part 1: Extending the stroke model

The WILL *Manipulation* module needs additional data about the strokes. 
To be precise, it needs the bounds of each individual segment (the curve between two control points). 
The interaction calculations speed up significantly if you calculate the bounds beforehand. 
WILL SDK provides methods to calculate the bounds, but you must store them in the stroke model.

In Part 1 of this tutorial, you will extend the stroke model to calculate and store the bounds of the stroke. 
Part 1 of this tutorial continues on from Part 2 of Tutorial 2: Encoding and decoding strokes.

### Step 1: Add properties to the Stroke class to store information on bounds

Add the following properties to the ```Stroke``` class:

```objective-c
@property (readonly) CGRect bounds;
```

```objective-c
@property (readonly) WCMCGRectVector* segmentsBounds;
```

### Step 2: Create the ```calculateBounds`` method

Create the ```calculateBounds``` method and call it from the ```init``` method.

```objective-c
-(void) calculateBounds
{
    segmentsBounds = WCMCalculateStrokeSegmentsBoundsVector(self.points.pointer, self.stride, self.width, 0.0);

    bounds = CGRectNull;
    for (int i=0;i<segmentsBounds.size;i++)
    {
        bounds = CGRectUnion(bounds, segmentsBounds.begin[i]);
    }
}
```

```objective-c
+(Stroke*) strokeWithPoints:(WCMFloatVector*)points andStride:(int)stride andWidth:(float)width andColor:(UIColor*)color andTs:(float)ts andTf:(float)tf andBlendMode:(WCMBlendMode)blendMode
{
    ...

    [result calculateBounds];

    return result;
}
```

**Note:** The size of the ```segmentsBounds``` vector is always 3 less than the size of of the ```points``` vector. 
This is because of the nature of the Catmull-Rom spline. 
The Catmull-Rom spline needs 4 points to define a single curve (segment). 
For 4 points, you have a single segment. 
Each additional point adds a new segment because it uses the previous 3 control points to define the Catmull-Rom spline.

With this addition to the ```Stroke``` class, you can proceed to the actual stroke manipulation.

---
---
## Part 2: Creating an eraser

In Part 2 of this tutorial, you will create an eraser tool that erases an entire stroke.

### Step 1: Update the path building configuration to create a thicker path

You want the eraser tool to create a thicker path. 
Update the path building configuration to do this as follows:

```objective-c
        pathBuilder = [[WCMSpeedPathBuilder alloc] init];
        [pathBuilder setNormalizationConfigWithMinValue:0 andMaxValue:7000];
        [pathBuilder setPropertyConfigWithName:WCMPropertyNameWidth andMinValue:50 andMaxValue:50 andInitialValue:NAN andFinalValue:NAN andFunction:WCMPropertyFunctionPower andParameter:1 andFlip:NO];
```

### Step 2: Implement an ```erase``` method to remove strokes that intersect with the eraser path

Create a ```WCMIntersector``` instance to perform the calculations needed to determine if a stroke intersects the eraser path.

Set the path part calculated by the ```pathBuilder``` class as the target of the intersection. 
For each stroke, check if it intersects the target. 
If it does intersect the target, remove the stroke from the ```strokes``` array.

```objective-c
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
                                          andSegmentsBounds:s.segmentsBoundsPointer];

        if (!intersects)
        {
            [newStrokes addObject:s];
        }
    }

    strokes = newStrokes;
    [self redrawStrokes];
}
```

### Step 3: Update the touch event processing to use the eraser

Add the following call to the ```processTouches:withEvent:``` method:

```objective-c
        [self erase:pathAppendResult.addedPath];
```

---
---
## Part 3: Erasing parts of strokes

In Part 2 of this tutorial, you created an eraser tool that erased entire strokes.

Instead of removing strokes from the array, you might want to remove only parts of them. 
You can do this by using the ```intersectTarget:``` method. 
The method returns an array of intervals stored in the ```WCMPathInterval``` structure. 
Each interval of the path is either totally inside or totally outside the intersection target. 
You can remove the original strokes and create new strokes for each interval that is outside the target.

In Part 3 of this tutorial, you will create an eraser tool that erases only the parts of strokes that the tool touches.

### Step 1: Change the ```erase``` method

Define the utility method ```strokeFromStroke:andInterval:``` to split strokes into new strokes using the ```WCMPathInterval``` array. 
This method creates a stroke from the interval of another stroke, as follows:

```objective-c
+(Stroke*) strokeFromStroke:(Stroke*)s andInterval:(WCMPathInterval)interval
{
    Stroke * result = [[Stroke alloc] init];
    result->_points = [WCMFloatVector vectorWithBegin:s.points.begin + interval.fromIndex*s.stride
                                               andEnd:s.points.begin + (interval.toIndex+1)*s.stride];
    result->_stride = s->_stride;
    result->_width = s->_width;
    result->_color = s->_color;
    result->_blendMode = s->_blendMode;
    result->_ts = interval.fromT;
    result->_tf = interval.toT;

    [result calculateBounds];

    return result;
}
```

Note the use of (```interval.toIndex+1```) in the code. 
This value is used because the ```WCMFloatVector``` end property points just after the last element of the list.

Using the ```WCMPathInterval``` intervals array, check if the interval is outside the intersection target and create a new stroke for it. 
To do this, change the ```erase:``` method as follows:

```objective-c
-(void) erase:(WCMFloatVectorPointer*)pts
{
    WCMIntersector* intersector = [[WCMIntersector alloc] init];
    [intersector setTargetAsStrokeWithPoints:pts andPointsStride:pathStride andWidth:NAN];

    NSMutableArray * newStrokes = [NSMutableArray array];

    for (Stroke* s in strokes)
    {
        size_t intervalsCount;
        WCMPathInterval* intervals = [intersector intersectTargetWith:s.points.pointer
                                                       andPointStride:s.stride
                                                             andWidth:s.width
                                                                andTs:s.ts andTf:s.tf
                                                      andStrokeBounds:s.bounds
                                                    andSegmentsBounds:s.segmentsBounds.begin
                                                       intervalsCount:&intervalsCount];

        //optimzation: When only one interval, that interval covers the whole stroke.
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
```

---
---

