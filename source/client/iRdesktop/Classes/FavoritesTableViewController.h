/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 FavoritesTableViewController.h
 Copyright (C) Carter Harrison   2008-2009
 Copyright (C) Thinstuff s.r.o.  2009
 
 ------------------------------------------------------------------------
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 ------------------------------------------------------------------------
 */


#import <UIKit/UIKit.h>
#import "ConnectionTableViewController.h"
#import "NewServerTableViewController.h"
#import "KeychainServices.h"
#import <CommonCrypto/CommonDigest.h>
#import "Misc.h"
#import "XUITableViewController.h"
#import "InfoViewController.h"


@interface FavoritesTableViewController : XUITableViewController <UIWebViewDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>
{
	id delegate;
	BOOL isEditing;
	NSMutableArray *bookmarkedServers;
	NSMutableDictionary *settingsRoot;
	UIWindow *newServerWindow;
	UINavigationController *newServerNavController;
	NewServerTableViewController *newServerTableViewController;
	NSArray *cachedToolbarButtons;
	BOOL canSelectAServer;
	BOOL serverPopoverPresent;
	InfoViewController *infoViewController;
	UINavigationController *infoViewNavController;
	UIInterfaceOrientation uiOrientation;
	NSInteger connectionAttempts;	
	UIWebView *newsView;
}

@property (nonatomic, retain) UIPopoverController* newServerPopoverController;


- (void)setDelegate:(id)object;
- (id)delegate;

- (IBAction)toggleEditMode;
- (IBAction)launchNewServerEditor:(id)sender;
- (IBAction)closeNewServerEditor;
- (void)userDidCancelLastConnectRequest;
- (void)connectionRequestDidFail;
- (void)connectionRequestDidSucceed;
- (void)disableInterface;
- (void)enableInterface;
- (void)saveToPropertyList;
- (void)saveNewServer;
- (void)setCanSelectAServer:(BOOL)canSelect;
- (void)launchInfoView:(BOOL)adMode;
- (IBAction)launchAboutView;
- (IBAction)launchAdView;
- (void)storeSettings;
- (void)reloadNewsTicker;
- (NSURLRequest*)getNewsTickerURL;

- (id)applicationPlistFromFile:(NSString *)fileName;
- (NSData *)applicationDataFromFile:(NSString *)fileName;
- (BOOL)writeApplicationData:(NSData *)data toFile:(NSString *)fileName;

//////////////////////////////////////////////
/// UINavigationControllerDelegate Methods ///
//////////////////////////////////////////////
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;

//////////////////////////////////////////////
/// UIPopoverControllerDelegate Methods ///
//////////////////////////////////////////////
- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController;


@end

@protocol FavoritesTableViewControllerDelegate
- (void)connectToServerWithConnectionSettings:(NSDictionary *)connectionSettings withCellIndex:(NSIndexPath *)index;
- (void)cancelLastConnectRequest;
- (UIToolbar *)mainToolbar;
- (void)launchAbout;
@end
