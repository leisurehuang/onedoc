/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 NewServerTableViewController.h
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
#import "PropertyEditorController.h"
#import "KeychainServices.h"

@interface NewServerTableViewController : UITableViewController <UITextFieldDelegate, UITableViewDelegate>
{
	NSMutableDictionary *connectionSettings;
	NSMutableArray *serverList;
	UISwitch *consoleSwitch;
	UISwitch *soundOnServerSwitch;
	UITextField* txtTitle;
	UITextField* txtHostname;
	UITextField* txtDomain;
	UITextField* txtPassword;
	UITextField* txtPort;
	UITextField* txtUserName;
	BOOL noKeyChainUpdate;	// flag to distinguish between New/Edit mode
}

- (CGSize)getPopoverSize;
- (void)textFieldDidEndEditing:(UITextField *)textField;
- (UILabel *)UILabelForSubtitle:(NSString *)subtitle;
- (UILabel *)UILabelForValue:(NSString *)value;
- (UITextField*) UITextFieldForSubtitle:(NSString *)subtitle value:(NSString*)value secure:(BOOL)secure rec:(CGRect)rec;
- (NSMutableDictionary *)connectionSettings;
- (BOOL)isSaveButtonActive;
- (void)saveChangedProperty;
- (void)userDidChangeConsoleSetting;
- (void)userDidChangeSoundSetting;
- (void)resetConnectionSettingsToNew;

@end

