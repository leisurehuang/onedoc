/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 PageViewController.h
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
#import <UIKit/UIPopoverController.h>
#import "PageView.h"
#import "FlippedPageView.h"
#import "RDCViewController.h"
#import "FavoritesTableViewController.h"
#import <QuartzCore/CoreAnimation.h>


#define kMainToolbarHeight			44
#define kKeyboardHeightPortrait		215
#define kKeyboardHeightLandscape	160

@interface PageViewController : UIViewController <PageViewDelegate, RDCViewControllerDelegate, FavoritesTableViewControllerDelegate, UITextFieldDelegate>
{
	NSMutableArray *activeConnections;
	UIToolbar *mainToolbar;
	UINavigationController *favoritesNavController;
	FavoritesTableViewController *favoritesController;
	RDCViewController *zoomedController;
	PageView *pageView;


	//State variable to hang on to while we are switching
	//to and from animation methods.
	RDCViewController *flippingController;
	
	//Temporary Instance Variables Needed to maintain state between threads.
	RDCViewController *selectedServer;
	NSIndexPath *selectedCellIndexPath;
	
	//Temporary Instance Variables neeeded to maintain state after a user selects a server
	//from the favorites list.
	BOOL shouldScrollToPageAfterFavorites;
	int pageToScrollToAfterFavorites;
	BOOL userDidCancelLastConnection;
	
	// width/height of current iOS device
	int devWidth;
	int devHeight;
}


// return page view
- (PageView*)getPageView;

////////////////////////////
/// GUI Callback Methods ///
////////////////////////////
- (void)setupStandardToolbarButtons;
- (void)launchFavoritesChooser;
- (void)removeFavoritesChooser;
- (void)didRemoveFavoritesChooser;
- (void)hideToolbar;
- (void)showToolbar;
- (void)flipPageForController:(RDCViewController *)controller andZoom:(BOOL)zoom;
- (void)flipPageToFront:(RDCViewController *)controller;
- (void)flipPageToBack;
- (void)toggleKeyboard;
- (void)instanceConnectionStatusHasChanged:(id)viewController;
- (void)storeSettings;
- (void)reloadNewsTicker;

//////////////////////////////////
/// Page View Delegate Methods ///
//////////////////////////////////
- (int)numberOfPagesToDisplay;
- (UIView *)viewForPageNumber:(int)pageNumber;
- (CGRect)rectForZoomedPage;
- (BOOL)shouldSelectPageNumber:(int)page;
- (void)willSelectPageNumber:(int)page;
- (void)didSelectPageNumber:(int)page;
- (void)willUnzoomCurrentPage;
- (void)didUnzoomCurrentPage;
- (void)willZoomCurrentPage;
- (void)didZoomCurrentPage;
- (void)userDidClosePageAtPageNumber:(int)pageNumber;
- (NSString *)titleForPageNumber:(int)page;
- (NSString *)subTitleForPageNumber:(int)page;
- (void)launchAbout;

//////////////////////////////////////////
/// RDCViewController Delegate Methods ///
//////////////////////////////////////////
-(void)rdcViewControllerDidConnect:(RDCViewController *)controller;
-(void)rdcViewControllerDidDisconnect:(RDCViewController *)controller;
-(void)rdcViewControllerDidFailToConnect:(RDCViewController *)controller;
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation withController:(RDCViewController *)controller;

/////////////////////////////////////////////////////
/// FavoritesTableViewController Delegate Methods ///
/////////////////////////////////////////////////////
- (void)connectToServerWithConnectionSettings:(NSDictionary *)connectionSettings withCellIndex:(NSIndexPath *)index;
- (void)cancelLastConnectRequest;
- (UIToolbar *)mainToolbar;

@end
