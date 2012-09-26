/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 InfoViewController.m
 Copyright (C) Thinstuff s.r.o.  2009
 
 A UIViewController with an UIWebView main view for displaying product
 information. 
 
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

#import "InfoViewController.h"
#import "Misc.h"

@implementation InfoViewController

@synthesize webView;
@synthesize adMode;
@synthesize lastClickedLink;
@synthesize delegate;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
	 	 
	 self.webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
	 webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	 webView.autoresizesSubviews = YES;
	 webView.delegate = self;
	 
	 webView.detectsPhoneNumbers = NO;
	 
	 self.view = webView;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.lastClickedLink]];
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[webView reload];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{	
	if ([[request URL] isFileURL])
	{
		return (YES);
	}
	
	if (navigationType == UIWebViewNavigationTypeLinkClicked)
	{
		self.lastClickedLink = [[request URL] absoluteString];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"External Link" 
														message:[NSString stringWithFormat:@"Open [%@] in Safari ?", lastClickedLink]
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:@"No", nil];
		[alert show];
		[alert release];
				
		return(NO);
	}
	return(YES);
}

- (NSString*) getAppVersion
{
	CFStringRef appVersion = (CFStringRef)CFBundleGetValueForInfoDictionaryKey( CFBundleGetMainBundle() , kCFBundleVersionKey );
	CFRetain(appVersion);
	if( !appVersion )
	{
		appVersion = CFStringCreateCopy(kCFAllocatorDefault , CFSTR("1.0"));
	}
	return (NSString*)appVersion;
}

- (void)viewDidLoad 
{	
	[super viewDidLoad];
	
	NSString* promotionCode = [Misc getPromotionCode];
	
	NSString *htmlString1 = [NSString stringWithFormat:@""
							 "<html>"
							 "<head>"
							 "<meta name='viewport' content='width=device-width; initial-scale=1.0; maximum-scale=1.0;'>"
							 "<style type=\"text/css\">"
							 " body { background-color:#FFFFFF; color:#000000; font-family:Helvetica }"
							 " a:link { color:#0000FF; }"
							 "</style>" 
							 "</head>"
							 "<body>"
							 "<p style=\"border-width:2px; border-style:solid; padding:2px;\">"
							 "To get your discount for XP/VS Terminal Server visit <a href=\"http://www.thinstuff.com/promo/?id=irdesktop&code=%@\">www.thinstuff.com/promo</a> "
							 "and enter the following promotion code:<br><font color=\"blue\">%@</font></p>"
							 "Adding Thinstuff´s XP/VS Terminal Server software to a Windows workstation enables you to establish an "
							 "unlimited number of RDP connections to it. This turns your Windows workstation into a complete Terminal "
							 "Server and enables cost effective Server Based Computing. "
							 "The product supports all Windows XP and Vista flavours (even Home and 64-bit versions) and all Windows Server 2003/2008 versions (including Small Business editions)."
							 "</p>"
							 "<p>"
							 "You can download a free, fully functional demo version from <a href=\"http://www.thinstuff.com\">www.thinstuff.com</a>. </p>", promotionCode, promotionCode];
	

	NSString *htmlString2 = [NSString stringWithFormat:@""
							 "<html>"
							 "<head>"
							 "<meta name='viewport' content='width=device-width; initial-scale=1.0; maximum-scale=1.0;'>"
							 "<style type=\"text/css\">"
							 " body { background-color:#FFFFFF; color:#000000; font-family:Helvetica }"
							 " a:link { color:#0000FF; }"
							 "</style>" 
							 "</head>"
							 "<body>"
							 "<p><br>"
							 "Thinstuff iRdesktop is an open source client for Windows Terminal Services, "
							 "capable of natively using Remote Desktop Protocol (RDP) in order to remotely access your Windows desktop."
							 "</p>"
							 "<p>"
							 "<h4>Version Information</h4>"
							 "<table border=1 cellspacing=0 cellpadding=3 width=100%%></tr>"
							 "<tr>	<td>iRdesktop Version</td>		<td>%@</td>		</tr>"
							 "<tr>	<td>Wifi MAC Address</td>		<td>%@</td>		</tr>"
							 "<tr>	<td>System Name</td>			<td>%@</td>		</tr>"
							 "<tr>	<td>System Version</td>			<td>%@</td>		</tr>"
							 "<tr>	<td>Model</td>					<td>%@</td>		</tr>"
							 "</table>"
							 "</p>"
							 "<p>"
							 "<h4>Help & Support</h4>"
							 "Please go to <a href=\"http://www.iRdesktop.com/support\">www.iRdesktop.com/support</a> for setup and usage instructions."
							 "<h4>Unique Offer for iRdesktop Users</h4>"
							 "Thinstuff offers a software product called XP/VS Terminal Server that turns your Windows workstation "
							 "into a complete Terminal Server with multiple concurrent RDP connections. "
							 "The product supports all Windows XP and Vista flavours (even Home and 64-bit versions) and all Windows Server 2003/2008 versions (including Small Business editions)."
							 "<br>"
							 "You can download a free, fully functional demo version from our <a href=\"http://www.thinstuff.com\">website</a>. "
							 "If you like the product and are considering a purchase please remember that we have "
							 "a special discount for iRdesktop users for the single-user version. "
							 "For more info visit <a href=\"http://www.thinstuff.com/promo/?id=irdesktop&code=%@\">www.thinstuff.com/promo</a> "
							 "and enter the following promotion code:<br>%@"
							 "<h4>Credits</h4>"
							 "iRdesktop is based on <a href=\"http://www.iphonewinadmin.com/\">WinAdmin</a> "
							 "which is based on <a href=\"http://cord.sf.net/\">CoRD</a> "
							 "which is in turn based on of the Unix program <a href=\"http://www.rdesktop.org\">rdesktop</a>."
							 "</p>"
							 "<p>"
							 "<h4>License</h4>"
							 "This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by "
							 "the Free Software Foundation; either version 2 of the License, or (at your option) any later version."
							 "</p>"
							 "<p>"
							 "This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of "
							 "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the <a href=\"license.txt\">GNU General Public License</a> for more details. "
							 "</p>"
							 "<p>"
							 "A copy of the product's source code can be obtained from <a href=\"http://www.iRdesktop.com/gpl\">http://www.iRdesktop.com/gpl</a>."
							 "</p><br>"
							 , 
							 [self getAppVersion],
							 [Misc getPrimaryMACAddress:@":"],
							 [[UIDevice currentDevice] systemName],
							 [[UIDevice currentDevice] systemVersion],
							 [[UIDevice currentDevice] model],
							 promotionCode, 
							 promotionCode];

	[webView loadHTMLString:adMode?htmlString1:htmlString2 baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}


@end
