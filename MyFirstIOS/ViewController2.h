//
//  ViewController2.h
//  MyFirstIOS
//
//  Created by 松本 英高 on 2015/04/16.
//  Copyright (c) 2015年 Hidetaka Matsumoto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController2 : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
