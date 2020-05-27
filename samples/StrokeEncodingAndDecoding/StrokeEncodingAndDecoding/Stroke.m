//
//  Stroke.m
//  StrokeModelAndPersistance
//
//  Created by Plamen Petkov on 10/1/14.
//
//

#import <Foundation/Foundation.h>
#import <WILLCore/WILLCore.h>
#import "Stroke.h"

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