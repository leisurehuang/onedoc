/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 NewServerTableViewController.m
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


#import "NewServerTableViewController.h"



@implementation NewServerTableViewController


- (id)initWithStyle:(UITableViewStyle)style 
{
	noKeyChainUpdate = YES;
	return [super initWithStyle:style];
}

- (id)initWithStyle:(UITableViewStyle)style settings:(NSDictionary *)settings fromServerList:(NSMutableArray *)servers
{
	noKeyChainUpdate = NO;
	if (self = [super initWithStyle:style]) 
	{
		connectionSettings = [settings retain];
		serverList = [servers retain];
		[connectionSettings setValue:[KeychainServices retrieveGenericPasswordForConnectionSettings:connectionSettings] forKey:@"password"];
		
		if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		{
			self.tableView.tableFooterView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
			((UILabel*)self.tableView.tableFooterView).text = @" ";		
			((UILabel*)self.tableView.tableFooterView).backgroundColor = [UIColor clearColor];
		}
	}
	return self;
}

- (CGSize)getPopoverSize
{
	return CGSizeMake(500, 600);
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	self.tableView.delegate = self;
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		self.contentSizeForViewInPopover = [self getPopoverSize];
    }	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}

- (void)resetConnectionSettingsToNew
{
	if (connectionSettings)
	{
		[connectionSettings release];
	}
	connectionSettings = [[NSMutableDictionary alloc] initWithCapacity:7];
	[connectionSettings setValue:@"Hundreds" forKey:@"colordepth"];
	[connectionSettings setValue:[NSNumber numberWithInt:640] forKey:@"screenwidth"];
	[connectionSettings setValue:[NSNumber numberWithInt:480] forKey:@"screenheight"];
	[connectionSettings setValue:@"" forKey:@"domain"];
	[connectionSettings setValue:[NSNumber numberWithInt:8] forKey:@"colordepth"];
	[connectionSettings setValue:[NSNumber numberWithInt:3389] forKey:@"port"];
	[connectionSettings setValue:[NSNumber numberWithBool:NO] forKey:@"console"];
	[connectionSettings setValue:@"" forKey:@"title"];
	[connectionSettings setValue:@"" forKey:@"username"];
	[connectionSettings setValue:@"" forKey:@"hostname"];
	[connectionSettings setValue:@"" forKey:@"password"];	
	[self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if(section == 0)
		return 6;
	else
		return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int section = [indexPath indexAtPosition:0];
	int row = [indexPath indexAtPosition:1];
	UITableViewCell *cell;

	static NSString *MyIdentifier = @"PropertyCell";
	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:MyIdentifier] autorelease];


	//Configure other cell properties
	cell.selectionStyle = UITableViewCellSelectionStyleNone;	
	
	//Add the text to the cell
	NSString *subtitle;
	NSString *value;

	if(section == 0)
	{
		switch (row) 
		{
			case 0:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"EditTitle" value:@"Edit Title" table:nil];
				value = [connectionSettings valueForKey:@"title"];			
				txtTitle = [self UITextFieldForSubtitle:subtitle value:value secure:NO rec:CGRectInset(cell.contentView.bounds, 10, 10)];
				[cell.contentView addSubview:txtTitle];
				break;
			case 1:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"EditHostname" value:@"Edit Hostname" table:nil];
				value = [connectionSettings valueForKey:@"hostname"];
				txtHostname = [self UITextFieldForSubtitle:subtitle value:value secure:NO rec:CGRectInset(cell.contentView.bounds, 10, 10)];
				[cell.contentView addSubview:txtHostname];
				break;
			case 2:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"EditUsername" value:@"Edit Username" table:nil];
				value = [connectionSettings valueForKey:@"username"];
				txtUserName = [self UITextFieldForSubtitle:subtitle value:value secure:NO rec:CGRectInset(cell.contentView.bounds, 10, 10)];
				[cell.contentView addSubview:txtUserName];
				break;
			case 3:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"EditPassword" value:@"Edit Password" table:nil];
				//value = [KeychainServices retrieveGenericPasswordForConnectionSettings:connectionSettings];
				value = [connectionSettings valueForKey:@"password"];
				txtPassword = [self UITextFieldForSubtitle:subtitle value:value secure:YES rec:CGRectInset(cell.contentView.bounds, 10, 10)];
				[cell.contentView addSubview:txtPassword];
				break;
			case 4:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"EditDomain" value:@"Edit Domain" table:nil];
				value = [connectionSettings valueForKey:@"domain"];
				txtDomain = [self UITextFieldForSubtitle:subtitle value:value secure:NO rec:CGRectInset(cell.contentView.bounds, 10, 10)];
				[cell.contentView addSubview:txtDomain];
				break;
			case 5:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"EditPort" value:@"Edit Port" table:nil];
				value = [NSString stringWithFormat:@"%d", [[connectionSettings valueForKey:@"port"] intValue]];
				txtPort = [self UITextFieldForSubtitle:subtitle value:value secure:NO rec:CGRectInset(cell.contentView.bounds, 10, 10)];
				[cell.contentView addSubview:txtPort];
				break;			
		}			
	}
	else if(section == 1)
	{
		switch(row)
		{
			case 0:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"EditColors" value:@"Edit Colors" table:nil];
				if ([[connectionSettings valueForKey:@"colordepth"] intValue] == 16)
					value = [[NSBundle mainBundle] localizedStringForKey:@"Thousands" value:[[NSBundle mainBundle] localizedStringForKey:@"Thousands" value:@"Thousands" table:nil] table:nil];
				else if ([[connectionSettings valueForKey:@"colordepth"] intValue] == 32)
					value = [[NSBundle mainBundle] localizedStringForKey:@"Millions" value:@"Millions" table:nil];
				else
					//Default value
					value = [[NSBundle mainBundle] localizedStringForKey:@"Hundreds" value:@"Hundreds" table:nil];
				cell.textLabel.text = subtitle;
				cell.detailTextLabel.text = value;										
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
				if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
				{
					cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
					cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
				}
				break;
			
			
			case 1:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"EditResolution" value:@"Edit Resolution" table:nil];
				value = [NSString stringWithFormat:@"%d x %d", [[connectionSettings valueForKey:@"screenwidth"] intValue], [[connectionSettings valueForKey:@"screenheight"] intValue]];
				cell.textLabel.text = subtitle;
				cell.detailTextLabel.text = value;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

				if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
				{
					cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
					cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
				}
				break;
		}
	}
	else
	{
		switch(row)
		{
			case 0:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"ConnectToConsole" value:@"Use Console" table:nil];
				value = @"";
				CGRect frameRect1;
				if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				{
					if(self.view.bounds.size.width < 600)
						frameRect1 = CGRectMake(self.view.bounds.size.width - 165, 9.0, 1.0, 1.0);				
					else
						frameRect1 = CGRectMake(self.view.bounds.size.width - 195, 9.0, 1.0, 1.0);				
				}
				else
					frameRect1 = CGRectMake(self.view.bounds.size.width - 125, 9.0, 1.0, 1.0);							
				consoleSwitch = [[UISwitch alloc] initWithFrame:frameRect1];
				[consoleSwitch setOn:[[connectionSettings valueForKey:@"console"] boolValue] animated:NO];
				[consoleSwitch addTarget:self action:@selector(userDidChangeConsoleSetting) forControlEvents:UIControlEventValueChanged];
				[cell.contentView addSubview:consoleSwitch];
				cell.accessoryType = UITableViewCellAccessoryNone;
				[consoleSwitch release];
				cell.textLabel.text = subtitle;
				if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
					cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
				break;
			case 1:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"SoundOnServer" value:@"Leave Sound on Server" table:nil];
				value = @"";
				CGRect frameRect2;
				if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				{
					if(self.view.bounds.size.width < 600)
						frameRect2 = CGRectMake(self.view.bounds.size.width - 165, 9.0, 1.0, 1.0);				
					else
						frameRect2 = CGRectMake(self.view.bounds.size.width - 195, 9.0, 1.0, 1.0);				
				}
				else
					frameRect2 = CGRectMake(self.view.bounds.size.width - 125, 9.0, 1.0, 1.0);							
				soundOnServerSwitch = [[UISwitch alloc] initWithFrame:frameRect2];
				[soundOnServerSwitch setOn:[[connectionSettings valueForKey:@"srvsound"] boolValue] animated:NO];
				[soundOnServerSwitch addTarget:self action:@selector(userDidChangeSoundSetting) forControlEvents:UIControlEventValueChanged];
				[cell.contentView addSubview:soundOnServerSwitch];
				cell.accessoryType = UITableViewCellAccessoryNone;
				[soundOnServerSwitch release];	
				cell.textLabel.text = subtitle;
				if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
					cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
				break;
			default:
				break;
		}
	}
  
	return cell;
}


// Check if the "thing" pass'd is empty
static inline BOOL isEmpty(id thing) {
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

- (UITextField*) UITextFieldForSubtitle:(NSString *)subtitle value:(NSString*)value secure:(BOOL)secure rec:(CGRect)rec
{
	UITextField* txtField;
	txtField = [[[UITextField alloc] initWithFrame:rec] autorelease];
	txtField.placeholder = subtitle;
	if([value length] != 0)
		txtField.text = value;
	txtField.font = [UIFont systemFontOfSize:15];
	txtField.secureTextEntry = secure;
	txtField.returnKeyType = UIReturnKeyDone;
	txtField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	[txtField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	txtField.delegate = self;
	[txtField addTarget:self action:@selector(textFieldDone:) forControlEvents:UIControlEventEditingDidEndOnExit];
	return txtField;
	
}

- (void)textFieldDone:(id)sender
{
	[sender resignFirstResponder];
}

- (UILabel *)UILabelForSubtitle:(NSString *)subtitle
{
	UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 6, 150, 30)] autorelease];
	subtitleLabel.text = subtitle;
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		subtitleLabel.font = [UIFont boldSystemFontOfSize:15 ];
		subtitleLabel.backgroundColor = [UIColor groupTableViewBackgroundColor];
	}
	else
	{
		subtitleLabel.textColor = [UIColor colorWithRed:.392 green:.466 blue:.616 alpha:1.0];
		subtitleLabel.font = [UIFont systemFontOfSize:13];
	}
	[subtitleLabel setLineBreakMode:UILineBreakModeWordWrap];
	[subtitleLabel setNumberOfLines:0];
	return subtitleLabel;
}

- (UILabel *)UILabelForValue:(NSString *)value
{
	UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(176, 11, 100, 20)] autorelease];
	titleLabel.text = value;

	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		titleLabel.textAlignment = UITextAlignmentRight;
		titleLabel.backgroundColor = [UIColor groupTableViewBackgroundColor];
		titleLabel.font = [UIFont systemFontOfSize:15];
		titleLabel.textColor = [UIColor colorWithRed:0.0 green:0.25098 blue:0.501961 alpha:1.0];
	}
	else 
	{
		titleLabel.textAlignment = UITextAlignmentRight;
		titleLabel.font = [UIFont boldSystemFontOfSize:14];
	}

	return titleLabel;
}

- (NSDictionary *)connectionSettings
{
	if(!noKeyChainUpdate)
	{
		NSDictionary *cachedSettings = [connectionSettings copy];
		[connectionSettings setValue:txtTitle.text forKey:@"title"];
		[connectionSettings setValue:txtHostname.text forKey:@"hostname"];
		[connectionSettings setValue:txtUserName.text forKey:@"username"];
		if(txtPassword.text != nil)
			[connectionSettings setValue:txtPassword.text forKey:@"password"];
		else
			[connectionSettings setValue:@"" forKey:@"password"];
		[connectionSettings setValue:txtPort.text forKey:@"port"];		
		[KeychainServices updateGenericPasswordForConnectionSettings:cachedSettings withNewConnectionSettings:connectionSettings];
		[cachedSettings release];
	}
	else 
	{
		[connectionSettings setValue:txtTitle.text forKey:@"title"];
		[connectionSettings setValue:txtHostname.text forKey:@"hostname"];
		[connectionSettings setValue:txtUserName.text forKey:@"username"];
		if(txtPassword.text != nil)
			[connectionSettings setValue:txtPassword.text forKey:@"password"];
		else
			[connectionSettings setValue:@"" forKey:@"password"];
		[connectionSettings setValue:txtPort.text forKey:@"port"];			
	}
	return connectionSettings;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int section = [indexPath indexAtPosition:0];
	int row = [indexPath indexAtPosition:1];
	
	PropertyEditorController *newController = nil;
	if(section == 1)
	{
		switch (row) 
		{
			case 0:
				newController = [[[PropertyEditorController alloc] initWithPropertyType:PropertyTypeColorDepth] autorelease];
				newController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"EditColors" value:@"Edit Colors" table:nil];
				switch ([[connectionSettings valueForKey:@"colordepth"] intValue])
				{
					case 8:
						[newController setColorValue:PropertyColorDepthHundreds];
						break;
					case 16:
						[newController setColorValue:PropertyColorDepthThousands];
						break;
					case 32:
						[newController setColorValue:PropertyColorDepthMillions];
						break;
					default:
						break;
				}
				break;
			case 1:
				newController = [[[PropertyEditorController alloc] initWithPropertyType:PropertyTypeResolution] autorelease];
				[newController setResolutionWidth:[[connectionSettings valueForKey:@"screenwidth"] intValue] 
										   height:[[connectionSettings valueForKey:@"screenheight"] intValue]];
				newController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"EditResolution" value:@"Edit Resolution" table:nil];
				break;
			default:
				break;
		}
	}
	if (newController != nil)
	{
		[newController.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveChangedProperty)]];
		[self.navigationController pushViewController:newController animated:YES];
	}

}

- (BOOL)isSaveButtonActive
{
	if ([connectionSettings valueForKey:@"title"] && [connectionSettings valueForKey:@"hostname"])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	NSString* key = [[NSString alloc] init];
	if(textField == txtTitle)
		key = @"title";
	if(textField == txtHostname)
		key = @"hostname";
	if(textField == txtUserName)
		key = @"username";
	if(textField == txtPassword)
		key = @"password";
	if(textField == txtDomain)
		key = @"domain";
	if(textField == txtPort)
		key = @"port";

	if(!noKeyChainUpdate)
	{
		NSDictionary *cachedSettings = [connectionSettings copy];
		[connectionSettings setValue:textField.text forKey:key];
		if(key == @"password" || key == @"title" || key == @"username" || key == @"hostname")
		{
			if(key == @"password" && textField.text == nil)
				[connectionSettings setValue:@"" forKey:@"password"];
			[KeychainServices updateGenericPasswordForConnectionSettings:cachedSettings withNewConnectionSettings:connectionSettings];
		}
		[cachedSettings release];
	}
	else
		[connectionSettings setValue:textField.text forKey:key];
		
	self.navigationItem.rightBarButtonItem.enabled = [self isSaveButtonActive];
}

//////////////////////////////////////
/// Property Save Callback Methods ///
//////////////////////////////////////
- (void)saveChangedProperty
{
	int type = [(PropertyEditorController *)[self.navigationController topViewController] propertyType];
	if (type == PropertyTypeColorDepth)
	{
		int chosenColor = [[(PropertyEditorController *)[self.navigationController topViewController] segmentControl] selectedSegmentIndex];
		switch (chosenColor) {
			case PropertyColorDepthHundreds:
				[connectionSettings setValue:[NSNumber numberWithInt:8] forKey:@"colordepth"];
				break;
			case PropertyColorDepthThousands:
				[connectionSettings setValue:[NSNumber numberWithInt:16] forKey:@"colordepth"];
				break;
			case PropertyColorDepthMillions:
				[connectionSettings setValue:[NSNumber numberWithInt:32] forKey:@"colordepth"];
				break;
			default:
				break;
		}
	}
	else if (type == PropertyTypeResolution)
	{
		[connectionSettings setValue:[NSNumber numberWithInt:[(PropertyEditorController *)[self.navigationController topViewController] screenWidth]] forKey:@"screenwidth"];
		[connectionSettings setValue:[NSNumber numberWithInt:[(PropertyEditorController *)[self.navigationController topViewController] screenHeight]] forKey:@"screenheight"];
	}
	
	[self.tableView reloadData];
	self.navigationItem.rightBarButtonItem.enabled = [self isSaveButtonActive];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)userDidChangeConsoleSetting
{
	[connectionSettings setValue:[NSNumber numberWithBool:consoleSwitch.on] forKey:@"console"];
}


- (void)userDidChangeSoundSetting
{
	[connectionSettings setValue:[NSNumber numberWithBool:soundOnServerSwitch.on] forKey:@"srvsound"];
}

- (void)dealloc 
{
	if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad && self.tableView.tableFooterView)
		[self.tableView.tableFooterView release];
	   
	[serverList release];
	[connectionSettings release];
	[consoleSwitch release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning];
}

@end