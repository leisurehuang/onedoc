/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 PageViewController.c
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


#import "PageViewController.h"



@implementation PageViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{		
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			devWidth = 768;
			devHeight = 1024; 
		}
		else
		{
			devWidth = 320;
			devHeight = 480; 
		}
		
		
		// Setup the array of active connections
		activeConnections = [[NSMutableArray alloc] initWithCapacity:0];

		// Setup Page View
		CGRect uiR = [UIScreen mainScreen].applicationFrame;
		if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
			pageView = [[PageView alloc] initWithFrame:CGRectMake(0.0, 0, uiR.size.width, uiR.size.height) delegate:self];	
		else
			pageView = [[PageView alloc] initWithFrame:CGRectMake(0.0, 0, uiR.size.height, uiR.size.width) delegate:self];	
		
		pageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
		[self.view addSubview:pageView];

		// Setup Main Toolbar
		mainToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - kMainToolbarHeight, self.view.frame.size.width, kMainToolbarHeight)];
		mainToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		[self setupStandardToolbarButtons];
		[self.view addSubview:mainToolbar];
				
		// Launch the favorites chooser
		shouldScrollToPageAfterFavorites = NO;
		[self launchFavoritesChooser];
	}
	return self;
}

- (PageView*)getPageView
{
	return pageView;
}


- (void)loadView
{
	CGRect uiR = [UIScreen mainScreen].applicationFrame;
	if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
		self.view = [[UIView alloc] initWithFrame:CGRectMake(0.0, uiR.origin.y, uiR.size.width, uiR.size.height)];
	else
		self.view = [[UIView alloc] initWithFrame:CGRectMake(0.0, uiR.origin.x, uiR.size.height, uiR.size.width)];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
}

- (void)viewDidLoad
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	if ([pageView isZoomed])
	{
		return YES;
	}
	
	// FIXME: also rotate if Favorites view is active ...	
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if ([pageView isZoomed])
	{
		RDCViewController *thisController = [activeConnections objectAtIndex:[pageView currentPageNumber]];
		if ([thisController isKeyboardToggled])
		{
			[thisController toggleKeyboard];
		}
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[pageView setOrientationChangeSinceLastLayout:YES];
	if ([pageView isZoomed])
	{
		RDCViewController *controller = [activeConnections objectAtIndex:[pageView currentPageNumber]];
		[controller scrollView].maximumZoomScale = 3.0;
		CGRect uiR = [UIScreen mainScreen].applicationFrame;
		if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
		{
			pageView.frame = CGRectMake(0.0, 0, uiR.size.width, uiR.size.height);		
			controller.view.frame = CGRectMake(0.0, 0, uiR.size.width, uiR.size.height);
			[controller scrollView].minimumZoomScale = ([self rectForZoomedPage].size.height - kRDCToolbarHeight) / [controller screenHeight];
		}
		else
		{
			pageView.frame = CGRectMake(0.0, 0, uiR.size.height, uiR.size.width);
			controller.view.frame = CGRectMake(0.0, 0, uiR.size.height, uiR.size.width);
			[controller scrollView].minimumZoomScale = [self rectForZoomedPage].size.width / [controller screenWidth];
		}
//		[[controller scrollView] setNeedsDisplay];
		[controller scrollView].minimumZoomScale = [controller scrollView].minimumZoomScale - .1;
		[[controller rdcView] removeFromSuperview];
		[controller scrollView].minimumZoomScale = [controller scrollView].minimumZoomScale + .1;
		[[controller scrollView] addSubview:[controller rdcView]];
		[controller updateScrollViewAfterOrientationChange];
	}
	else
	{
		if(favoritesController)
			[favoritesController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	}

}

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)dealloc 
{
	if (!favoritesNavController)
	{
		[favoritesNavController release];
	}
	[mainToolbar dealloc];
	[pageView dealloc];
	[super dealloc];
}

////////////////////////////
/// GUI Callback Methods ///
////////////////////////////
- (void)setupStandardToolbarButtons
{
	UIBarButtonItem *favorites = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(launchFavoritesChooser)];
	[mainToolbar setItems:[NSArray arrayWithObjects:favorites, nil] animated:YES];
	[favorites release];	
}

- (void)launchAbout
{
	if (favoritesController)
	{
		[favoritesController launchAboutView];
	}
}


- (void)launchFavoritesChooser
{
	// minimize any existing session
	int currentPage = [pageView currentPageNumber];
	if(currentPage >= 0)
		[self rdcViewControllerDidMinimize];
	
	//Lazily load the favorites NavigationController and TableViewController
	if (!favoritesController)
	{
		favoritesController = [[FavoritesTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
		//favoritesController = [[FavoritesTableViewController alloc] initWithStyle:UITableViewStylePlain];
		favoritesController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
		[favoritesController setDelegate:self];
	}
	favoritesController.navigationItem.leftBarButtonItem.enabled = YES;
	favoritesController.tableView.scrollEnabled = YES;
	if (!favoritesNavController)
	{
		favoritesNavController = [[UINavigationController alloc] initWithRootViewController:favoritesController];
		[favoritesNavController setDelegate:favoritesController];
		favoritesNavController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
		favoritesNavController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	}	
	
	//Configure the toolbar for the favorites chooser
	UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:favoritesController action:@selector(toggleEditMode)];
	UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"About" value:@"About" table:nil] style:UIBarButtonItemStyleBordered target:self action:@selector(launchAbout)];
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	NSMutableArray *buttons = [NSMutableArray arrayWithObjects:editButton, flexibleSpace, aboutButton, nil];
	[editButton release];
	if ([activeConnections count] > 0)
	{
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(removeFavoritesChooser)];
		[buttons addObject:doneButton];
		[flexibleSpace release];
		[doneButton release];
	}
	mainToolbar.barStyle = UIBarStyleBlackOpaque;
	
	[mainToolbar setItems:buttons animated:YES];
	
	//Slide in the Favorites Chooser
	if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
	{
		favoritesNavController.view.frame = CGRectMake(0.0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - kMainToolbarHeight);
	}
	else
	{
		favoritesNavController.view.frame = CGRectMake(0.0, self.view.frame.size.width, self.view.frame.size.height, self.view.frame.size.width - kMainToolbarHeight);
	}
	[pageView addSubview:favoritesNavController.view];	   
	[pageView bringSubviewToFront:mainToolbar];
	[UIView beginAnimations:@"deployFavoritesChooser" context:nil];

	static BOOL bFirstAppearance = YES;
	if (bFirstAppearance) {
		[UIView setAnimationDuration:.0];
		bFirstAppearance = NO;
	}
	else {
		[UIView setAnimationDuration:.4];
	}
		
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
	{
		favoritesNavController.view.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height - kMainToolbarHeight);
	}
	else
	{
		favoritesNavController.view.frame = CGRectMake(0.0, 0.0, self.view.frame.size.height, self.view.frame.size.width - kMainToolbarHeight);
	}
	[UIView commitAnimations];
}

- (void)removeFavoritesChooser
{
	//Slide out the Favorites Chooser
	[self setupStandardToolbarButtons];
	[UIView beginAnimations:@"removeFavoritesChooser" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(didRemoveFavoritesChooser)];
	[UIView setAnimationDuration:.4];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];

	if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
	{
		favoritesNavController.view.frame = CGRectMake(0.0, devHeight - 80, self.view.frame.size.width, pageView.frame.size.height);
	}
	else
	{
		favoritesNavController.view.frame = CGRectMake(0.0, devWidth - 80, self.view.frame.size.height, pageView.frame.size.width);
	}
	[UIView commitAnimations];
	[favoritesController setCanSelectAServer:YES];
}

- (void)storeSettings
{
	[favoritesController storeSettings];
}

- (void)reloadNewsTicker
{
	[favoritesController reloadNewsTicker];
}


//Animation Delegate Methods.
- (void)didRemoveFavoritesChooser
{
	[favoritesNavController.view removeFromSuperview];
	if (shouldScrollToPageAfterFavorites)
	{
		shouldScrollToPageAfterFavorites = NO;
		[pageView scrollToPage:pageToScrollToAfterFavorites animated:YES andZoom:YES];
	}
}

- (void)hideToolbar
{
	[UIView beginAnimations:@"hideMainToolbar" context:nil];
	[UIView setAnimationDuration:.4];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	mainToolbar.frame = CGRectMake(0.0, pageView.frame.size.height, mainToolbar.frame.size.width, mainToolbar.frame.size.height);
	[UIView commitAnimations];	
}

- (void)showToolbar
{
	[UIView beginAnimations:@"showMainToolbar" context:nil];
	[UIView setAnimationDuration:.4];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	mainToolbar.frame = CGRectMake(0.0, pageView.frame.size.height - kMainToolbarHeight, pageView.frame.size.width, kMainToolbarHeight);
	[UIView commitAnimations];	
}

- (void)flipPageForController:(RDCViewController *)controller andZoom:(BOOL)zoom;
{
	//Flip to front from back.
	if ([[controller flippedPageView] superview])
	{
		[self flipPageToFront:controller];
	}
	//Flip to back from front.
	else
	{
		flippingController = controller;
		[pageView hideCloseButtonForCurrentPageWithCallbackObject:self selector:@selector(flipPageToBack)];
	}
}

- (void)flipPageToFront:(RDCViewController *)controller
{
	//Flip the view over.
	[controller flippedPageView].frame = CGRectMake(0.0, 0.0, controller.view.frame.size.width, controller.view.frame.size.height);
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:([controller isViewFlipped] ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:[controller view] cache:NO];
	[UIView setAnimationDelegate:pageView];
	[UIView setAnimationDidStopSelector:@selector(zoomCurrentPage)];
	[[controller flippedPageView] removeFromSuperview];
	[[controller view] addSubview:[controller scrollView]];
	[controller setIsViewFlipped:NO];
	[UIView commitAnimations];
}

- (void)flipPageToBack
{
	//Flip the view over.  If we get no controller object
	//it is because this method is being called as a result
	//of another animation finishing and we couldn't pass a real
	//object in.  So we will check the flippingController instance
	//variable for a controller.
	RDCViewController *controller = flippingController;
	[controller.view.layer setNeedsLayout];
	[controller flippedPageView].frame = CGRectMake(0.0, 0.0, controller.view.frame.size.width, controller.view.frame.size.height);
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationDelegate:pageView];
	[UIView setAnimationDidStopSelector:@selector(showCloseButtonForCurrentPage)];
	[UIView setAnimationTransition:([controller isViewFlipped] ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:[controller view] cache:NO];
	[[controller scrollView] removeFromSuperview];
	[[controller view] addSubview:[controller flippedPageView]];
	[controller flippedPageView].frame = CGRectMake(0.0, 0.0, controller.view.frame.size.width, controller.view.frame.size.height);
	[controller setIsViewFlipped:YES];
	controller.view.userInteractionEnabled = YES;
	[UIView commitAnimations];
}

- (void)toggleKeyboard
{
	if (zoomedController)
	{
		[zoomedController toggleKeyboard];
	}
}

- (void)instanceConnectionStatusHasChanged:(id)viewController
{

}

//////////////////////////////////
/// Page View Delegate Methods ///
//////////////////////////////////
- (int)numberOfPagesToDisplay
{
	return [activeConnections count];
}

- (UIView *)viewForPageNumber:(int)pageNumber
{
	return [[activeConnections objectAtIndex:pageNumber] view];
}

- (CGRect)rectForZoomedPage
{
	CGRect uiR = [UIScreen mainScreen].applicationFrame;
	if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
	{
		return CGRectMake(0.0, 0, uiR.size.width, uiR.size.height);
	}
	else
	{
		return CGRectMake(0.0, 0, uiR.size.height, uiR.size.width);
	}
}

- (BOOL)shouldSelectPageNumber:(int)page
{
	if (![[activeConnections objectAtIndex:page] isViewFlipped])
	{
		return YES;
	}
	return NO;
}

- (void)willSelectPageNumber:(int)page
{
	//Delete this method from class and PageViewDelegate protocol
}

- (void)didSelectPageNumber:(int)page
{
	zoomedController = [[activeConnections objectAtIndex:page] retain];
}

- (void)willUnzoomCurrentPage
{
	RDCViewController *controller = [activeConnections objectAtIndex:[pageView currentPageNumber]];
	if ([zoomedController isKeyboardToggled])
	{
		[self toggleKeyboard];
	}
	[zoomedController hideRDCToolbar];
	controller.view.userInteractionEnabled = NO;
	
	int i = 0;
	for (i = 0 ; i < activeConnections.count ; i++)
	{
		RDCViewController *thisController = [activeConnections objectAtIndex:i];
		if (thisController != controller)
		{
			[pageView addSubview:thisController.view];
		}
	}
	[pageView bringSubviewToFront:controller.view];
}

- (void)didUnzoomCurrentPage
{
	[self showToolbar];
	[zoomedController release];
	zoomedController = nil;
}

- (void)willZoomCurrentPage
{
	//Hide the main toolbar
	[UIView beginAnimations:@"hideMainToolbar" context:nil];
	[UIView setAnimationDuration:.4];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	mainToolbar.frame = CGRectMake(0.0, pageView.frame.size.height, pageView.frame.size.width, mainToolbar.frame.size.height);
	[UIView commitAnimations];

	//Enable user interaction 
	RDCViewController *controller = [activeConnections objectAtIndex:[pageView currentPageNumber]];
	[pageView bringSubviewToFront:[controller view]];
	[controller view].userInteractionEnabled = YES;
}

- (void)didZoomCurrentPage
{
	//Reset the max and min zoom scales on the rdcviewcontroller to account for resize
	RDCViewController *controller = [activeConnections objectAtIndex:[pageView currentPageNumber]];
	[controller scrollView].maximumZoomScale = 3.0;
	if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
	{
		[controller scrollView].minimumZoomScale = ([self rectForZoomedPage].size.height - kRDCToolbarHeight) / [controller screenHeight];
	}
	else
	{
		[controller scrollView].minimumZoomScale = [self rectForZoomedPage].size.width / [controller screenWidth];
	}
	
	//Tell the RDCViewController to display its toolbar
	[controller showRDCToolbar];
	
	int i = 0;
	for (i = 0 ; i < activeConnections.count ; i++)
	{
		RDCViewController *thisController = [activeConnections objectAtIndex:i];
		if (thisController != controller)
		{
			[thisController.view removeFromSuperview];
		}
	}
}

- (void)userDidClosePageAtPageNumber:(int)pageNumber
{
	[activeConnections removeObjectAtIndex:pageNumber];
	[pageView removePageAtPageNumber:pageNumber animated:YES];
	if ([activeConnections count] == 0)
	{
		[self launchFavoritesChooser];
	}
}

- (NSString *)titleForPageNumber:(int)page
{
	return [[activeConnections objectAtIndex:page] title];
}

- (NSString *)subTitleForPageNumber:(int)page
{
	return [[activeConnections objectAtIndex:page] host];
}

//////////////////////////////////////////
/// RDCViewController Delegate Methods ///
//////////////////////////////////////////
-(void)rdcViewControllerDidConnect:(RDCViewController *)controller
{
	if ([controller isViewFlipped])
	{
		[self flipPageForController:controller andZoom:YES];
	}
	
	if (selectedServer && selectedServer == controller)
	{
		if (![activeConnections containsObject:controller])
		{
			[activeConnections addObject:controller];
			pageToScrollToAfterFavorites = [activeConnections indexOfObject:controller];
			shouldScrollToPageAfterFavorites = YES;
			
			[controller setupView];
			if (selectedCellIndexPath)
			{
				UITableViewCell *selectedCell = [favoritesController.tableView cellForRowAtIndexPath:selectedCellIndexPath];
				selectedCell.accessoryView = nil;
				selectedCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
				[selectedCellIndexPath release];
			}
			[selectedServer release];
			selectedServer = nil;
			[self removeFavoritesChooser];
		}
	}
	
	int currentPage = [pageView currentPageNumber];	
	if ([activeConnections objectAtIndex:currentPage] && [activeConnections objectAtIndex:currentPage] == controller)
	{
		[controller scrollView].maximumZoomScale = 3.0;
		[controller scrollView].minimumZoomScale = [controller scrollView].frame.size.height / [controller screenHeight];
	}
}

-(void)rdcViewControllerDidDisconnect:(RDCViewController *)controller
{
	int currentPage = [pageView currentPageNumber];
	
	//First check to make sure the disconnected controller is still available as a page.
	//It's entirely possible that the user has closed the page before this method
	//is called so we will plan for this accordingly.
	if ([activeConnections containsObject:controller])
	{
		if ([activeConnections objectAtIndex:currentPage] == controller)
		{
			[pageView unZoomCurrentPage];
		}
		if (![controller isViewFlipped])
		{
			[self flipPageForController:controller andZoom:NO];
		}
	}
}

- (void)rdcViewControllerDidFailToConnect:(RDCViewController *)controller
{
	//Reset the UITableView for another selection
	if (selectedServer && selectedServer == controller)
	{
		if (selectedCellIndexPath)
		{
			UITableViewCell *selectedCell = [favoritesController.tableView cellForRowAtIndexPath:selectedCellIndexPath];
			selectedCell.accessoryView = nil;
			selectedCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			[selectedCellIndexPath release];
		}
		selectedServer = nil;
	}
	[controller release];
	
	// open an alert with just an OK button
	if (!userDidCancelLastConnection)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"ConnectionFailure" value:@"Connection Failure" table:nil] 
														message:[[NSBundle mainBundle] localizedStringForKey:@"ConnectionFailureMessage" value:@"Could not establish a connection to the server" table:nil]
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
		[favoritesController connectionRequestDidFail];
	}
	else
	{
		userDidCancelLastConnection = NO;
	}
	
	//Allow the user to select a new server
	[favoritesController setCanSelectAServer:YES];
}

- (void)rdcViewControllerDidMinimize
{
	[pageView unZoomCurrentPage];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation withController:(RDCViewController *)controller
{
	if (zoomedController == controller)
	{
		return YES;
	}
	else
	{
		return YES;
	}
}

/////////////////////////////////////////////////////
/// FavoritesTableViewController Delegate Methods ///
/////////////////////////////////////////////////////
- (void)connectToServerWithConnectionSettings:(NSDictionary *)connectionSettings withCellIndex:(NSIndexPath *)index
{
	RDCViewController *controller = [[RDCViewController alloc] initWithConnectionSettingsDictionary:connectionSettings delegate:self];
	if (selectedServer)
	{
		[selectedServer release];
	}
	selectedServer = controller;
	[controller retain];
	selectedCellIndexPath = index;
	[index retain];
	
	[controller setDelegate:self];
	controller.view.userInteractionEnabled = NO;
	controller.view.alpha = 0.0;
	controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
}

- (void)cancelLastConnectRequest
{
	//Reset the UITableView for another selection
	if (selectedServer)
	{
		userDidCancelLastConnection = YES;
		[[selectedServer rdInstance] cancelConnection];
	}
}

- (UIToolbar *)mainToolbar
{
	return mainToolbar;
}

//////////////////////////////////
// UITextField Delegate Methods //
//////////////////////////////////
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	RDCViewController *controller = [activeConnections objectAtIndex:[pageView currentPageNumber]];
	return [controller textField:textField shouldChangeCharactersInRange:range replacementString:string];
}


- (UIViewController*)viewControllerForPresentingModalView
{
	return self;
}




@end

