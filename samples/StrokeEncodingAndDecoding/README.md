# Tutorial 2: Encoding and decoding strokes

In this tutorial, you learn how to create a model for path points that you will call a ```Stroke```, encode strokes into a compressed binary data, and package them in a WILL Document file. 
The tutorial is divided into the following parts:

* [Part 1: Creating a stroke model](#part-1-creating-a-stroke-model)
* [Part 2: Serializing and deserializing strokes](#part-2-serializing-and-deserializing-strokes)

Each part builds on the previous part, extending and improving the functionality.

The stroke model that you create in this tutorial is also essential in Tutorial 3: Erasing strokes and Tutorial 4: Selecting strokes, where you will modify the model.

## Prerequisites

This tutorial continues on from Part 2 and Part 4 of Tutorial 1: Drawing with touch.

## Source code

You can find the sample project in the following location:
```Xcode: /ios/Samples/StrokeEncodingAndDecoding```

---
---
## Part 1: Creating a stroke model

In this tutorial, you will learn how to use WILL SDK for ink to encode strokes into compressed binary data and how to reconstruct strokes from encoded data.

In Part 1 of this tutorial, you will create a model to store strokes. 
Part 1 of this tutorial continues on from Part 2 and Part 4 of Tutorial 1: Drawing with touch.

### Step 1: Create a simple model to store the strokes

Before you begin the serialization process, create a simple model to store the strokes that you build. 
The model consists of a single class, called ```Stroke```:

```objective-c
@interface Stroke : NSObject

+(Stroke*) strokeWithPoints:(WCMFloatVector*)points andStride:(int)stride andWidth:(float)width andColor:(UIColor*)color andTs:(float)ts andTf:(float)tf andBlendMode:(WCMBlendMode)blendmode;

@property float width;
@property UIColor* color;
@property int stride;
@property float ts, tf;
@property WCMBlendMode blendMode;

@property (readonly) WCMFloatVector* points;

@end
```

```objective-c
@implementation Stroke

+(Stroke*) strokeWithPoints:(WCMFloatVector*)points andStride:(int)stride andWidth:(float)width andColor:(UIColor*)color andTs:(float)ts andTf:(float)tf andBlendMode:(WCMBlendMode)blendmode
{
    Stroke * result = [[Stroke alloc] init];
    result->_points = points;
    result->_stride = stride;
    result->_width = width;
    result->_color = color;
    result->_ts = ts;
    result->_tf = tf;
    result->_blendMode = blendmode;

    return result;
}

@end
```

The ```Stroke``` class has the following properties:

* *points:* An array of the control points of the path. Depending on the type of stroke, each control point could have the following fields:
	* X,Y
	* X,Y,Width
	* X,Y,With,Alpha
* *stride:* The offset from one control point to the next. The offset could be 2, 3, or 4, depending on whether the points have Width or Alpha fields.
* *width:* The constant width of the stroke if the control points have only the X,Y or X,Y,Alpha fields. Otherwise, the width is NAN.
* *ts:* The starting value of the Catmull-Rom spline parameter of the first curve of the path. The default value is 0.
* *tf:* The final value of the Catmull-Rom spline parameter of the last curve the path. The default value is 1.
* *blendmode:* The blend mode used in the rendering process when blending the stroke with content already present in the target layer.

### Step 2: Create an array to store the strokes

Create an array called strokes as follows:
```objective-c
    NSMutableArray * strokes;
```

Add the following code to the ```initWithFrame:``` method:
```objective-c
        strokes = [NSMutableArray array];
```        
        
### Step 3: Add the strokes to the array

Add the following code to the ```processTouches:``` method:

```objective-c
        if (wcmInputPhase == WCMInputPhaseEnd)
        {
            Stroke* stroke = [Stroke strokeWithPoints:[WCMFloatVector vectorWithBegin:pathAppendResult.wholePath.begin andEnd:pathAppendResult.wholePath.end]
                                            andStride:pathStride
                                             andWidth:NAN
                                             andColor:[UIColor blackColor]
                                                andTs:0
                                                andTf:1
                                         andBlendMode:WCMBlendModeNormal];
            [strokes addObject:stroke];
        }
```

The ```strokes``` array is now filled. 
By creating a new instance of the ```WCMFloatVector``` class, you copy the points from the ```pathAppendResult.wholePath``` object. 
This is important because the ```pathAppendResult.wholePath``` object will change when building a new stroke with the path builder.
        
---
---

## Part 2: Serializing and deserializing strokes

WILL SDK for ink provides the ```WCMInkDecoder``` and ```WCMInkEncoder``` classes. 
The ```WCMInkEncoder``` class creates a compressed binary representation for a collection of strokes. 
The ```WCMInkDecoder``` class reads this binary data and recreates the strokes. 
The ```WCMDocument``` class can then encode the stroke data in a WILL Document file.

In Part 2 of this tutorial, you will use these classes to encode and decode strokes.

### Step 1: Encode the strokes using the ink encoder

The encoding process is straightforward.

Create a ```WCMInkEncoder``` instance and call the ```encodePathWithPrecision:``` method for each stroke in your collection.

Call ```getBytes```. The only parameter whose purpose is not clear is the ```decimalScale``` parameter. 
This parameter is used when the stroke coordinates are converted from floating-point numbers to fixed-point numbers. 
It specifies the number of digits after the decimal point (in base 10) to store. 
In most cases, two digits is enough.

The other parameters of the ```encodePathWithPrecision``` method are as follows:

* points
* stride
* width
* color
* ts
* tf

For more information about the parameters, see the reference documentation for ```WCMInkEncoder```.

### Step 2: Create a document to store the encoded strokes

Create an instance of the ```WCMDocument``` class.

Create a new instance of the ```WCMDocumentSection``` class. 
This class represents a scene inside the document. 
Each scene can contain strokes, images, and other graphic elements. In this tutorial, the scene contains strokes only.

### Step 3: Store the encoded strokes in the document

To store the strokes, create an instance of the ```WCMDocumentSectionPaths``` class.

Set the content of the paths element instance with the binary data produced by the ```WCMInkDecoder``` class.

Add the section to the document and the paths element to the section.

Call the ```createDocumentAtPath:``` method as follows:

```objective-c
- (void) saveStrokes:(NSMutableArray*)strokes toPath:(NSString*)path
{
    WCMInkEncoder * inkEncoder = [[WCMInkEncoder alloc] init];
    for (Stroke * s in strokes)
    {
        [inkEncoder encodePathWithPrecision:2 andPoints:s.points andStride:s.stride andWidth:s.width andColor:s.color andTs:0 andTf:1 andBlendMode:WCMBlendModeNormal];
    }

    NSData * inkData = [inkEncoder getBytes];

    WCMDocument * doc = [[WCMDocument alloc] init];

    WCMDocumentSection * section = [[WCMDocumentSection alloc] init];
    section.size = self.view.bounds.size;

    WCMDocumentSectionPaths * pathsElement = [[WCMDocumentSectionPaths alloc] init];
    [pathsElement.content setData:inkData withType:[WCMDocumentContentType STROKES]];

    [doc.sections addObject:section];
    [section addElement:pathsElement];

    [doc createDocumentAtPath:path];
}
```

### Step 4: Load the file with the file format decoder

The decoding process is also straightforward.

Create a ```WCMDocument``` instance and load the data from the file using the ```loadDocumentAtPath:``` method.

### Step 5: Find the encoded ink in the document

To obtain the encoded ink, take the first section in the document and then the first subelement of that section. 
This subelement should be a paths element (an instance of ```WCMDocumentSectionPaths```).

### Step 6: Decode the strokes using the ink decoder

Create a ```WCMInkDecoder``` instance. Initialize it with the data contents of the paths element.

Call the ```decodePathToPoints:``` method until it returns ```NO```, which indicates that there are no remaining strokes to decode.

The completed code is as follows:

```objective-c
- (NSMutableArray*) decodeStrokesFromDocumentPath:(NSString*)path
{
    WCMDocument * doc = [[WCMDocument alloc] init];

    [doc loadDocumentAtPath:path];

    WCMDocumentSection * section = doc.sections[0];
    WCMDocumentSectionPaths * pathsElement = section.subelements[0];
    NSData * inkData = [pathsElement.content loadData];

    WCMInkDecoder * decoder = [[WCMInkDecoder alloc] initWithData:inkData];

    WCMFloatVector* strokePoints;
    unsigned int strokeStride;
    float strokeWidth;
    UIColor* strokeColor;
    float strokeStartValue;
    float strokeFinishValue;
    WCMBlendMode blendMode;

    NSMutableArray * strokes = [[NSMutableArray alloc] init];

    while([decoder decodePathToPoints:&strokePoints
                            andStride:&strokeStride
                             andWidth:&strokeWidth
                             andColor:&strokeColor
                                andTs:&strokeStartValue
                                andTf:&strokeFinishValue
                         andBlendMode:&blendMode])
    {
        Stroke * stroke = [Stroke strokeWithPoints:strokePoints
                                         andStride:strokeStride
                                          andWidth:strokeWidth
                                          andColor:strokeColor
                                             andTs:strokeStartValue
                                             andTf:strokeFinishValue
                                      andBlendMode:blendMode];
        [strokes addObject:stroke];
    }

    return strokes;
}
```

### Step 7: Draw the decoded strokes

Create a method to draw the strokes array to the screen using the following code:

```objective-c
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
```

This method creates a temporary instance of the ```WCMStrokeRenderer``` class called ```renderer```. 
The temporary instance is initialized with the size and scale factor of the view. 
For each stroke, the ```renderer``` is configured with the stroke parameters (width, color, stride, and so on). 
The stroke is then drawn and blended into the ```strokesLayer```. 
Before drawing each stroke, you must call the ```[renderer resetAndClearBuffers]``` method.

---
---
