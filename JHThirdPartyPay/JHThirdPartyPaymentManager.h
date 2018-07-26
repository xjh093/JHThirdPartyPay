//
//  JHThirdPartyPaymentManager.h
//  JHKit
//
//  Created by HaoCold on 2017/7/27.
//  Copyright © 2017年 HaoCold. All rights reserved.
//  支付宝与微信支付

#import <Foundation/Foundation.h>

#define kJHImport 0

#if kJHImport
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>
#endif

/**<
 点击屏幕左上角的快捷返回按钮，不会触发第三方支付的回调
 
 所以在支付完成后
 向后台请求该订单支付状态
 
 */

extern NSString *JHThirdPartyPaymentManagerPayStatusKey;
extern NSString *JHThirdPartyPaymentManagerPayOrderKey;

typedef NS_ENUM(NSUInteger,JHThirdPartyPaymentManagerType) {
    JHThirdPartyPaymentManagerType_Ali, //支付宝
    JHThirdPartyPaymentManagerType_WX   //微信
};

typedef void(^JHPayCallback)(NSString *order);

@interface JHThirdPartyPaymentManager : NSObject
#if kJHImport
<WXApiDelegate>
#endif

/// success - 9000, cancel - 6001
@property (nonatomic,  assign) NSInteger  aliPayCode; // 支付宝支付状态码，9000
/// success - 0, cancel - -2
@property (nonatomic,  assign) NSInteger  wxPayCode;  // 微信支付状态码，0表示成功

+ (instancetype)manager;

/// Call thid method before pay.
- (void)jh_savePayStatus:(NSString *)order;

/// Pay with order information, after callback will remove pay status.
- (void)jh_pay:(JHThirdPartyPaymentManagerType)payType
         order:(id)obj
      callback:(JHPayCallback)callback;

@end

/**< AppDelegate.m
 
 // iOS 2.0 ~ 9.0
 - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [self xjh_handleURL:url];
    return YES;
 }
 
 //  >= iOS 9.0
 - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    [self xjh_handleURL:url];
    return YES;
 }
 
 - (void)xjh_handleURL:(NSURL *)url{
    BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url];
    if (!result) { // 微信的回调
        result = [WXApi handleOpenURL:url delegate:[JHThirdPartyPaymentManager manager]];
    }
    if (!result && [url.host isEqualToString:@"safepay"]) { // 支付宝的回调
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"xx result = %@",resultDic);
            [JHThirdPartyPaymentManager manager].aliPayCode = [resultDic[@"resultStatus"] integerValue];
             // {
             // extendInfo =     {
             // };
             // memo = "\U7528\U6237\U4e2d\U9014\U53d6\U6d88";
             // result = "";
             // resultStatus = 6001;
             // }
        }];
    }
 }
 
 */
