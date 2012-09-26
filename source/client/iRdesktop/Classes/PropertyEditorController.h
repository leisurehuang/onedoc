/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 PropertyEditorController.h
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


@interface PropertyEditorController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
{
	IBOutlet UITextField *textField;
	IBOutlet UISegmentedControl *segmentControl;
	IBOutlet UITableView *resTableView;
	int propertyType;
	NSString *textValue;
	int colorDepth;
	int resolutionWidth;
	int resolutionHeight;
	int port;
	NSArray *availableResolutions;		//To add or remove resolutions that can be selected, just
										//add or remove values from this array.
}

- (id)initWithPropertyType:(int)type;
- (void)setTextValue:(NSString *)text;
- (void)setColorValue:(int)depth;
- (void)setResolutionWidth:(int)width height:(int)height;
- (int)screenWidth;
- (int)screenHeight;
- (int)propertyType;
- (int)colorDepth;
- (int)port;
- (UISegmentedControl *)segmentControl;
- (UITextField *)textField;

//////////////////////
/// Helper Methods ///
//////////////////////

///////////////////////////////////
/// UITextFieldDelegate Methods ///
///////////////////////////////////
- (BOOL)textFieldShouldReturn:(UITextField *)textField;

////////////////////////////////////
/// UITableView Delegate Methods ///
////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

typedef enum {
	PropertyTypeColorDepth,
	PropertyTypeResolution,
	PropertyTypeTitle,
	PropertyTypeHostname,
	PropertyTypeUsername,
	PropertyTypePassword,
	PropertyTypeDomain,
	PropertyTypePort,
} PropertyType;

typedef enum {
	PropertyColorDepthHundreds,
	PropertyColorDepthThousands,
	PropertyColorDepthMillions
} PropertyColorDepth;

@end
