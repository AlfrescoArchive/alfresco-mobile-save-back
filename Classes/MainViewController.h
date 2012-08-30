//
//  MainViewController.h
//  SaveBack
//
//  Created by Mike Hatfield on 28/08/2012.
//  Copyright (c) 2012 Alfresco. All rights reserved.
//

@interface MainViewController : UIViewController <UIDocumentInteractionControllerDelegate, UIActionSheetDelegate>

// UI Elements
@property (weak, nonatomic) IBOutlet UINavigationItem *customNavigationItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *documentLabel;

// UI Element actions
- (IBAction)actionButtonHandler:(id)sender;

// Public methods
- (BOOL)handleFileOpenURL:(NSURL *)url annotation:(id)annotation;

@end
