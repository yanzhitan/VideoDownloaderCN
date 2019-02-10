#pragma mark - 微博

#import <UIKit/UIKit.h>
#import "lib/DownloaderManager/DownloaderManager.h"
#import "lib/MBProgressHUD/MBProgressHUD.h"

@interface WBVideoItem : NSObject
@property(readonly, copy, nonatomic) NSURL *urlHD;
@end

@interface WBStatus : NSObject
@property(readonly, nonatomic) WBVideoItem *vt_videoItem;
@property(readonly, nonatomic) id retweetByStatus;
@property(readonly, nonatomic) id pageInfo;
@end

@interface WBPageCardStatus : WBStatus
@end

@interface WBVideoTimelineTableViewCell : NSObject
@property(retain, nonatomic) WBStatus *status;
@end

@interface WBVideoTimelineViewController
@property(readonly, nonatomic) WBVideoTimelineTableViewCell *playingCell;
@end

@interface WBVideoContainerView : UIView <DownloaderManagerDelegeate>
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

- (void)downloadVideo;
@end

@interface WBTimelinePageInfo : NSObject
@property(readonly, nonatomic) id videoItem;
@end

@interface WBVideoModel : WBVideoItem
@end

%hook WBVideoContainerView

- (void)setFrame:(struct CGRect)arg1 {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self addGestureRecognizer:longPress];
    %orig;
}

%new
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    //解决手势触发两次
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"VideoDownloaderCN" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
        UIAlertAction *dAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self downloadVideo];
        }];

        UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertVC addAction:dAction];
        [alertVC addAction:cAction];

        //寻找当前vc
        id vc = [self nextResponder];
        while (vc) {
            if ([vc isKindOfClass:%c(UIViewController)])   
            {
                break;
            }else vc = [vc nextResponder];
        }
        if ([vc isKindOfClass:%c(UIViewController)]) {
            vc = (UIViewController *)vc;
            [vc presentViewController:alertVC animated:YES completion:nil];
        }
    }
}

%new
- (void)downloadVideo {
    NSURL *url = nil;
    /**
     第一种情况，点开视频长按下载
     */
    id wbTimeLineVC = [[[[[[[self nextResponder]nextResponder]nextResponder]nextResponder]nextResponder]nextResponder]nextResponder];
    if ([wbTimeLineVC isKindOfClass:%c(WBVideoTimelineViewController)]) {
        //取出当前视频的cell
        WBVideoTimelineTableViewCell *playingCell = [wbTimeLineVC playingCell];
        if ([playingCell isKindOfClass:%c(WBVideoTimelineTableViewCell)]) {
            //每个WBstatus记录着视频的信息
            WBStatus *status = [playingCell status];
            if ([status isKindOfClass:%c(WBPageCardStatus)]) {
                //检查是否转发的视频
                WBTimelinePageInfo *pageInfo = nil;
                WBPageCardStatus *retweetByStatus = [status retweetByStatus];
                if ([retweetByStatus isKindOfClass:%c(WBPageCardStatus)]) {
                    pageInfo = [retweetByStatus pageInfo];
                }else {
                    pageInfo = [status pageInfo];
                }
                if ([pageInfo isKindOfClass:%c(WBTimelinePageInfo)]) {
                    WBVideoModel *videoItem = [pageInfo videoItem];
                    if ([videoItem isKindOfClass:%c(WBVideoItem)]) {
                        url = [videoItem urlHD];
                    }
                }
            } else if ([status isKindOfClass:%c(WBStatus)]) {
                WBVideoItem *vt_videoItem = [status vt_videoItem];
                if ([vt_videoItem isKindOfClass:%c(WBVideoItem)]) {
                    url = [vt_videoItem urlHD];             
                }else {
                    WBStatus *retweetByStatus = [status retweetByStatus];
                    WBTimelinePageInfo *pageInfo = [retweetByStatus pageInfo];
                    if ([pageInfo isKindOfClass:%c(WBTimelinePageInfo)]) {
                    WBVideoModel *videoItem = [pageInfo videoItem];
                    if ([videoItem isKindOfClass:%c(WBVideoItem)]) {
                        url = [videoItem urlHD];
                    }
                }
                }
            }
        }
    }
    
    /**
     第二种情况，未点开视频，长按下载
     */
    //2.1转发情况
    id wbTimelineLargeCardViewRetweet = [[[self nextResponder]nextResponder]nextResponder];
    //2.2非转发情况
    id wbTimelineLargeCardViewSelf = [[self nextResponder]nextResponder];
    
    id wbTimelineLargeCardView = nil;
    if ([wbTimelineLargeCardViewRetweet isKindOfClass:%c(WBTimelineLargeCardView)]) {
        wbTimelineLargeCardView = wbTimelineLargeCardViewRetweet;
    }else if ([wbTimelineLargeCardViewSelf isKindOfClass:%c(WBTimelineLargeCardView)]) {
        wbTimelineLargeCardView = wbTimelineLargeCardViewSelf;
    }

    if (wbTimelineLargeCardView) {
        WBTimelinePageInfo *pageInfo = [wbTimelineLargeCardView pageInfo];
        if ([pageInfo isKindOfClass:%c(WBTimelinePageInfo)]) {
            WBVideoModel *videoItem = [pageInfo videoItem];
            if ([videoItem isKindOfClass:%c(WBVideoItem)]) {
                url = [videoItem urlHD];
            }
        }
    }
    
    /**
     第三种情况，视屏全屏播放界面
     */
    id wbVideoPlayerViewController = [[self nextResponder]nextResponder];
    if ([wbVideoPlayerViewController isKindOfClass:%c(WBVideoPlayerViewController)]) {
        WBVideoItem *videoItem = [wbVideoPlayerViewController videoItem];
        if ([videoItem isKindOfClass:%c(WBVideoItem)]) {
            url = [videoItem urlHD];
        }
    }
    
    /**
     第四种情况，首页"视频"标签入口
     */
    id wbPageVideoPlaylistCardLargeVideoView = [self nextResponder];
    if ([wbPageVideoPlaylistCardLargeVideoView isKindOfClass:%c(WBPageVideoPlaylistCardLargeVideoView)]) {
        WBTimelinePageInfo *pageInfo = [wbPageVideoPlaylistCardLargeVideoView pageInfo];
        if ([pageInfo isKindOfClass:%c(WBTimelinePageInfo)]) {
            WBVideoModel *videoItem = [pageInfo videoItem];
            if ([videoItem isKindOfClass:%c(WBVideoModel)]) {
                url = [videoItem urlHD];
            }
        }
    }
    
    id wbVideoSocialPlayerViewController = [[[self nextResponder] nextResponder] nextResponder];
    if ([wbVideoSocialPlayerViewController isKindOfClass:%c(WBVideoSocialPlayerViewController)]) {
        WBVideoItem *_currentVideoItem = MSHookIvar<WBVideoItem *>(wbVideoSocialPlayerViewController, "_currentVideoItem");
        if ([_currentVideoItem isKindOfClass:%c(WBVideoItem)]) {
            url = [_currentVideoItem urlHD]; 
        }
    }
    
    /**
     拿到视频url下载
     */
    if (url)
    {
        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
        downloadManager.delegate = self;
        [downloadManager downloadVideoWithURL:url];
    }
 }

static BOOL isShow = NO;
static MBProgressHUD *hud = nil;
%new
- (void)videoDownloadeProgress:(float)progress downloadTask:(NSURLSessionDownloadTask * _Nullable)downloadTask {
    if (!isShow)
    {
        hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.label.text = NSLocalizedString(@"Donwloading...", @"HUD loading title");
        NSProgress *progressObject = [NSProgress progressWithTotalUnitCount:100];
        hud.progressObject = progressObject;
        [hud.button setTitle:NSLocalizedString(@"cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        [hud.button addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, @selector(weiBoDownloadTask),
                         downloadTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        isShow = YES;
    }
    hud.progressObject.completedUnitCount = [@(progress * 100)  intValue] ;
    hud.detailsLabel.text = [NSString stringWithFormat:@"%lld%%",hud.progressObject.completedUnitCount];
    if (hud.progressObject.fractionCompleted >= 1.f)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            hud = nil;
            isShow = NO;
        });
    }
}

%new
- (void)cancel {
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(weiBoDownloadTask));
    [downloadTask cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        hud = nil;
        isShow = NO;
    });
}

%new
- (void)videoDidFinishDownloaded:(NSString * _Nonnull)filePath {
    //保存到系统相册
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

%new
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Save Failed!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        hud.mode = MBProgressHUDModeCustomView;
        NSString *recPath = @"/Library/Application Support/VideoDownloaderCN/";
        NSString *imagePath = [recPath stringByAppendingPathComponent:@"Checkmark.png"];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        hud.customView = [[UIImageView alloc] initWithImage:image];
        hud.square = YES;
        hud.label.text = NSLocalizedString(@"Done", @"HUD done title");
        [hud hideAnimated:YES afterDelay:2.f];
    }
    //移除沙盒的缓存文件
    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    
}

%end

/**
 插件开关
 */
static BOOL weiboEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    weiboEnable = [settings objectForKey:@"weiboEnable"] ? [[settings objectForKey:@"weiboEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (weiboEnable)
    {
        %init(_ungrouped);
    }
    
}
