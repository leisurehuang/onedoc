/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDCViewController.h
 Copyright (C) Carter Harrison   2008-2009
 
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
#import "RDInstance.h"
#import "RDCKeyboard.h"
#import "miscellany.h"
#import "RDCView.h"
#import "FlippedPageView.h"
#import "KeychainServices.h"
#import "RDCScrollView.h"

#define kRDCToolbarHeight			30
#define kKeyboardHeightPortrait		215
#define kKeyboardHeightLandscape	160

@interface RDCViewController : UIViewController <UITextFieldDelegate, RDInstanceDelegate, UIScrollViewDelegate, UIActionSheetDelegate>
{
	RDInstance *rd;
	IBOutlet FlippedPageView *flippedPageView;
	UIScrollView *scrollView;
	UITextField *textField;
	BOOL keyboardDeployed;
	BOOL keyboardComboDeployed;
	BOOL isViewFlipped;
	id delegate;
	NSDictionary *connectionSettings;
	UIToolbar *rdcToolbar;
	UIBarButtonItem *mouseToolbarButton;
}

//////////////////
// Initializers //
//////////////////
- (id)initWithConnectionSettingsDictionary:(NSDictionary *)connSettings delegate:(id)object;

///////////////
// Accessors //
///////////////
- (FlippedPageView *)flippedPageView;
- (UIScrollView *)scrollView;
- (RDCView *)rdcView;
- (RDInstance *)rdInstance;
- (BOOL)isViewFlipped;
- (void)setIsViewFlipped:(BOOL)flipped;
- (NSString *)title;
- (NSString *)host;
- (int)screenHeight;
- (int)screenWidth;

/////////////////////////////////////////////
// Methods to support building UI elements //
/////////////////////////////////////////////
- (void)setupView;
- (UIScrollView *)buildScrollView;
- (UITextField *)buildTextField;
- (UIToolbar *)buildRDCToolbar;
- (void)hideRDCToolbar;
- (void)showRDCToolbar;
- (void)deployActionsMenu;

//////////////////////////////////
// UITextField Delegate Methods //
//////////////////////////////////
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

///////////////////////////////////
/// RDInstance Delegate Methods ///
///////////////////////////////////
- (void)instanceDidDisconnect:(RDInstance *)instance;
- (void)instanceDidConnect:(RDInstance *)instance;
- (void)instanceDidFailToConnect:(RDInstance *)instance;
- (void)setCursor:(CGImageRef)cursor;

//////////////////////////
// GUI Callback Methods //
//////////////////////////
- (void)toggleKeyboard;
- (BOOL)isKeyboardToggled;
- (IBAction)connect;
- (void)updateScrollViewAfterOrientationChange;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

/////////////////////////////////////
/// UIScrollView Delegate Methods ///
/////////////////////////////////////
- (UIView *)scrollViewWillBeginZooming:(UIScrollView *)scrollView;
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)newScale;

////////////////////////////////
/// Delegate Related Methods ///
////////////////////////////////
- (void)setDelegate:(id)object;
- (id)delegate;

@end

@protocol RDCViewControllerDelegate
- (void)rdcViewControllerDidConnect:(RDCViewController *)controller;
- (void)rdcViewControllerDidDisconnect:(RDCViewController *)controller;
- (void)rdcViewControllerDidFailToConnect:(RDCViewController *)controller;
- (void)rdcViewControllerDidMinimize;
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation withController:(RDCViewController *)controller;
@end

