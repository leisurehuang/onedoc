/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 FavoritesTableViewController.m
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

#define XPVSADSECTIONID		0


#import "FavoritesTableViewController.h"
#import "PageViewController.h"

@implementation FavoritesTableViewController

@synthesize newServerPopoverController;

- (id)initWithStyle:(UITableViewStyle)style 
{
	
	if (self = [super initWithStyle:style]) 
	{
		// read number of connection attempts from user defaults
		NSUserDefaults* stdUserDefaults = [NSUserDefaults standardUserDefaults];
		if(stdUserDefaults)
			connectionAttempts = [stdUserDefaults integerForKey:@"connectionAttempts"];
			
		isEditing = NO;
		canSelectAServer = YES;
		serverPopoverPresent = NO;
		settingsRoot = [[NSMutableDictionary alloc] initWithDictionary:[self applicationPlistFromFile:@"settings.plist"]];
		bookmarkedServers = [[NSMutableArray alloc] initWithArray:[settingsRoot valueForKey:@"Servers"]];
		
		//TO FACILITATE UPGRADE FROM 1.0.0 to 1.0.1
		//Iterate over servers.. Add port numbers if they don't exist already.  
		int i = 0;
		for (i = 0 ; i < bookmarkedServers.count ; i++)
		{
			NSMutableDictionary *server = [bookmarkedServers objectAtIndex:i];
			if (![server valueForKey:@"port"])
			{
				[server setValue:[NSNumber numberWithInt:3389] forKey:@"port"];
			}
			if (![server valueForKey:@"console"])
			{
				[server setValue:[NSNumber numberWithBool:NO] forKey:@"console"];
			}
		}
		
		
		//Setup the navigation item
		self.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"FavoriteServers" value:@"Favorite Servers" table:@"Localizable"];
		[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"New" value:@"New" table:nil] style:UIBarButtonItemStyleBordered target:self action:@selector(launchNewServerEditor:)] autorelease] animated:YES];
		
		//Adjust the view
		self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		cachedToolbarButtons = nil;
		uiOrientation = self.interfaceOrientation;
	}
	return self;
}

- (void)setDelegate:(id)object
{
	if (delegate)
	{
		[delegate release];
	}
	delegate = object;
	[object retain];
}

- (id)delegate
{
	return delegate;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if(fromInterfaceOrientation == UIInterfaceOrientationPortrait || fromInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
		uiOrientation = UIInterfaceOrientationLandscapeLeft;
	else
		uiOrientation = UIInterfaceOrientationPortrait;

	// reload ticker
	// [newsView reload];
}

- (IBAction)toggleEditMode
{
	isEditing = !isEditing;

	if (isEditing)
	{
		cachedToolbarButtons = [delegate mainToolbar].items;
		[cachedToolbarButtons retain];
		[[delegate mainToolbar] setItems:nil animated:YES];
		[self.tableView setEditing:YES animated:YES];
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toggleEditMode)] autorelease] animated:YES];
		[self.navigationItem setLeftBarButtonItem:nil animated:YES];
		[self saveToPropertyList];
	}
	else
	{
		[[delegate mainToolbar] setItems:cachedToolbarButtons animated:YES];
		[cachedToolbarButtons release];
		cachedToolbarButtons = nil;
		[self.tableView setEditing:NO animated:YES];
		[self.navigationItem setRightBarButtonItem:nil animated:YES];
		[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"New" value:@"New" table:nil] style:UIBarButtonItemStyleBordered target:self action:@selector(launchNewServerEditor:)] autorelease] animated:YES];
		[self saveToPropertyList];
	}
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
	serverPopoverPresent = NO;
}

- (IBAction)launchNewServerEditor:(id)sender
{	
	//Setup the navigation controller and table view controller
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{		
		newServerTableViewController = [[NewServerTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
		newServerNavController = [[UINavigationController alloc] initWithRootViewController:newServerTableViewController];
		newServerNavController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
		newServerTableViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
		newServerNavController.navigationBar.barStyle = UIBarStyleBlackOpaque;	
		
		//Clear Existing Fields in the New Server Editor
		[newServerTableViewController resetConnectionSettingsToNew];	
		newServerTableViewController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"NewServer" value:@"New Server" table:nil];
		newServerTableViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveNewServer)] autorelease];
		newServerTableViewController.navigationItem.rightBarButtonItem.enabled = [newServerTableViewController isSaveButtonActive];
		newServerTableViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeNewServerEditor)] autorelease];;	
		
		Class cls = NSClassFromString(@"UIPopoverController");
		if(cls != nil)
		{
			if(!serverPopoverPresent)
			{			
				serverPopoverPresent = YES;
				if(self.newServerPopoverController == nil)
				{
					self.newServerPopoverController = [[cls alloc] initWithContentViewController:newServerNavController];
					self.newServerPopoverController.delegate = self;
				}
				else
					[self.newServerPopoverController setContentViewController:newServerNavController];		
			
				[self.newServerPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			}
			else
			{
				[self.newServerPopoverController dismissPopoverAnimated:YES];
				serverPopoverPresent = NO;
			}
		}
	}
	else 
	{
		newServerTableViewController = [[NewServerTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
		newServerNavController = [[UINavigationController alloc] initWithRootViewController:newServerTableViewController];
		[[delegate view] addSubview:newServerNavController.view];
		newServerNavController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
		newServerTableViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
		newServerNavController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		
		//Clear Existing Fields in the New Server Editor
		[newServerTableViewController resetConnectionSettingsToNew];
		
		//Configure the navigation controller and tableview controller
		newServerTableViewController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"NewServer" value:@"New Server" table:nil];

		newServerNavController.view.frame = CGRectMake(0.0, [delegate getPageView].frame.size.height, [delegate getPageView].frame.size.width, [delegate getPageView].frame.size.height);
		newServerNavController.navigationBar.frame = CGRectMake(0, 0, [delegate getPageView].frame.size.width, 44);

		newServerTableViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveNewServer)] autorelease];
		newServerTableViewController.navigationItem.rightBarButtonItem.enabled = [newServerTableViewController isSaveButtonActive];
		newServerTableViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeNewServerEditor)] autorelease];;
				
		//Animate the New Server editor onto the screen.
		[UIView beginAnimations:@"launchNewServerEditor" context:nil];
		[UIView setAnimationDuration:.4];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	
		newServerTableViewController.navigationController.view.frame = CGRectMake(0.0, 0, [delegate getPageView].frame.size.width, [delegate getPageView].frame.size.height);

		[UIView commitAnimations];
	}
}


- (IBAction)closeNewServerEditor
{
	//Animate the new server window off the screen
	[self.tableView reloadData];
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[self.newServerPopoverController dismissPopoverAnimated:YES];
		serverPopoverPresent = NO;
		[newServerNavController.view removeFromSuperview];
		[newServerNavController release];
	}
	else
	{		
		[UIView beginAnimations:@"closeNewServerEditor" context:nil];
		[UIView setAnimationDuration:.4];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(didRemoveNewServerEditor)];
		newServerTableViewController.navigationController.view.frame = CGRectMake(0.0, [UIScreen mainScreen].applicationFrame.size.height + 100, self.view.frame.size.width, self.view.frame.size.height);
		[UIView commitAnimations];
	}
}

- (void)didRemoveNewServerEditor
{
	[newServerNavController.view removeFromSuperview];
	[newServerNavController release];
}


- (void)launchInfoView:(BOOL)adMode
{
	infoViewController = [[InfoViewController alloc] initWithNibName:nil bundle:nil];
	
	infoViewController.adMode = adMode;

	infoViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;

	infoViewNavController = [[UINavigationController alloc] initWithRootViewController:infoViewController];

	infoViewNavController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
	infoViewNavController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	
	infoViewController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"AboutiRdesktop" value:adMode ? @"Thinstuff XP/VS Server" : @"About iRdesktop" table:nil];
	infoViewNavController.view.frame = CGRectMake(0.0, 0, [delegate getPageView].frame.size.width, [delegate getPageView].frame.size.height);
	infoViewController.navigationController.view.frame = CGRectMake(0.0, 0, [delegate getPageView].frame.size.width, [delegate getPageView].frame.size.height);
	infoViewNavController.navigationBar.frame = CGRectMake(0, 0, [delegate getPageView].frame.size.width, 44);
	
	infoViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeInfoView)] autorelease];
	[[delegate view] addSubview:infoViewNavController.view];
	
	[UIView beginAnimations:@"launchInfoView" context:nil];
	[UIView setAnimationDuration:0.8];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:[delegate view] cache:YES];

	[UIView commitAnimations];
}

- (IBAction)launchAboutView
{
	[self launchInfoView:FALSE];
}


- (IBAction)launchAdView
{
	[self launchInfoView:TRUE];
}


- (void)didRemoveInfoView
{
	[infoViewNavController release];
}

- (IBAction)closeInfoView
{
	[UIView beginAnimations:@"closeInfoView" context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:[delegate view] cache:YES];

	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(didRemoveInfoView)];
	
	[infoViewNavController.view removeFromSuperview];

	[UIView commitAnimations];
}


//Action method for the "Abort" button which displays in table view cells during
//connection attempts.
- (void)userDidCancelLastConnectRequest
{
	[self enableInterface];
	
	//Tell the delegate to perform the cancel.
	[delegate cancelLastConnectRequest];
}

//Called by PageViewController when a connection can't be established.
- (void)connectionRequestDidFail
{
	[self enableInterface];
}

//Called by PageViewController when a connection is established.
- (void)connectionRequestDidSucceed
{
	[self enableInterface];
}

//Disabled portions of the interface when a connection attempt is made.
- (void)disableInterface
{
	//Disable all toolbar buttons.
	NSArray *toolbarItems = [delegate mainToolbar].items;
	int i = 0;
	for (i = 0 ; i < toolbarItems.count ; i++)
	{
		[[toolbarItems objectAtIndex:i] setEnabled:NO];
	}
	self.navigationItem.leftBarButtonItem.enabled = NO;
	
	//Disable tableview scrolling.
	self.tableView.scrollEnabled = NO;
}

//Enables portions of the interface disabled by the previous method.  Called
//when the interface needs to be turned back on after a failed or aborted connection
//attempt.
- (void)enableInterface
{
	//Enable all toolbar buttons
	NSArray *toolbarItems = [delegate mainToolbar].items;
	int i = 0;
	for (i = 0 ; i < toolbarItems.count ; i++)
	{
		[[toolbarItems objectAtIndex:i] setEnabled:YES];
	}
	self.navigationItem.leftBarButtonItem.enabled = YES;
	
	//Turn scrolling back on.
	self.tableView.scrollEnabled = YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)_tableView 
{
	return 2;
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	// make room for the ad
	if(section == XPVSADSECTIONID)
		return 60.0;
	return 0.0;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if(section == XPVSADSECTIONID)
		return [[[UIView alloc] init] autorelease];
	return nil;
}
*/

- (NSInteger)tableView:(UITableView *)_tableView numberOfRowsInSection:(NSInteger)section 
{
	if (section == XPVSADSECTIONID)
		return 1;
	else
		return [bookmarkedServers count];
}

- (CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == XPVSADSECTIONID)
		return 55.0;
	
	return _tableView.rowHeight;
}



 - (NSString *)tableView:(UITableView *)_tableView titleForHeaderInSection:(NSInteger)section
{
	//if (section != XPVSADSECTIONID) return @"Saved Servers";
	return nil;
}

- (NSURLRequest*) getNewsTickerURL
{
	// get application version string
	CFStringRef appVersion = (CFStringRef)CFBundleGetValueForInfoDictionaryKey( CFBundleGetMainBundle() , kCFBundleVersionKey );
	CFRetain(appVersion);
	if( !appVersion )
	{
		appVersion = CFStringCreateCopy(kCFAllocatorDefault , CFSTR("1.0"));
	}
	
	// get total number of connection attempts		
	NSString *requestUrl = [NSString stringWithFormat:@""
							@"http://www.irdesktop.com/iRdesktopFrame.php?model=%@&systemName=%@&systemVersion=%@&uid=%@&appVersion=%@&conCnt=%d&jb=%d",
							[[Misc getPlatform] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
							[[[UIDevice currentDevice] systemName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
							[[[UIDevice currentDevice] systemVersion] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
							[[[UIDevice currentDevice] uniqueIdentifier] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
							(NSString*)appVersion, 
							connectionAttempts, [Misc deviceHasJailBreak]
							];
	
	NSURL *url = [NSURL URLWithString:requestUrl];
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	return requestObj;
}


- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *MyIdentifier = @"MyIdentifier";
	static NSString *AdIdentifier = @"AdIdentifier";

	if ([indexPath section] == XPVSADSECTIONID)
	{
		UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:AdIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:AdIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(15.0, 8.0, 275.0, 16.0)] autorelease];
			label.font = [UIFont boldSystemFontOfSize:15.0];
			label.text = @"Thinstuff News Ticker";

			[cell.contentView addSubview:label];

			newsView = [[[UIWebView alloc] initWithFrame:CGRectMake(15.0, 26.0, 275, 20.0)] retain];
			newsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
			
			newsView.scalesPageToFit = NO;
			newsView.detectsPhoneNumbers = NO;
						
			newsView.delegate = self;
				
			[newsView loadRequest:[self getNewsTickerURL]];
			
			[cell.contentView addSubview:newsView];		
		}
		return cell;	
	}
	
	UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) 
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}
	
	// Configure the cell
	cell.hidesAccessoryWhenEditing = YES;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	int serverIndex = [indexPath indexAtPosition:[indexPath length] - 1];
	cell.text = [[bookmarkedServers objectAtIndex:serverIndex] valueForKey:@"title"];
	return cell;
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{	
	if ([[[request URL] scheme] isEqualToString:@"irdesktopapp"])
	{
		if ([[[request URL] host] isEqualToString:@"PROMOTIONINFO"])
		{
			[self launchAdView];
		}		
		return (NO);
	}
	if ([[[request URL] path] rangeOfString:@"iRdesktopFrame.php"].location != NSNotFound) {
		return (YES);
	}
	[[UIApplication sharedApplication] openURL:[request URL]];	
	return (NO);
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)_tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == XPVSADSECTIONID)
		return UITableViewCellAccessoryNone;
	else
		return UITableViewCellAccessoryDetailDisclosureButton;
}

- (NSIndexPath *)tableView:(UITableView *)_tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (canSelectAServer)
	{
		return indexPath;
	}
	return nil;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == XPVSADSECTIONID)
	{
		//[self launchAdView];
		return;
	}
	//Configure the cell.
	canSelectAServer = NO;
	int index = [indexPath indexAtPosition:([indexPath length] - 1)];
	UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
	cell.selectedTextColor = [UIColor blackColor];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	//Build and configure a new accessory view containing a red Abort UIButton and a UIActivityIndicatorView
	UIView *accView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 94, 35)];
	
	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage *cancelImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AbortButton" ofType:@"png"]];
	cancelButton.frame = CGRectMake(0.0, 0.0, 63.0, 33.0);
	[cancelButton setBackgroundImage:cancelImage forState:UIControlStateNormal];
	[cancelButton setTitle:@"Abort" forState:UIControlStateNormal];
	[cancelButton addTarget:self action:@selector(userDidCancelLastConnectRequest) forControlEvents:UIControlEventTouchDown];
	cancelButton.font = [UIFont boldSystemFontOfSize:14];
	
	UIActivityIndicatorView *gear = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	gear.frame = CGRectMake(68.0, 5.5, 22.0, 22.0);
	[gear startAnimating];
	
	[accView addSubview:gear];
	[accView addSubview:cancelButton];
	cell.accessoryView = accView;
	cell.accessoryType = UITableViewCellAccessoryNone;
	[accView release];
	
	//Disable toolbar buttons while trying to connect
	[self disableInterface];

	// save connection stats
	++connectionAttempts;
	[self storeSettings];
	
	//Start up the connection.
	self.tableView.scrollEnabled = NO;
	[delegate connectToServerWithConnectionSettings:[bookmarkedServers objectAtIndex:index] withCellIndex:indexPath];
}

- (void)tableView:(UITableView *)_tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == XPVSADSECTIONID)
	{
		return;
	}
	int index = [indexPath indexAtPosition:([indexPath length] - 1)];
	
	NewServerTableViewController *connViewController = [[NewServerTableViewController alloc] initWithStyle:UITableViewStyleGrouped settings:[bookmarkedServers objectAtIndex:index] fromServerList:bookmarkedServers];
	[connViewController.navigationItem setTitle:[[bookmarkedServers objectAtIndex:index] valueForKey:@"title"]];
	[self.navigationController pushViewController:connViewController animated:YES];
}

- (void)tableView:(UITableView *)_tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath 
{
	int fromIndex = [fromIndexPath indexAtPosition:[fromIndexPath length] - 1];
	int toIndex = [toIndexPath indexAtPosition:[toIndexPath length] - 1];
	
	id selectedServer = [[bookmarkedServers objectAtIndex:fromIndex] retain];
	[bookmarkedServers removeObject:selectedServer];

	if (toIndex < fromIndex)
	{
		[bookmarkedServers insertObject:selectedServer atIndex:toIndex];
	}
	else
	{
		[bookmarkedServers insertObject:selectedServer atIndex:toIndex];
	}
	if (!settingsRoot)
	{
		NSLog(@"No settings root");
	}
	[settingsRoot setValue:bookmarkedServers forKey:@"Servers"];
	[selectedServer release];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if(proposedDestinationIndexPath.section == XPVSADSECTIONID)
    {
        return sourceIndexPath;
    }
    else
    {
        return proposedDestinationIndexPath;
    }
}

- (BOOL)tableView:(UITableView *)_tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if ([indexPath section] == XPVSADSECTIONID)
	{
		return FALSE;
	}
	return YES;
}

- (BOOL)tableView:(UITableView *)_tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == XPVSADSECTIONID)
	{
		return FALSE;
	}
	return YES;
}

- (void)tableView:(UITableView *)_tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		int index = [indexPath indexAtPosition:([indexPath length] - 1)];
		[KeychainServices removeGenericPasswordForConnectionSettings:[bookmarkedServers objectAtIndex:index]];
		[bookmarkedServers removeObjectAtIndex:index];
		[settingsRoot setValue:bookmarkedServers forKey:@"Servers"];
		[self saveToPropertyList];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:YES];
	}
}

- (void)storeSettings
{
	NSUserDefaults* stdUserDefaults = [NSUserDefaults standardUserDefaults];
	if(stdUserDefaults)
	{
		[stdUserDefaults setInteger:connectionAttempts forKey:@"connectionAttempts"];
		[stdUserDefaults synchronize];
	}
}

- (void)reloadNewsTicker
{
	[newsView loadRequest:[self getNewsTickerURL]];	
}

- (void)dealloc 
{
	[newsView release];	
	[bookmarkedServers release];
	[settingsRoot release];
	[super dealloc];
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated 
{
	[self.tableView reloadData];
	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning];
}

- (void)saveToPropertyList
{
	NSMutableArray *servers = [[settingsRoot objectForKey:@"Servers"] mutableCopy];
	int i = 0 ;
	for (i = 0 ; i < servers.count ; i++)
	{
		[[servers objectAtIndex:i] removeObjectForKey:@"password"];
	}
    NSString *error = nil;
    NSData *pData = [NSPropertyListSerialization dataFromPropertyList:settingsRoot format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
	if (!pData) 
	{
        NSLog(@"Save Error: %@", error);
		NSLog(@"%@", settingsRoot);
        //return NO; 
    }
    [self writeApplicationData:pData toFile:@"settings.plist"];
	[servers release];
}

- (BOOL)writeApplicationData:(NSData *)data toFile:(NSString *)fileName
{ 
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	if (!documentsDirectory) 
	{
		NSLog(@"Documents directory not found!");
		return NO;
	}
	NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"settings.plist"];
	return ([data writeToFile:appFile atomically:YES]);
}

- (id)applicationPlistFromFile:(NSString *)fileName
{
    NSData *retData;
    NSString *error = nil;
    id retPlist;
	NSPropertyListFormat format;
	
    retData = [self applicationDataFromFile:fileName];
    if (!retData) 
	{
        //The settings.plist file doesn't exist.  Return an empty plist structure to be saved later on.
		NSMutableDictionary *root = [[[NSMutableDictionary alloc] initWithCapacity:2] autorelease];
		NSMutableArray *bookmarks = [[NSMutableArray alloc] initWithCapacity:0];
		NSMutableArray *recents = [[NSMutableArray alloc] initWithCapacity:0];
		[root setValue:bookmarks forKey:@"Servers"];
		[root setValue:recents forKey:@"Recents"];
		[recents release];
		[bookmarks release];
		
		return root;
    }
	else
	{
		retPlist = [NSPropertyListSerialization propertyListFromData:retData  mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&error];
		if (!retPlist)
		{
			NSLog(@"Plist not returned, error: %@", error);
		}
		return retPlist;
	}
}

- (NSData *)applicationDataFromFile:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSData *myData = [[[NSData alloc] initWithContentsOfFile:appFile] autorelease];
    return myData;
}

- (void)saveNewServer
{
	// Add the new server's password for the keychain
	NSMutableDictionary *connectionSettings = [newServerTableViewController connectionSettings];
	[KeychainServices addGenericPasswordForConnectionSettings:connectionSettings];
	
	// Add the new server's data to the bookmarkedServers property list and save to settings.plist.
	[bookmarkedServers addObject:connectionSettings];
	[settingsRoot setValue:bookmarkedServers forKey:@"Servers"];
	[self saveToPropertyList];
	[self closeNewServerEditor];
}

- (void)setCanSelectAServer:(BOOL)canSelect
{
	canSelectAServer = canSelect;
}

//////////////////////////////////////////////
/// UINavigationControllerDelegate Methods ///
//////////////////////////////////////////////
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if (viewController == self)
	{
		if (cachedToolbarButtons)
		{
			[[delegate mainToolbar] setItems:cachedToolbarButtons animated:YES];
			[cachedToolbarButtons release];
			cachedToolbarButtons = nil;
		}
		[self saveToPropertyList];
		[self.tableView reloadData];
	}
	else if (viewController != self)
	{
		if (!cachedToolbarButtons)
		{
			cachedToolbarButtons = [[[delegate mainToolbar] items] retain];
			[[delegate mainToolbar] setItems:nil animated:YES];
		}
	}
}



@end

