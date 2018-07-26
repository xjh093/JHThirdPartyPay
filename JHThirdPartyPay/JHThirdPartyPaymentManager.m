//
//  JHThirdPartyPaymentManager.m
//  JHKit
//
//  Created by HaoCold on 2017/7/27.
//  Copyright © 2017年 HaoCold. All rights reserved.
//

// 支付宝状态码
// 9000    订单支付成功
// 8000    正在处理中，支付结果未知（有可能已经支付成功），请查询商户订单列表中订单的支付状态
// 4000    订单支付失败
// 5000    重复请求
// 6001    用户中途取消
// 6002    网络连接出错
// 6004    支付结果未知（有可能已经支付成功），请查询商户订单列表中订单的支付状态
// 其它     其它支付错误

// 微信状态码
// WXSuccess           = 0,    /**< 成功    */
// WXErrCodeCommon     = -1,   /**< 普通错误类型    */
// WXErrCodeUserCancel = -2,   /**< 用户点击取消并返回    */
// WXErrCodeSentFail   = -3,   /**< 发送失败    */
// WXErrCodeAuthDeny   = -4,   /**< 授权失败    */
// WXErrCodeUnsupport  = -5,   /**< 微信不支持    */

NSString *JHThirdPartyPaymentManagerPayStatusKey = @"JHThirdPartyPaymentManagerPayStatusKey";
NSString *JHThirdPartyPaymentManagerPayOrderKey = @"JHThirdPartyPaymentManagerPayOrderKey";

#import "JHThirdPartyPaymentManager.h"

@interface JHThirdPartyPaymentManager()
@property (nonatomic,    copy) JHPayCallback callback;
@end

@implementation JHThirdPartyPaymentManager

+ (instancetype)manager{
    static JHThirdPartyPaymentManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[JHThirdPartyPaymentManager alloc] init];
    });
    return manager;
}

- (void)jh_savePayStatus:(NSString *)order{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:JHThirdPartyPaymentManagerPayStatusKey];
    if (order) {
        [[NSUserDefaults standardUserDefaults] setObject:order forKey:JHThirdPartyPaymentManagerPayOrderKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)jh_pay:(JHThirdPartyPaymentManagerType)payType order:(id)obj callback:(JHPayCallback)callback{
    _callback = callback;
    [self xx_addNotification];
    if (payType == JHThirdPartyPaymentManagerType_Ali) {
        [self xx_alipay:(NSDictionary *)obj];
    }else if (payType == JHThirdPartyPaymentManagerType_WX){
        [self xx_wxpay:(NSDictionary *)obj];
    }
}

- (void)xx_alipay:(NSDictionary *)order{
    _aliPayCode = -1000;
#if kJHImport
    __weak typeof(self) weakself = self;
    [[AlipaySDK defaultService] payOrder:order[@"alipay"] fromScheme:@"com.redbird.QuBar" callback:^(NSDictionary *resultDic) {
        NSLog(@"xx web resultDic:%@",resultDic);
        weakself.aliPayCode = [resultDic[@"resultStatus"] integerValue];
        [weakself xx_checkPayStatus];
    }];
#endif
}

- (void)xx_wxpay:(NSDictionary *)dic{
    _wxPayCode = -1000;
    NSData *data = [dic[@"data"] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *xdic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if (xdic) {
        
#if kJHImport
        PayReq *req   = [[PayReq alloc] init];
        req.openID    = xdic[@"appid"];
        req.partnerId = xdic[@"partnerid"];
        req.prepayId  = xdic[@"prepayid"];
        req.nonceStr  = xdic[@"noncestr"];
        req.timeStamp = [xdic[@"timestamp"] intValue];
        req.package   = xdic[@"package"];
        req.sign      = xdic[@"sign"];
        
        [WXApi sendReq:req];
#endif
    }else{
        if (_callback) {
            _callback(@"微信支付订单信息有误~");
        }
    }
}

- (void)xx_addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xx_checkPayStatus) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)xx_removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)xx_checkPayStatus{
    // UIApplicationWillEnterForegroundNotification 比 支付宝 微信 SDK回调 快
    // 这里做一下延迟
    BOOL status = [[NSUserDefaults standardUserDefaults] boolForKey:JHThirdPartyPaymentManagerPayStatusKey];
    NSString *order = [[[NSUserDefaults standardUserDefaults] objectForKey:JHThirdPartyPaymentManagerPayOrderKey] copy];
    if (status && order.length > 0) {
        if (_callback) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                _callback(order);
                [self xx_removePayStatus];
                [self xx_removeNotification];
            });
        }
    }
}

- (void)xx_removePayStatus{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:JHThirdPartyPaymentManagerPayStatusKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:JHThirdPartyPaymentManagerPayOrderKey];
}

#if kJHImport
#pragma mark - WXApiDelegate
- (void)onResp:(BaseResp*)resp
{
    _wxPayCode = resp.errCode;
}
#endif

@end
