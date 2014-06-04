//
//  DemoViewController.m
//  AUImageCache
//
//  Created by Natalia Osiecka on 03.6.2014.
//  Copyright (c) 2014 AppUnite. All rights reserved.
//

#import "DemoViewController.h"
#import "AUImageFetchController.h"

@interface DemoViewController ()

@property (nonatomic, strong) NSArray *imageUrls;

@end

/**
 1. add podspec and upload as a cocoapods
 2. upload to review
**/
static NSString *ImageCellIdentifier = @"ImageCellIdentifier";

@implementation DemoViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        NSMutableArray *tmp = [[NSMutableArray alloc] init];
        for (int i = 0; i < 20; i++) {
            NSString *urlString = [NSString stringWithFormat:@"https://dl.dropboxusercontent.com/u/35428210/testImgs/testImg_%d.jpg", i];
            
            [tmp addObject:urlString];
        }
        
        _imageUrls = [tmp copy];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[DemoTableViewCell class] forCellReuseIdentifier:ImageCellIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 300.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _imageUrls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DemoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ImageCellIdentifier forIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // keep weak reference to avoid retain cycle
    __weak typeof(DemoTableViewCell) *weakCell = (DemoTableViewCell *)cell;
    
    // reusable cells, lets nil the image
    [cell.imageView setImage:nil];
    // set url for later in-block use
    NSString *urlString = _imageUrls[indexPath.row];
    [(DemoTableViewCell *)cell setUrlString:urlString];
    
    // now run block to update image
    [[AUImageFetchController sharedDownloader] fetchImageWithURL:urlString success:^(UIImage *image, NSString *url) {
        // we need to make sure we put it in correct cell (otherwise it can get messed up during scrolling)
        if (weakCell && [weakCell.urlString isEqualToString:url]) {
            // There are 2 types of caching:
            // 1. disc you can check on device storage (Library->Caches->AUCache), please do notice 2 lines in AppDelegate to remove outdated cache after some period of time
            // 2. memory during debug (AUImageCache memoryCache)
            [weakCell.imageView setImage:image];
            // because we use standard cells, it won't appear until we relayout
            [weakCell setNeedsLayout];
        }
    } failure:^(NSError *error) {
        // this should be handled in better way - eg show 'no image' image
        NSLog(@"Failure, handle it somehow");
    }];
}

@end

@implementation DemoTableViewCell

@end
