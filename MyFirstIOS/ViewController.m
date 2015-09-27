//
//  ViewController.m
//  MyFirstIOS
//
//  Created by 松本 英高 on 2015/04/15.
//  Copyright (c) 2015年 Hidetaka Matsumoto. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)_init {
    _charaNameLabel.text = nil;
    _charaDetailTextView.text = nil;
    _charaImageView.image = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self _init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // キャラ情報取得API
    [self apiGetCharaWithCompletion:^(NSDictionary *response) {
        // 取得した情報をviewに反映
        NSError *error = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:response[@"image_url"]] options:NSDataReadingMappedIfSafe error:&error];
        UIImage *image = [UIImage imageWithData:imageData];
        
        _charaNameLabel.text = response[@"name"];
        _charaDetailTextView.text = response[@"detail"];
        _charaImageView.image = image;
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * ローディング表示on
 */
- (void)showLoading
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:@"Loading..."];
}

/**
 * ローディング表示off
 */
- (void)hideLoading
{
    [SVProgressHUD dismiss];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

/**
 * エラーダイアログ表示
 */
- (void)showErrorDialog {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"エラーだよ"
                                 preferredStyle:UIAlertControllerStyleAlert];
    // OK処理
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    // ダイアログを表示
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

/**
 * キャラ情報取得API
 */
- (void)apiGetCharaWithCompletion:(void (^)(NSDictionary *response))callback
{
    // リクエスト作成
    NSURL *url = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/17354346/example/chara.json"];
    // セッション作成
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    // セッションタスク作成
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // 通信エラー
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 通信中表示off
                [self hideLoading];
                // エラーダイアログ表示
                [self showErrorDialog];
            });
            return;
        }
        // レスポンスをパース
        NSError *error2;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error2];
        // パースエラー
        if (error2) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 通信中表示off
                [self hideLoading];
                // エラー表示
                [self showErrorDialog];
            });
            return;
        }
        // 正常処理
        dispatch_async(dispatch_get_main_queue(), ^{
            // 通信中表示off
            [self hideLoading];
            // コールバック実行
            callback(dict);
        });
    }];
    // 通信中表示on
    [self showLoading];
    // セッションタスク開始
    [task resume];
}

@end
