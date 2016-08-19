//
//  SGScanViewController.h
//  
//
//  Created by NetSet on 8/17/16.
//  Copyright © 2016 NetSet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LXReorderableCollectionViewFlowLayout.h"
#import "RippleAnimation.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface SGScanViewController : UIViewController<LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (strong ,nonatomic) UIImagePickerController *invokeCamera;
@property (strong ,nonatomic) NSString *scannedPDFPath;

- (IBAction)addPagesPressed:(id)sender;
- (IBAction)previewPressed:(id)sender;

@end
