//
//  ViewController.m
//  web长按保存图片
//
//  Created by kezhiyou on 16/7/15.
//  Copyright © 2016年 daijuqing. All rights reserved.
//

#import "ViewController.h"
static NSString* const kTouchJavaScriptString=
@"document.ontouchstart=function(event){\
x=event.targetTouches[0].clientX;\
y=event.targetTouches[0].clientY;\
document.location=\"myweb:touch:start:\"+x+\":\"+y;};\
document.ontouchmove=function(event){\
x=event.targetTouches[0].clientX;\
y=event.targetTouches[0].clientY;\
document.location=\"myweb:touch:move:\"+x+\":\"+y;};\
document.ontouchcancel=function(event){\
document.location=\"myweb:touch:cancel\";};\
document.ontouchend=function(event){\
document.location=\"myweb:touch:end\";};";

@interface ViewController ()<UIWebViewDelegate,UIActionSheetDelegate>

{
    UIWebView *_webView;
    NSTimer *_timer;
    NSInteger _gesState;
    NSString *_imgURL;
}

@end

@implementation ViewController
typedef NS_ENUM(NSInteger, GESTURE_STATE) { GESTURE_STATE_START, GESTURE_STATE_MOVE, GESTURE_STATE_END};

- (void)viewDidLoad {
    [super viewDidLoad];

    [self loadWebView];
}

- (void)loadWebView{
    _webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
    _webView.delegate  =self;
    
    NSURL *url = [NSURL URLWithString:@"http://m.baidu.com"];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    [_webView loadRequest:request];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)_request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *requestString = [[_request URL] absoluteString];
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    if ([components count] > 1 && [(NSString *)[components objectAtIndex:0] isEqualToString:@"myweb"])
    {
        
        if([(NSString *)[components objectAtIndex:1] isEqualToString:@"touch"])
        {
            
            if ([(NSString *)[components objectAtIndex:2] isEqualToString:@"start"])
            {
                /*
                 @需延时判断是否响应页面内的js...
                 */
                _gesState = GESTURE_STATE_START;
                NSLog(@"touch start!");
                
                float ptX = [[components objectAtIndex:3]floatValue];
                float ptY = [[components objectAtIndex:4]floatValue];
                NSLog(@"touch point (%f, %f)", ptX, ptY);
                
                NSString *js = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).tagName", ptX, ptY];
                NSString * tagName = [_webView stringByEvaluatingJavaScriptFromString:js];
                _imgURL = nil;
                if ([tagName isEqualToString:@"IMG"])
                {
                    _imgURL = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", ptX, ptY];
                }
                if (_imgURL)
                {
                    _timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(handleLongTouch) userInfo:nil repeats:NO];
                }
            }
            else if ([(NSString *)[components objectAtIndex:2] isEqualToString:@"move"])
            {
                //**如果touch动作是滑动，则取消hanleLongTouch动作**//
                _gesState = GESTURE_STATE_MOVE;
                NSLog(@"you are move");
            }
        }
        else if ([(NSString*)[components objectAtIndex:2]isEqualToString:@"end"])
        {
            [_timer invalidate];
            _timer = nil;
            _gesState = GESTURE_STATE_END;
            NSLog(@"touch end");
        }
        
        return NO;
    }
    
    
    return YES;
}
- (void)handleLongTouch {
    NSLog(@"%@", _imgURL);
    if (_imgURL && _gesState == GESTURE_STATE_START) {
        UIActionSheet* sheet =[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"保存图片", nil];
        sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
        [sheet showInView:[UIApplication sharedApplication].keyWindow];
    }
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.numberOfButtons - 1 == buttonIndex) {
        return;
    }
    NSString* title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"保存图片"]) {
        if (_imgURL) {
            NSLog(@"imgurl = %@", _imgURL);
        }
        NSString *urlToSave = [_webView stringByEvaluatingJavaScriptFromString:_imgURL];
        NSLog(@"image url=%@", urlToSave);
        
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlToSave]];
        UIImage* image = [UIImage imageWithData:data];
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
    if (error){
        NSLog(@"Error");
        //        [self showAlert:SNS_IMAGE_HINT_SAVE_FAILE];
    }else {
        NSLog(@"OK");
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"提醒" message:@"保存成功!" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [_webView stringByEvaluatingJavaScriptFromString:kTouchJavaScriptString];
}

@end
