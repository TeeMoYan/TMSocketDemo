//
//  ViewController.m
//  TMSocketTest
//
//  Created by 闫振 on 2018/12/19.
//  Copyright © 2018年 TeeMo. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>


#define SocketPort htons(12346)
#define SocketIP   inet_addr("127.0.0.1")
static int const kMaxConnectCount = 5;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *mTextField;
@property (weak, nonatomic) IBOutlet UITextView *mTextView;
@property (nonatomic, assign) int mSocketId;
@property (nonatomic,strong)NSString *mDateStr;
@property (nonatomic, strong) NSMutableAttributedString *totalAttributeStr;
@property (nonatomic, assign) int mClientSocket;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.mTextView.userInteractionEnabled = NO;
    self.totalAttributeStr = [[NSMutableAttributedString alloc] init];
    
}
- (IBAction)connectSocket:(UIButton *)sender {
    
    [self connectSocket];
}

- (IBAction)breakSocket:(UIButton *)sender {
   
    if (self.mClientSocket) {
        close(self.mClientSocket);
        NSLog(@"=========关闭Socket=========");
    }
  
}

- (IBAction)sendMessage:(UIButton *)sender {
    /**
     3: 发送消息
     s：一个用于标识已连接套接口的描述字。
     buf：包含待发送数据的缓冲区。
     len：缓冲区中数据的长度。
     flags：调用执行方式。
     
     返回值
     如果成功，则返回发送的字节数，失败则返回SOCKET_ERROR
     一个中文对应 3 个字节！UTF8 编码！
     */
    if (self.mTextField.text.length == 0) {
        NSLog(@"=========不能发送空消息=========");
        return;
    }
    NSString *send_str = self.mTextField.text;
    const char *send_msg = send_str.UTF8String;
    ssize_t send_length = send(self.mClientSocket, send_msg, strlen(send_msg), 0);
    NSLog(@"发送了========%ld字节==========",send_length);
    if (send_length <= 0) {
        return;
    }
    [self showMessage:send_str msgType:0];
    self.mTextField.text = @"";
    
}
/**
 1: 创建socket
 参数
 domain：协议域，又称协议族（family）。常用的协议族有AF_INET、AF_INET6、AF_LOCAL（或称AF_UNIX，Unix域Socket）、AF_ROUTE等。协议族决定了socket的地址类型，在通信中必须采用对应的地址，如AF_INET决定了要用ipv4地址（32位的）与端口号（16位的）的组合、AF_UNIX决定了要用一个绝对路径名作为地址。
 type：指定Socket类型。常用的socket类型有SOCK_STREAM、SOCK_DGRAM、SOCK_RAW、SOCK_PACKET、SOCK_SEQPACKET等。流式Socket（SOCK_STREAM）是一种面向连接的Socket，针对于面向连接的TCP服务应用。数据报式Socket（SOCK_DGRAM）是一种无连接的Socket，对应于无连接的UDP服务应用。
 protocol：指定协议。常用协议有IPPROTO_TCP、IPPROTO_UDP、IPPROTO_STCP、IPPROTO_TIPC等，分别对应TCP传输协议、UDP传输协议、STCP传输协议、TIPC传输协议。
 注意：1.type和protocol不可以随意组合，如SOCK_STREAM不可以跟IPPROTO_UDP组合。当第三个参数为0时，会自动选择第二个参数类型对应的默认协议。
 返回值:
 如果调用成功就返回新创建的套接字的描述符，如果失败就返回INVALID_SOCKET（Linux下失败返回-1）
 */
- (void)connectSocket{
    //1.创建socket
    self.mSocketId = socket(AF_INET, SOCK_STREAM, 0);
    if (self.mSocketId == -1) {
        NSLog(@"=========创建失败=========");
        return;
    }
    //2.绑定socket
    /**
     参数
     参数一：套接字描述符
     参数二：指向数据结构sockaddr的指针，其中包括目的端口和IP地址
     参数三：参数二sockaddr的长度，可以通过sizeof（struct sockaddr）获得
     返回值
     成功则返回0，失败返回非0，错误码GetLastError()。
     */
    //    struct sockaddr_in {
    //        __uint8_t    sin_len;
    //        sa_family_t    sin_family;
    //        in_port_t    sin_port;
    //        struct    in_addr sin_addr;
    //        char        sin_zero[8];
    //    };
    
    struct sockaddr_in      socket_add;
    socket_add.sin_port   = SocketPort;
    socket_add.sin_family = AF_INET;
    
    struct in_addr        socket_idAdd;
    socket_idAdd.s_addr   = SocketIP;
    
    socket_add.sin_addr = socket_idAdd;
    bzero(&(socket_add.sin_zero), 8);

    
    int bind_result = bind(self.mSocketId, (const struct sockaddr *)&socket_add, sizeof(socket_add));

    
    if (bind_result == -1) {
        NSLog(@"=========绑定失败=========");
        return;
    }else{
        NSLog(@"=========绑定成功=========");
    }
   //3.监听Socket
    
    int listen_result =  listen(self.mSocketId, kMaxConnectCount);
    if (listen_result == -1) {
        NSLog(@"=========监听失败=========");
        return;
    }else{
        NSLog(@"=========监听成功=========");
    }
    //接收客户端连接
    for (int i = 0; i < kMaxConnectCount; i++) {
        [self acceptClientConnect];
    }
  
    
    
}
//4.接收数据
- (void)acceptClientConnect{
    /**
     参数
     1> 客户端socket
     2> 接收内容缓冲区地址
     3> 接收内容缓存区长度
     4> 接收方式，0表示阻塞，必须等待服务器返回数据
     返回值
     如果成功，则返回读入的字节数，失败则返回SOCKET_ERROR -1
     */
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        struct sockaddr_in client_addr;
        socklen_t addr_length;
        self.mClientSocket =  accept(self.mSocketId, (struct sockaddr *)&client_addr, &addr_length);
        
        if (self.mClientSocket == -1) {
            NSLog(@"==========接收客户端错误===========");
        }else{
            NSString *str = [NSString stringWithFormat:@"客户端socket:%d",self.mClientSocket];
            NSLog(@"===========%@=========",str);
            [self receiveMsgWithClietnSocket:self.mClientSocket];
        }
        
    });
        

}
- (void)receiveMsgWithClietnSocket:(int)clientSocket{
    while (1) {
        // 5: 接受客户端传来的数据
        char buf[1024] = {0};
        long iReturn = recv(clientSocket, buf, 1024, 0);
        if (iReturn>0) {
            NSLog(@"客户端来消息了");
            // 接收到的数据转换
            NSData *recvData  = [NSData dataWithBytes:buf length:iReturn];
            NSString *recvStr = [[NSString alloc] initWithData:recvData encoding:NSUTF8StringEncoding];
            NSLog(@"%@",recvStr);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self showMessage:recvStr msgType:1];

            });

            
        }else if (iReturn == -1){
            NSLog(@"读取消息失败");
            break;
        }else if (iReturn == 0){
            NSLog(@"客户端走了");
            
            close(clientSocket);
            
            break;
        }
    }
    
}
- (void)showMessage:(NSString *)msg msgType:(int)msgType{
    
    // 时间处理
    NSString *showTimeStr = [self getCurrentTime];
    if (showTimeStr) {
        NSMutableAttributedString *dateAttributedString = [[NSMutableAttributedString alloc] initWithString:showTimeStr];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        [dateAttributedString addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13],NSForegroundColorAttributeName:[UIColor blackColor],NSParagraphStyleAttributeName:paragraphStyle} range:NSMakeRange(0, showTimeStr.length)];
        [self.totalAttributeStr appendAttributedString:dateAttributedString];
        [self.totalAttributeStr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.headIndent = 20.f;
    NSMutableAttributedString *attributedString;
    if (msgType == 0) { // 我发送的
        attributedString = [[NSMutableAttributedString alloc] initWithString:msg];
        
        paragraphStyle.alignment = NSTextAlignmentRight;
        [attributedString addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15],NSForegroundColorAttributeName:[UIColor blueColor],NSParagraphStyleAttributeName:paragraphStyle}range:NSMakeRange(0, msg.length)];
    }else{
//        msg = [msg substringToIndex:msg.length-1];
        attributedString = [[NSMutableAttributedString alloc] initWithString:msg];
        
        [attributedString addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15],NSForegroundColorAttributeName:[UIColor blackColor],NSParagraphStyleAttributeName:paragraphStyle } range:NSMakeRange(0, msg.length)];
    }
    [self.totalAttributeStr appendAttributedString:attributedString];
    [self.totalAttributeStr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
    self.mTextView.attributedText = self.totalAttributeStr;
    
    
}

- (NSString *)getCurrentTime{
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateStr = [dateFormatter stringFromDate:date];
    if (!self.mDateStr || self.mDateStr.length == 0) {
        self.mDateStr = dateStr;
        return dateStr;
    }
    NSDate *recoderDate = [dateFormatter dateFromString:self.mDateStr];
    self.mDateStr = dateStr;
    NSTimeInterval timeInter = [date timeIntervalSinceDate:recoderDate];
    NSLog(@"%@--%@ -- %f",date,recoderDate,timeInter);
    if (timeInter<6) {
        return @"";
    }
    return dateStr;
}
@end
