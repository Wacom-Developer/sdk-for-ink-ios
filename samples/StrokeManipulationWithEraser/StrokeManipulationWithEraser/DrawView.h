//
//  DrawView.h
//  StrokeManipulationWithEraser
//
//  Created by Plamen Petkov on 12/1/14.
//
//

#import <UIKit/UIKit.h>

@protocol DrawView <NSObject>

@property NSMutableArray * strokes;

-(void) redrawStrokes;

@end
