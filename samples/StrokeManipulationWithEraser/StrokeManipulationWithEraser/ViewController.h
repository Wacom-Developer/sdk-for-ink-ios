//
//  ViewController.h
//  StrokeManipulationWithEraser
//
//  Created by Plamen Petkov on 12/1/14.
//
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (IBAction) partButtonPressed:(id)sender;

- (IBAction) back:(id)sender;

@property (nonatomic) IBOutlet UIButton *backButton;

@end

