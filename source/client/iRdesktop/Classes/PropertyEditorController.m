/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 PropertyEditorController.m
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


#import "PropertyEditorController.h"


@implementation PropertyEditorController

- (id)initWithPropertyType:(int)type
{
	NSString *nibNameOrNil;
	propertyType = type;
	switch (type) 
	{
		case PropertyTypeTitle:
			nibNameOrNil = @"PropertyEditorText";
			break;
		case PropertyTypeUsername:
			nibNameOrNil = @"PropertyEditorText";
			break;
		case PropertyTypeDomain:
			nibNameOrNil = @"PropertyEditorText";
			break;
		case PropertyTypeHostname:
			nibNameOrNil = @"PropertyEditorText";
			break;
		case PropertyTypePassword:
			nibNameOrNil = @"PropertyEditorSecureText";
			break;
		case PropertyTypeColorDepth:
			nibNameOrNil = @"PropertyEditorColors";
			break;
		case PropertyTypeResolution:
			nibNameOrNil = @"PropertyEditorResolution";
			availableResolutions = [[NSArray alloc] initWithObjects:@"640 x 480", @"720 x 480", @"800 x 500", @"800 x 600", @"1024 x 640", @"1024 x 768", @"1152 x 720", @"1280 x 1024", @"1440 x 900", nil];
			break;
		case PropertyTypePort:
			nibNameOrNil = @"PropertyEditorNumber";
			break;
		default:
			nibNameOrNil = nil;
			break;
	}
	if (self = [super initWithNibName:nibNameOrNil bundle:nil]) 
	{
		// Initialization code
		if (nibNameOrNil == @"PropertyEditorResolution")
		{
			[resTableView setDelegate:self];
			[resTableView setDataSource:self];
		}
	}
	return self;
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	if (propertyType == PropertyTypeHostname || propertyType == PropertyTypePort || propertyType == PropertyTypePassword || propertyType == PropertyTypeDomain || propertyType == PropertyTypeUsername || propertyType == PropertyTypeTitle)
	{
		textField.clearButtonMode = UITextFieldViewModeAlways;
		textField.clearsOnBeginEditing = NO;
		if (textValue != nil)
		{
			textField.text = textValue;
		}
		textField.font = [textField.font fontWithSize:18];
		textField.textColor = [UIColor colorWithRed:.392 green:.466 blue:.65 alpha:1.0];
		textField.returnKeyType = UIReturnKeyDone;
		if (propertyType == PropertyTypeTitle)
		{
			textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
		}
		if (propertyType == PropertyTypeHostname)
		{
			textField.keyboardType = UIKeyboardTypeURL;
		}
		if (propertyType == PropertyTypePort)
		{
			textField.keyboardType = UIKeyboardTypeNumberPad;
		}
		[textField setDelegate:self];
		[textField becomeFirstResponder];
	}
	else if (propertyType == PropertyTypeColorDepth)
	{
		if (segmentControl != nil)
		{
			segmentControl.selectedSegmentIndex = colorDepth;
		}
	}
	else if (propertyType == PropertyTypeResolution)
	{
		if (resTableView != nil)
		{
			[resTableView setDelegate:self];
			[resTableView setDataSource:self];
			[resTableView reloadData];
		}
	}
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		CGSize size = {500, 600}; // size of view in popover
		self.contentSizeForViewInPopover = size;
	}
}

- (void)setTextValue:(NSString *)text
{
	if (propertyType == PropertyTypePort || propertyType == PropertyTypeHostname || propertyType == PropertyTypePassword || propertyType == PropertyTypeDomain || propertyType == PropertyTypeUsername || propertyType == PropertyTypeTitle)
	{
		textValue = text;
	}
}

- (void)setColorValue:(int)depth
{
	if (propertyType == PropertyTypeColorDepth)
	{
		colorDepth = depth;
	}
}

- (void)setResolutionWidth:(int)width height:(int)height;
{
	if (propertyType == PropertyTypeResolution)
	{
		resolutionWidth = width;
		resolutionHeight = height;
	}
}

- (void)setPortNumber:(int)aPort
{
	if (propertyType == PropertyTypePort)
	{
		port = aPort;
	}
}

- (int)screenWidth
{
	return resolutionWidth;
}

- (int)screenHeight
{
	return resolutionHeight;
}

- (int)propertyType
{
	return propertyType;
}

- (int)colorDepth
{
	return colorDepth;
}

- (int)port
{
	return [textField.text intValue];
}

- (UISegmentedControl *)segmentControl
{
	return segmentControl;
}

- (UITextField *)textField
{
	return textField;
}

///////////////////////////////////
/// UITextFieldDelegate Methods ///
///////////////////////////////////
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[[self.navigationItem.rightBarButtonItem target] performSelector:[self.navigationItem.rightBarButtonItem action]];
	return NO;
}

////////////////////////////////////
/// UITableView Delegate Methods ///
////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return availableResolutions.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[NSBundle mainBundle] localizedStringForKey:@"SelectResolution" value:@"Select Resolution" table:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *resolutionString = [NSString stringWithFormat:@"%d x %d", resolutionWidth, resolutionHeight];
	int row = [indexPath indexAtPosition:1];
	static NSString *MyIdentifier = @"ResolutionCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (!cell)
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}
	
	cell.text = [availableResolutions objectAtIndex:row];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	if ([[availableResolutions objectAtIndex:row] isEqualToString:resolutionString])
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//Remove the checkmark from this cell.
	int i = 0;
	for (i = 0 ; i < availableResolutions.count ; i++)
	{
		NSUInteger ints[2] = {0, i};
		UITableViewCell *thisCell = [resTableView cellForRowAtIndexPath:[NSIndexPath indexPathWithIndexes:ints length:2]];
		if (thisCell.accessoryType == UITableViewCellAccessoryCheckmark)
		{
			thisCell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
	//Add a checkmark to this cell
	UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
	selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
	int row = [indexPath indexAtPosition:1];
	NSArray *resValues = [[availableResolutions objectAtIndex:row] componentsSeparatedByString:@" x "];
	resolutionWidth = [[resValues objectAtIndex:0] intValue];
	resolutionHeight = [[resValues objectAtIndex:1] intValue];
}

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)dealloc 
{
	if (availableResolutions)
	{
		[availableResolutions release];
	}
	[super dealloc];
}


@end
