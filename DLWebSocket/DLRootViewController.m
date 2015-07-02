//
//  DLRootViewController.m
//  DLWebSocket
//
//  Created by JamesKobe on 15/6/30.
//  Copyright (c) 2015年 杨德龙. All rights reserved.
/*
       说明:  在移动端实现webSocket 大部分的原生的实现方法是用原生的方法去模拟
              webSocket请求 毕竟webSocket 原本是用于web端的比如 特殊的请求头 服务端只接受 web端的格式的请求和连接
              发送的数据和得到的数据都要按照服务端要求的格式来进行处理 而且webSocket协议本身就有很多个版本每个版本的
              要求不尽相同经典的SocketRocket也是用这样的方式来处理的。但是我们的方案是真正的Websocket并不是模拟的
              不需要去考虑这些数据打包和收到数据的复杂的处理不需要考虑webSocket的版本。因为apple提供的UIWebView本身
              可以执行JS代码帮我们去实现WebSocket。并且通过JS将后台推送的消息返回给我们这里用到了一个很好的第三方控件
              WebViewJavascriptBridge,这个类专门用于OC和JS交互,WebViewJavascriptBridge.js.txt也要根据项目做
              相应的更改。笔者在项目中成功应用。
    Introduction:  we use UIWebview to execute Javascript code to link webSocket Server . to send data to
                   Server or received data from Server by WebViewJavascriptBridge.
                   this kind of solution is not suitable for every project. you have to change a little 
                   bit to match your project
              
    注意事项: 1.0 收到服务端推送消息的格式和发送给服务端的格式 每个项目可能不同
             2.0 每次连接webSocket 之前 都要把之前的先断开不然会报错
    Attentions: 1.0 everyServer supported data formate is different so you need to change a little bit
                    in SocketWebView.html  
                 2.0 before you connect webSocket you  need to disconnect the old one
 */

#import "DLRootViewController.h"
#import "WebViewJavascriptBridge.h"

#define HOST    @"xxx.xxx.xx.x"   //  例如@"192.168.12.3"  "ws.xxxx.com" 注意不要 http打头 因为在JS 中会加上
#define PORT    @"xxx"                  //  例如@"851"

@interface DLRootViewController ()<UIWebViewDelegate>

@property (strong, nonatomic)UIWebView *webView;

@property WebViewJavascriptBridge* bridge;  // OC和JS 交互的类


@property (weak, nonatomic) IBOutlet UITextField *urlTextField;

@property (weak, nonatomic) IBOutlet UITextField *portTextField;


@property (weak, nonatomic) IBOutlet UITextField *tokenTextField;


@property (weak, nonatomic) IBOutlet UIButton *loginBtn;


- (IBAction)onLoginBtnClicked:(id)sender;


@property (weak, nonatomic) IBOutlet UITextView *msgTextView;



@end

@implementation DLRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   // [self webServiceConnectHost:HOST onPort:PORT withToken:@"123456"];
    
}

#pragma mark ----
#pragma mark ----   DLWebSocket Method
- (void)webServiceConnectHost:(NSString *)host onPort:(NSString *)port  withToken:(NSString *)token
{
    if (_bridge)
    {
        return;
    }
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"SocketWebView" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    
    if (self.webView==nil)
    {
        self.webView=[[UIWebView alloc]initWithFrame:CGRectMake(-100, -100, 100, 100)];
        [self.view addSubview:self.webView];
        
        __weak typeof (self) weakSelf=self;
        [WebViewJavascriptBridge enableLogging];
        _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback)
        {
            NSLog(@"received webSocket data  : %@", data);
            [weakSelf webServiceDidReceivedPushedMessage:data];  // 收到服务端推送的消息时的回调方法
            
        }];
        [self.webView loadHTMLString:appHtml baseURL:baseURL];
        
        /* 
           这里 模拟 发一个包含 指定的主机地址  指定的端口号  和授权码 的消息给服务端
           在SocketWebView.html中的 JS 在收到 这个特定的消息的时用得到的 token 登录主机地址和特定的端口号
           建立起真正的webSocket连接 每个服务端可能不同需要对SocketWebView中的JS做相应的修改
         */
        NSString *message = [NSString stringWithFormat:@"{\"c\":10000,\"host\":\"%@\",\"port\":\"%@\",\"token\":\"%@\"}",host,port,token];
        
        [_bridge send:message responseCallback:^(id response)
        {
            NSLog(@"sendMessage got response: %@", response);
        }];
    }
    

}

- (void)webServiceDidReceivedPushedMessage:(id)message
{
    NSLog(@"handle data");
    self.msgTextView.text=[message description];
    
}

- (void)webServiceDisConnect
{
    if (self.webView)
    {
        [self.webView removeFromSuperview];
        self.webView=nil;
        
    }
}


- (IBAction)onLoginBtnClicked:(id)sender
{
    [self webServiceConnectHost:self.urlTextField.text onPort:self.portTextField.text withToken:self.tokenTextField.text];
    
}


@end
