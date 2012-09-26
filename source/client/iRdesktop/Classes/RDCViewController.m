/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDCViewController.m
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


#import "RDCViewController.h"


@implementation RDCViewController

- (id)initWithConnectionSettingsDictionary:(NSDictionary *)connSettings delegate:(id)object
{
	if (self = [super initWithNibName:nil bundle:nil]) 
	{
		// Initialization code
		keyboardDeployed = NO;
		connectionSettings = [connSettings retain];
		NSString *host = [connectionSettings valueForKey:@"hostname"];
		NSString *username = [connectionSettings valueForKey:@"username"];
		NSString *password = [KeychainServices retrieveGenericPasswordForConnectionSettings:connSettings];
		NSString *domain = [connectionSettings valueForKey:@"domain"];
		int port = [[connectionSettings valueForKey:@"port"] intValue];
		int colorDepth = [[connectionSettings valueForKey:@"colordepth"] intValue];
		[self setDelegate:object];

		//Setup the RDInstance variables and attempt to connect.
		rd = [[RDInstance alloc] initWithHost:host userName:username password:password domain:domain colorDepth:colorDepth delegate:self];
		[rd setScreenWidth:[[connectionSettings valueForKey:@"screenwidth"] intValue]];
		[rd setScreenHeight:[[connectionSettings valueForKey:@"screenheight"] intValue]];
		[rd setPort:port];
		[rd useConsole:[[connectionSettings valueForKey:@"console"] boolValue]];
		[rd leaveSound:[[connectionSettings valueForKey:@"srvsound"] boolValue]];
		[rd performSelectorInBackground:@selector(connect:) withObject:delegate];

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
		[nc addObserver:self selector:@selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];	
	}
	return self;
}

- (void)dealloc 
{
	//Release UI Components
	[rdcToolbar release];
	[textField release];
	[scrollView release];
	[[self view] release];
	if (flippedPageView)
	{
		[flippedPageView release];
	}
	
	//Release RD Components
	[connectionSettings release];
	[rd release];
	
	//Finish up
	[super dealloc];
}

////////////////////////////
/// AutoRotation Methods ///
////////////////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (keyboardDeployed)
	{
		[self toggleKeyboard];
	}
}



///////////////
// Accessors //
///////////////
- (FlippedPageView *)flippedPageView
{
	if (!flippedPageView)
	{
		if (![[NSBundle mainBundle] loadNibNamed:@"FlippedPage" owner:self options:nil])
		{
			NSLog(@"Warning! Could not load FlippedPage NIB file.\n");
			return NO;
		}
	}
	flippedPageView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
	return flippedPageView;
}

- (UIScrollView *)scrollView
{
	return scrollView;
}

- (RDCView *)rdcView
{
	return [rd view];
}

- (RDInstance *)rdInstance
{
	return rd;
}

- (BOOL)isViewFlipped
{
	return isViewFlipped;
}

- (void)setIsViewFlipped:(BOOL)flipped
{
	isViewFlipped = flipped;
}

- (NSString *)title
{
	return [connectionSettings valueForKey:@"title"];
}

- (NSString *)host
{
	return [connectionSettings valueForKey:@"hostname"];
}

- (int)screenHeight
{
	return [[connectionSettings valueForKey:@"screenheight"] intValue];
}
- (int)screenWidth
{
	return [[connectionSettings valueForKey:@"screenwidth"] intValue];
}

/////////////////////////////////////////////
// Methods to support building UI elements //
/////////////////////////////////////////////
- (void)viewDidLoad 
{
	if ([rd status] == CRDConnectionConnected)
	{
		[self setupView];
	}
}

- (void)setupView
{
	if (!scrollView)
	{
		//Setup the scrollview
		scrollView = [self buildScrollView];
		
		//Setup the textview.  This is needed only to allow a keyboard to pop-up when we need it.
		textField = [self buildTextField];
		
		//Setup the rdcToolbar.
		rdcToolbar = [self buildRDCToolbar];
		
		//Setup the view instance variable.  This view will not do any drawing, but will containg several subviews
		self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
		[[self view] addSubview:scrollView];
		[scrollView setDelegate:self];
		[[self view] addSubview:textField];
	}
}

- (UIScrollView *)buildScrollView
{
	//Setup the scrollView.  The scrollView contains [rd view] 
	// -44 from height because of mainToolbar (otherwise parts will be covered by the main toolbar)
	RDCScrollView *sv = [[RDCScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height - 44)];
	sv.backgroundColor = [UIColor blackColor];
	sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
	sv.contentSize = CGSizeMake([[connectionSettings valueForKey:@"screenwidth"] intValue], [[connectionSettings valueForKey:@"screenheight"] intValue]);
	sv.maximumZoomScale = 3.0;
	sv.minimumZoomScale = sv.frame.size.height / [rd view].frame.size.height;
	sv.canCancelContentTouches = YES;

	[sv addSubview:(UIView *)[rd view]];
	return sv;
}

- (UITextField *)buildTextField
{
	UITextField *tv = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, .1, .1)];
	[tv setDelegate:self];
	tv.autocorrectionType = UITextAutocorrectionTypeNo;
	//tv.autocapitalizationType = UITextAutocapitalizationTypeSentences;
	tv.text = @"beginning text";
	return tv;
}

- (UIToolbar *)buildRDCToolbar
{
	//Create the toolbar
	UIToolbar *tb = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, -kRDCToolbarHeight, self.view.frame.size.width, kRDCToolbarHeight)];
	
	tb.barStyle = UIBarStyleBlackOpaque;
	tb.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	//Add toolbar buttons 
	//UIBarButtonItem *keyboardButton = [[UIBarButtonItem alloc] initWithTitle:@"ABC" style:UIBarButtonItemStylePlain target:self action:@selector(toggleKeyboard)];
	UIImage *keyboardImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Kbd" ofType:@"png"]];
	UIImage *windowsImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Windows" ofType:@"png"]];
	UIImage *actionImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Gear" ofType:@"png"]];
	UIBarButtonItem *keyboardButton = [[UIBarButtonItem alloc] initWithImage:keyboardImage style:UIBarButtonItemStylePlain target:delegate action:@selector(toggleKeyboard)];
	UIBarButtonItem *windowsButton = [[UIBarButtonItem alloc] initWithImage:windowsImage style:UIBarButtonItemStylePlain target:delegate action:@selector(rdcViewControllerDidMinimize)];
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithImage:actionImage style:UIBarButtonItemStylePlain target:self action:@selector(deployActionsMenu)];
	UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	fixedSpace.width = 20;
	tb.items = [NSArray arrayWithObjects:keyboardButton, fixedSpace, windowsButton, flexibleSpace, actionButton, nil];
	
	//Cleanup
	[keyboardButton release];
	[flexibleSpace release];
	[windowsButton release];
	[actionButton release];
	[fixedSpace release];
	return tb;
}

- (void)hideRDCToolbar
{
	[UIView beginAnimations:@"hideToolbar" context:nil];
	[UIView setAnimationDuration:.3];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	rdcToolbar.frame = CGRectMake(0.0, -kRDCToolbarHeight, self.view.frame.size.width, kRDCToolbarHeight);
	scrollView.frame = CGRectMake(0.0, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height - self.view.frame.origin.y);
	[UIView commitAnimations];
	[rdcToolbar removeFromSuperview];
}

- (void)showRDCToolbar
{
	if ([rdcToolbar superview] != self.view)
	{
		[self.view addSubview:rdcToolbar];
		rdcToolbar.frame = CGRectMake(0.0, -kRDCToolbarHeight, self.view.frame.size.width, kRDCToolbarHeight);
	}
	[UIView beginAnimations:@"showToolbar" context:nil];
	[UIView setAnimationDuration:.4];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
//	rdcToolbar.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, kRDCToolbarHeight);
	CGRect re = [UIScreen mainScreen].applicationFrame;
	rdcToolbar.frame = CGRectMake(0.0, self.view.frame.origin.y, self.view.frame.size.width, kRDCToolbarHeight);
	scrollView.frame = CGRectMake(0.0, self.view.frame.origin.y + kRDCToolbarHeight, self.view.frame.size.width, self.view.frame.size.height - kRDCToolbarHeight - self.view.frame.origin.y);
	[UIView commitAnimations];
}

- (void)deployActionsMenu
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Session Actions" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:0 otherButtonTitles:@"Send CTRL+ALT+DEL", @"Send Windows Key", nil];
	[actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
			[rd sendCTRLALTDELETE];
			break;
		case 1:
			[rd sendWINKEY];
			break;
		default:
			break;
	}
}

//////////////////////////////////
// UITextField Delegate Methods //
//////////////////////////////////
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	int i = 0;
	const char *current;	
	RDCKeyboard *keyboard = [[rd view] keyTranslator];
	
	if ([string length] > 0)
	{
		for (i = 0 ; i < [string length] ; i++)
		{
			NSString *characterTyped = [string substringWithRange:NSMakeRange(i, 1)];
			// If this is the space key then we need to hardcode the keycode.
			if (characterTyped == @" ")
			{
				[keyboard handleKeyCode:32 keyDown:YES];
				[keyboard handleKeyCode:32 keyDown:NO];
			}
			else if ([keyboard handleSpecialKey:characterTyped])
			{
				//Do nothing.  The method in the if statement will take care of sending the key for us.
			}
			// Otherwise this is regular input and we should be able to handle it.
			else
			{
				current = [[characterTyped dataUsingEncoding:1 allowLossyConversion:YES] bytes];
				if (current)
				{
					[keyboard handleKeyCode:(int)(*current) keyDown:YES];
					[keyboard handleKeyCode:(int)(*current) keyDown:NO];
				}
			}
		}
	}
	//Input has no length - we will assume that it is a backspace key.
	else
	{
		[keyboard handleKeyCode:8 keyDown:YES];
		[keyboard handleKeyCode:8 keyDown:NO];
	}
	return NO;
}

//////////////////////////////////
/// RDInstanceDelegate Methods ///
//////////////////////////////////
- (void)instanceDidDisconnect:(RDInstance *)instance;
{
	if (delegate)
	{
		[delegate rdcViewControllerDidDisconnect:self];
		[[instance view] removeFromSuperview];
	}
}

- (void)instanceDidConnect:(RDInstance *)instance
{
	if (delegate)
	{
		[[instance view] setFrame:CGRectMake(0.0, 0.0, [[connectionSettings valueForKey:@"screenwidth"] intValue], [[connectionSettings valueForKey:@"screenheight"] intValue])];
		if ([[instance view] superview] != scrollView)
		{
			[scrollView addSubview:[instance view]];
		}
		[delegate rdcViewControllerDidConnect:self];
	}
}

- (void)instanceDidFailToConnect:(RDInstance *)instance
{
	if (delegate)
	{
		[delegate rdcViewControllerDidFailToConnect:self];
	}
}

- (void)setCursor:(CGImageRef)cursor
{
	/*
	UIImage *cursorImage = [UIImage imageWithCGImage:cursor];
	CGDataProviderRef dataProvider = CGImageGetDataProvider(cursor);
	CFDataRef data = CGDataProviderCopyData(dataProvider);
	if (!mouseToolbarButton)
	{
		mouseToolbarButton = [[UIBarButtonItem alloc] initWithImage:cursorImage style:UIBarButtonItemStylePlain target:nil action:nil];
		NSArray *toolbarItems = rdcToolbar.items;
		NSMutableArray *mutableItems = [toolbarItems mutableCopy];
		[mutableItems addObject:mouseToolbarButton];
		rdcToolbar.items = mutableItems;
		[mutableItems release];
	}
	else
	{
		mouseToolbarButton.image = cursorImage;
	}
	if (data)
		CFRelease(data);
	 */
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	CGRect frame = scrollView.frame;
    frame = CGRectMake(0, self.view.frame.origin.y + kRDCToolbarHeight, self.view.frame.size.width, self.view.frame.size.height - [[[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey] CGRectValue].size.height - kRDCToolbarHeight - self.view.frame.origin.y);
	scrollView.frame = frame;
	[UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	CGRect frame = scrollView.frame;
    frame = CGRectMake(0, self.view.frame.origin.y + kRDCToolbarHeight, self.view.frame.size.width, self.view.frame.size.height - kRDCToolbarHeight - self.view.frame.origin.y);
	scrollView.frame = frame;
    [UIView commitAnimations];

	// explicitly set keyboard deployed to NO and resgin textField in case the keyboard is closed without using our toggle button
	[textField resignFirstResponder];
	keyboardDeployed = NO;
}

//////////////////////////
// GUI Callback Methods //
//////////////////////////
- (void)toggleKeyboard
{
	if (!keyboardDeployed)
	{
//		[UIView commitAnimations];
		[textField becomeFirstResponder];
		keyboardDeployed = YES;
	}
	else
	{
//		[UIView commitAnimations];
		[textField resignFirstResponder];
		keyboardDeployed = NO;
	}
}

- (BOOL)isKeyboardToggled
{
	return keyboardDeployed;
}


- (IBAction)connect;
{
	[rd performSelectorInBackground:@selector(connect:) withObject:delegate];
}

- (void)updateScrollViewAfterOrientationChange
{
	scrollView.frame = CGRectMake(0.0, kRDCToolbarHeight, self.view.frame.size.width, self.view.frame.size.height - kRDCToolbarHeight);
}

/////////////////////////////////////
/// UIScrollView Delegate Methods ///
/////////////////////////////////////
- (UIView *)scrollViewWillBeginZooming:(UIScrollView *)scrollView
{
	return (UIView *)[rd view];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return (UIView *)[rd view];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)newScale
{
	[[rd view] setNeedsDisplay];
}

////////////////////////////////
/// Delegate Related Methods ///
////////////////////////////////
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

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

@end
