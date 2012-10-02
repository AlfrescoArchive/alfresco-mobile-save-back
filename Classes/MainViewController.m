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
    [super viewWillAppear:animated];
    [self updateViews];
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

/**
 * Convenience method for displaying messages in UIAlertViews
 */
- (void)displayMessage:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alfresco SaveBack Demo", @"application title")
                                message:message
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"default message OK")
                      otherButtonTitles:nil] show];
}

/**
 * Clears the current document references
 */
- (void)clearDocument
{
    if (self.savedFilePath != nil)
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.savedFilePath error:NULL];
        self.savedFilePath = nil;
    }
    self.alfrescoMetadata = nil;
    [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
    [self updateViews];
}

/**
 * Ensure the UI elements correctly reflect the application state
 */
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

/**
 * Called from the AppDelegate class to handle file open URL requests
 */
- (BOOL)handleFileOpenURL:(NSURL *)url annotation:(id)annotation
{
    // Generate the path where the incoming file is to be saved (in our Documents folder)
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *savePath = [documentsDirectory stringByAppendingPathComponent:url.path.pathComponents.lastObject];

    // Delete any existing file of the same name
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if ([fileManager fileExistsAtPath:savePath])
    {
        [fileManager removeItemAtPath:savePath error:&error];
        if (error)
        {
            [self displayMessage:error.localizedDescription];
            return NO;
        }
    }
    
    // Now move the incoming (Inbox) file to the Downloads folder
    [fileManager moveItemAtPath:url.path toPath:savePath error:&error];
    if (error)
    {
        [self displayMessage:error.localizedDescription];
        return NO;
    }

    self.savedFilePath = savePath;
    
    // If the inbound annotation has the Alfresco SaveBack metadata, then save that now
    self.alfrescoMetadata = [annotation objectForKey:AlfrescoSaveBackMetadataKey];
    
    [self updateViews];
    
    return YES;
}

#pragma mark - Action Button Handler

/**
 * Handles taps on the action button
 */
- (IBAction)actionButtonHandler:(id)sender
{
    self.actionButton.enabled = NO;
    
    // Create an action sheet
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;

    // Add the standard "Open In..." action
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Open In...", @"action menu item: Open In...")];

    // If the inbound file was accompanied by Alfresco metadata then we can offer the "Save Back" action too
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

/**
 * Handles taps on the trash button
 */
- (IBAction)trashButtonHandler:(id)sender
{
    // Remove references to the passed-in document
    [self clearDocument];
}

/**
 * Handle a tap on one of the action sheet buttons
 */
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        self.actionButton.enabled = YES;
    }
    else
    {
        // Both "Open In..." and "Save Back" require a UIDocumentInteractionController
        NSURL *url = [NSURL fileURLWithPath:self.savedFilePath];
        if (self.docInteractionController == nil)
        {
            self.docInteractionController = [[UIDocumentInteractionController alloc] init];
            self.docInteractionController.delegate = self;
        }
        self.docInteractionController.URL = url;
        self.docInteractionController.UTI = nil;

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
                self.docInteractionController.UTI = AlfrescoSaveBackUTI;
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

/**
 * Adds the Alfresco metadata to the outbound file request if the Alfresco app was chosen
 */
- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    if ([controller.UTI isEqualToString:AlfrescoSaveBackUTI])
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

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    self.actionButton.enabled = YES;
}

@end
