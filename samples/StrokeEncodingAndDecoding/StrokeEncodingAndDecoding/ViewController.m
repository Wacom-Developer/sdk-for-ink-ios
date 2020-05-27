//
//  ViewController.m
//  StrokeEncodingAndDecoding
//
//  Created by Plamen Petkov on 12/1/14.
//
//

#import <WILLCore/WILLCore.h>
#import "ViewController.h"
#import "DrawView.h"
#import "Stroke.h"

@interface ViewController ()


@end

@implementation ViewController
{
    DrawView * drawView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    drawView = [[DrawView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:drawView];
    
    [self loadStrkoes];
}

-(void) saveStrokes
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *willDocPath = [documentsPath stringByAppendingPathComponent:@"document.will"];
    
    [self saveStrokes:drawView.strokes toPath:willDocPath];
}

-(void) loadStrkoes
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *willDocPath = [documentsPath stringByAppendingPathComponent:@"document.will"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:willDocPath])
    {
        NSMutableArray * strokes =  [self decodeStrokesFromDocumentPath:willDocPath];
        drawView.strokes = strokes;
        [drawView redrawStrokes];
    }
}

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

@end
