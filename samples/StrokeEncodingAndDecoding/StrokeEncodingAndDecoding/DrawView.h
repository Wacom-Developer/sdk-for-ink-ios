//
//  DrawView.h
//  StrokeModelAndPersistance
//
//  Created by Plamen Petkov on 10/1/14.
//
//

#import <UIKit/UIKit.h>
#import <WILLCore/WILLCore.h>

@interface DrawView : UIView


@property NSMutableArray * strokes;

-(void) redrawStrokes;

@end
