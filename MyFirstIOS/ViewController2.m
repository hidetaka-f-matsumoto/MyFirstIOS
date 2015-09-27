//
//  ViewController2.m
//  MyFirstIOS
//
//  Created by 松本 英高 on 2015/04/16.
//  Copyright (c) 2015年 Hidetaka Matsumoto. All rights reserved.
//

#import "ViewController2.h"
#import "TableViewCell2.h"
#import "SVProgressHUD.h"

@interface ViewController2 ()
{
    NSMutableArray *_charaInfos;
}

@end

@implementation ViewController2

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    _charaInfos = [NSMutableArray array];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // キャラ情報取得API
    [self apiGetCharasWithCompletion:^(NSDictionary *response) {
        // データを更新
        _charaInfos = [response[@"charas"] mutableCopy];
        // テーブル描画更新
        [_tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _charaInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell2 *cell = [_tableView dequeueReusableCellWithIdentifier:@"charaCell"];
    NSDictionary *charaInfo = _charaInfos[indexPath.row];
    cell.charaNameLabel.text = charaInfo[@"name"];
#if 1 // メインスレッドを占有してしまう
    NSError *error = nil;
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:charaInfo[@"image_url"]] options:NSDataReadingMappedIfSafe error:&error];
    UIImage *image = [UIImage imageWithData:imageData];
    cell.charaImageView.image = image;
#else // サブスレッドで遅延ローディング
    cell.charaImageView.image = nil;
    dispatch_queue_t q_global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(q_global, ^{
        NSError *error = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:charaInfo[@"image_url"]] options:NSDataReadingMappedIfSafe error:&error];
        UIImage *image = [UIImage imageWithData:imageData];

        dispatch_queue_t q_main = dispatch_get_main_queue();
        dispatch_async(q_main, ^{
            cell.charaImageView.image = image;
        });
    });
#endif
    return cell;
}

#pragma mark - Some process

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
- (void)apiGetCharasWithCompletion:(void (^)(NSDictionary *response))callback
{
    // リクエスト作成
    NSURL *url = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/17354346/example/charas.json"];
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
