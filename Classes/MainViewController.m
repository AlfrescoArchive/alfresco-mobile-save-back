/*******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
 *
 * This file is part of the Alfresco SaveBack Demo.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
//
//  MainViewController.m
//

#import "MainViewController.h"
#import "AlfrescoSaveBackAPI.h"

@interface MainViewController ()

// Functional properties
@property (strong, nonatomic) NSString *savedFilePath;
@property (strong, nonatomic) NSDictionary *alfrescoMetadata;
@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (strong, nonatomic) UIDocumentInteractionController *docInteractionController;
@property (nonatomic) NSInteger saveBackActionIndex;

@end

@implementation MainViewController
@synthesize customNavigationItem = _customNavigationItem;
@synthesize actionButton = _actionButton;
@synthesize trashButton = _trashButton;
@synthesize logoImageView = _logoImageView;
@synthesize documentLabel = _documentLabel;

- (void)dealloc
{
    // Have we saved a file to the Documents directory?
    if (self.savedFilePath != nil)
    {
        // Yes; let's remove it
        [[NSFileManager defaultManager] removeItemAtPath:self.savedFilePath error:NULL];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set title
    self.customNavigationItem.title = NSLocalizedString(@"Alfresco SaveBack Demo", @"application title");
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateViews];
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
    return YES;
}

#pragma mark - Instance Methods

- (void)displayMessage:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alfresco SaveBack Demo", @"application title")
                                message:message
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"default message OK")
                      otherButtonTitles:nil] show];
}

- (void)clearDocument
{
    if (self.savedFilePath != nil)
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.savedFilePath error:NULL];
        self.savedFilePath = nil;
    }
    self.alfrescoMetadata = nil;
    [self updateViews];
}

- (void)updateViews
{
    BOOL hasDocument = (self.savedFilePath != nil);
    BOOL hasAlfrescoMetadata = (self.alfrescoMetadata != nil);

    self.actionButton.enabled = hasDocument;
    self.trashButton.enabled = hasDocument;
    self.logoImageView.image = [UIImage imageNamed:(hasAlfrescoMetadata ? @"has-alfresco-metadata" : @"no-alfresco-metadata")];
    self.documentLabel.text = hasDocument ? self.savedFilePath.pathComponents.lastObject : NSLocalizedString(@"No Document", @"no document label");
}

#pragma mark - File URL Handler

- (BOOL)handleFileOpenURL:(NSURL *)url annotation:(id)annotation
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *savePath = [documentsDirectory stringByAppendingPathComponent:url.path.pathComponents.lastObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:savePath])
    {
        [fileManager removeItemAtPath:savePath error:NULL];
    }
    [fileManager moveItemAtPath:url.path toPath:savePath error:NULL];

    self.savedFilePath = savePath;
    self.alfrescoMetadata = [annotation objectForKey:AlfrescoSaveBackMetadataKey];
    
    [self updateViews];
    
    return YES;
}

#pragma mark - Action Button Handler

- (IBAction)actionButtonHandler:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Open In...", @"action menu item: Open In...")];
    if (self.alfrescoMetadata != nil)
    {
        self.saveBackActionIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Save Back", @"action menu item: Save Back")];
    }
    
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
    {
        // Per Apple design guidelines, we do not show a "Cancel" button on the iPad
        actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"action menu item: Cancel")];
    }
    
    self.actionSheet = actionSheet;
    [actionSheet showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
}

- (IBAction)trashButtonHandler:(id)sender
{
    [self clearDocument];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        /**
         * Handle either "Open In..." or "Save Back"
         */
        NSURL *url = [NSURL fileURLWithPath:self.savedFilePath];
        if (self.docInteractionController == nil)
        {
            self.docInteractionController = [[UIDocumentInteractionController alloc] init];
            self.docInteractionController.delegate = self;
        }
        self.docInteractionController.URL = url;

        // Was it the "Save Back" action?
        if (buttonIndex == self.saveBackActionIndex)
        {
            /**
             * Alfresco SaveBack integration
             *
             * Create an NSURL object that the UIDocumentInteractionController will need for SaveBack to operate correctly
             */
            NSError *error;
            NSURL *saveBackURL = alfrescoSaveBackURLForFilePath(self.savedFilePath, &error);
            if (saveBackURL != nil)
            {
                // Set the URL property of the UIDocumentInteractionController to the URL that was returned
                self.docInteractionController.URL = saveBackURL;
            }
            else
            {
                // An error occurred - handle it here
                [self displayMessage:error.localizedDescription];
                return;
            }
        }
        
        /**
         * (Demo purposes) Attempt to update the file's ModificationDate to the current date
         */
        NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
        [[NSFileManager defaultManager] setAttributes:attrs ofItemAtPath:self.savedFilePath error:NULL];

        if (![self.docInteractionController presentOpenInMenuFromBarButtonItem:self.actionButton animated:YES])
        {
            [self displayMessage:NSLocalizedString(@"There are no applications that are capable of opening this file on this device", @"no available applications for Open In...")];
        }
    }
}

#pragma mark - UI Document Interaction Controller

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    if ([application isEqualToString:AlfrescoBundleIdentifier])
    {
        /**
         * Alfresco SaveBack integration
         *
         * Return the object that was passed in the annotation for key AlfrescoSaveBackMetadataKey
         */
        NSDictionary* annotation = [NSDictionary dictionaryWithObject:self.alfrescoMetadata forKey:AlfrescoSaveBackMetadataKey];
        self.docInteractionController.annotation = annotation;
    }
}

@end
