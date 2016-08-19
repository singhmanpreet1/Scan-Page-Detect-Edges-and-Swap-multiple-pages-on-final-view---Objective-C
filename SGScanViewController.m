//
//  SGScanViewController.m
//  
//
//  Created by NetSet on 8/17/16.
//  Copyright © 2016 NetSet. All rights reserved.
//

#import "SGScanViewController.h"
#import "PlayingCard.h"
#import "PlayingCardCell.h"
#import "MMCameraPickerController.h"
#import "CropViewController.h"
#define backgroundHex @"2196f3"
#import "UIColor+HexRepresentation.h"
#import "UIImage+fixOrientation.h"
#import <CoreTelephony/CoreTelephonyDefines.h>
#import "PDFImageConverter.h"
#import "AppDelegate.h"
#import "Globals.h"

// LX_LIMITED_MOVEMENT:
// 0 = Any card can move anywhere
// 1 = Only Spade/Club can move within same rank

#define LX_LIMITED_MOVEMENT 0



@interface SGScanViewController ()<MMCameraDelegate,MMCropDelegate>{
      RippleAnimation *ripple;
    MMCameraPickerController *cameraPicker;
    
    
}

@property (weak, nonatomic) IBOutlet UICollectionView *imagesCollectionView;
@property (strong, nonatomic) NSMutableArray *imagesArray;


@end

@implementation SGScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpImageBackButton];
    self.title = @"Scanned Documents";
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonAction:)];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    // Do any additional setup after loading the view.
    self.imagesArray =  [[NSMutableArray alloc]init];
    //[self.imagesCollectionView registerClass:PlayingCardCell.self forCellWithReuseIdentifier:@"PlayingCardCell"];
    cameraPicker=[self.storyboard instantiateViewControllerWithIdentifier:@"camera"];
    ripple=[[RippleAnimation alloc] init];
    cameraPicker.camdelegate=self;
    cameraPicker.transitioningDelegate=ripple;
    ripple.touchPoint = self.view.frame;
    
    [self presentViewController:cameraPicker animated:YES completion:nil];
    
    
    
}

-(void)rightBarButtonAction:(id)sender{
    
    if (_scannedPDFPath == nil) {
        NSMutableArray *pdfDataArray = [[NSMutableArray alloc]init];
        for (int i=0; i<_imagesArray.count; i++) {
            PlayingCard *playingCard = self.imagesArray[i];
            
            NSData *pdfData = [PDFImageConverter convertImageToPDF:playingCard.pickedImage];
            [pdfDataArray addObject:pdfData];
            
        }
        _scannedPDFPath = [self joinPDF:pdfDataArray];
    }
    [self performSegueWithIdentifier:@"unwindScannedPDFSegue" sender:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpImageBackButton
{
    FAKFontAwesome *backIcon = [FAKFontAwesome arrowCircleOLeftIconWithSize:25.0];
    [backIcon addAttribute:NSForegroundColorAttributeName value:RGB(255, 255, 255)];
    UIBarButtonItem *barBackButtonItem = [[UIBarButtonItem alloc] initWithImage:[backIcon imageWithSize:CGSizeMake(25.0, 25.0)] style:UIBarButtonItemStylePlain target:self action:@selector(popCurrentViewController)];
    self.navigationItem.leftBarButtonItem = barBackButtonItem;
    self.navigationItem.hidesBackButton = YES;
}

- (void)popCurrentViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSMutableArray *)constructsDeck {
    NSMutableArray *newDeck = [NSMutableArray arrayWithCapacity:52];
    
    for (NSInteger rank = 1; rank <= 13; rank++) {
        // Spade
        {
            PlayingCard *playingCard = [[PlayingCard alloc] init];
            playingCard.suit = PlayingCardSuitSpade;
            playingCard.rank = rank;
            [newDeck addObject:playingCard];
        }
        
        // Heart
        {
            PlayingCard *playingCard = [[PlayingCard alloc] init];
            playingCard.suit = PlayingCardSuitHeart;
            playingCard.rank = rank;
            [newDeck addObject:playingCard];
        }
        
        // Club
        {
            PlayingCard *playingCard = [[PlayingCard alloc] init];
            playingCard.suit = PlayingCardSuitClub;
            playingCard.rank = rank;
            [newDeck addObject:playingCard];
        }
        
        // Diamond
        {
            PlayingCard *playingCard = [[PlayingCard alloc] init];
            playingCard.suit = PlayingCardSuitDiamond;
            playingCard.rank = rank;
            [newDeck addObject:playingCard];
        }
    }
    
    return newDeck;
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)theCollectionView numberOfItemsInSection:(NSInteger)theSectionIndex {
    return self.imagesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PlayingCard *playingCard = self.imagesArray[indexPath.item];
    PlayingCardCell *playingCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PlayingCardCell" forIndexPath:indexPath];
    playingCardCell.backgroundColor = [UIColor redColor];
    playingCardCell.playingCard = playingCard;
    
    
    return playingCardCell;
}

#pragma mark - LXReorderableCollectionViewDataSource methods

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    PlayingCard *playingCard = self.imagesArray[fromIndexPath.item];
    
    [self.imagesArray removeObjectAtIndex:fromIndexPath.item];
    [self.imagesArray insertObject:playingCard atIndex:toIndexPath.item];
}
#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake((collectionView.frame.size.width/2)-20, (collectionView.frame.size.width/2)-1.5);
}


- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
#if LX_LIMITED_MOVEMENT == 1
    PlayingCard *playingCard = self.deck[indexPath.item];
    
    switch (playingCard.suit) {
        case PlayingCardSuitSpade:
        case PlayingCardSuitClub: {
            return YES;
        } break;
        default: {
            return NO;
        } break;
    }
#else
    return YES;
#endif
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
#if LX_LIMITED_MOVEMENT == 1
    PlayingCard *fromPlayingCard = self.deck[fromIndexPath.item];
    PlayingCard *toPlayingCard = self.deck[toIndexPath.item];
    
    switch (toPlayingCard.suit) {
        case PlayingCardSuitSpade:
        case PlayingCardSuitClub: {
            return fromPlayingCard.rank == toPlayingCard.rank;
        } break;
        default: {
            return NO;
        } break;
    }
#else
    return YES;
#endif
}

#pragma mark - LXReorderableCollectionViewDelegateFlowLayout methods

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"will begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"will end drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did end drag");
}

#pragma mark Picker delegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [_invokeCamera dismissViewControllerAnimated:YES completion:nil];
    [_invokeCamera removeFromParentViewController];
    ripple=nil;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [_invokeCamera dismissViewControllerAnimated:YES completion:nil];
    [_invokeCamera removeFromParentViewController];
    ripple=nil;
    
    CropViewController *crop=[self.storyboard instantiateViewControllerWithIdentifier:@"crop"];
    crop.cropdelegate=self;
    ripple=[[RippleAnimation alloc] init];
    crop.transitioningDelegate=ripple;
    ripple.touchPoint=self.view.frame;
    
    crop.adjustedImage=[info objectForKey:UIImagePickerControllerOriginalImage];
    
    
    
    [self presentViewController:crop animated:YES completion:nil];
    
    
}

#pragma mark Camera Delegate
-(void)didFinishCaptureImage:(UIImage *)capturedImage withMMCam:(MMCameraPickerController*)cropcam{
    
    [cropcam closeWithCompletion:^{
        NSLog(@"dismissed");
        ripple=nil;
        if(capturedImage!=nil){
            CropViewController *crop=[self.storyboard instantiateViewControllerWithIdentifier:@"crop"];
            crop.cropdelegate=self;
            ripple=[[RippleAnimation alloc] init];
            crop.transitioningDelegate=ripple;
            ripple.touchPoint=self.view.frame;
            crop.adjustedImage=capturedImage;
            
            [self presentViewController:crop animated:YES completion:nil];
        }
    }];
    
    
}
-(void)authorizationStatus:(BOOL)status{
    
}

#pragma mark crop delegate
-(void)didFinishCropping:(UIImage *)finalCropImage from:(CropViewController *)cropObj{
    
    PlayingCard *playingCard = [[PlayingCard alloc] init];
    
    playingCard.pickedImage = finalCropImage;
    [_imagesArray addObject:playingCard];
    [cropObj closeWithCompletion:^{
        ripple=nil;
        
        [self.imagesCollectionView reloadData];
        
    }];
    //    [self uploadData:finalCropImage];
    NSLog(@"Size of Image %lu",(unsigned long)UIImageJPEGRepresentation(finalCropImage, 0.5).length);
    //    NSLog(@"%@ Image",finalCropImage);
    /*OCR Call*/
    //     [self OCR:finalCropImage];
}


- (IBAction)addPagesPressed:(id)sender {
    ripple=[[RippleAnimation alloc] init];
    cameraPicker.camdelegate=self;
    cameraPicker.transitioningDelegate=ripple;
    ripple.touchPoint = self.view.frame;
    
    [self presentViewController:cameraPicker animated:YES completion:nil];
}

- (IBAction)previewPressed:(id)sender {
    NSMutableArray *pdfDataArray = [[NSMutableArray alloc]init];
    for (int i=0; i<_imagesArray.count; i++) {
        PlayingCard *playingCard = self.imagesArray[i];
        
        NSData *pdfData = [PDFImageConverter convertImageToPDF:playingCard.pickedImage];
        [pdfDataArray addObject:pdfData];
        
    }
    _scannedPDFPath = [self joinPDF:pdfDataArray];
    
}
-(void)drawImagesToPdf:(UIImageView *)button

{
    
    CGSize pageSize = CGSizeMake(300*5, button.frame.size.height*5+30);
    NSLog(@"page size %@",NSStringFromCGSize(pageSize));
    
    
    NSString *fileName = @"Demo.pdf";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pdfFileName = [documentsDirectory stringByAppendingPathComponent:fileName];
    UIGraphicsBeginPDFContextToFile(pdfFileName, CGRectMake(0, 0, button.frame.size.width, button.frame.size.height*3), nil);
    
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0.0, pageSize.width, pageSize.height), nil);
    
    //NSArray *arrImages = [NSArray arrayWithObjects:@"3.png", @"4.png", @"5.png", @"6.png", nil];
    float y = 220.0;
    
    for (int i=0; i<_imagesArray.count; i++) {
        PlayingCard *playingCard = self.imagesArray[i];
        UIImage * myPNG = playingCard.pickedImage;
        
        [myPNG drawInRect:CGRectMake(50.0, y, myPNG.size.width, myPNG.size.height)];
        
        y += myPNG.size.height + 20;
    }
    
    UIGraphicsEndPDFContext();
}

-(NSString *)joinPDF:(NSArray *)listOfPaths {
    // File paths
    NSString *fileName = @"ALL.pdf";
    NSString *pdfPathOutput = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];
    
    CFURLRef pdfURLOutput = (  CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:pdfPathOutput]);
    
    NSInteger numberOfPages = 0;
    // Create the output context
    CGContextRef writeContext = CGPDFContextCreateWithURL(pdfURLOutput, NULL, NULL);
    
    for (NSData *sourceData in listOfPaths) {
        CFDataRef myPDFData = (__bridge CFDataRef) sourceData;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(myPDFData);
        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithProvider(provider);
        numberOfPages = CGPDFDocumentGetNumberOfPages(pdfRef);
        
        // Loop variables
        CGPDFPageRef page;
        CGRect mediaBox;
        
        // Read the first PDF and generate the output pages
        //DLog(@"GENERATING PAGES FROM PDF 1 (%@)...", source);
        for (int i=1; i<=numberOfPages; i++) {
            page = CGPDFDocumentGetPage(pdfRef, i);
            mediaBox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
            CGContextBeginPage(writeContext, &mediaBox);
            CGContextDrawPDFPage(writeContext, page);
            CGContextEndPage(writeContext);
        }
        
        CGPDFDocumentRelease(pdfRef);
        CGDataProviderRelease(provider);
    }
    CFRelease(pdfURLOutput);
    
    // Finalize the output file
    CGPDFContextClose(writeContext);
    CGContextRelease(writeContext);
    
    return pdfPathOutput;
}


@end
