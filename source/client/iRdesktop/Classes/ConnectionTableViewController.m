/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 ConnectionTableViewController.m
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


#import "ConnectionTableViewController.h"

@implementation ConnectionTableViewController

- (id)initWithStyle:(UITableViewStyle)style settings:(NSDictionary *)settings fromServerList:(NSMutableArray *)servers;
{
	if (self = [super initWithStyle:style]) 
	{
		connectionSettings = [settings retain];
		serverList = [servers retain];
		[connectionSettings setValue:[KeychainServices retrieveGenericPasswordForConnectionSettings:connectionSettings] forKey:@"password"];
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return 10;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[NSBundle mainBundle] localizedStringForKey:@"ConnectionProperties" value:@"Connection aa Properties" table:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int section = [indexPath indexAtPosition:0];
	int row = [indexPath indexAtPosition:1];
	UITableViewCell *cell;

	if (section == 0)
	{
		static NSString *MyIdentifier = @"PropertyCell";
	
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
		
		//Add the text to the cell
		NSString *subtitle;
		NSString *value;
		
		//Configure other cell properties
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		
		switch (row) 
		{
			case 0:
				subtitle = @"title";
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"Title" value:@"title" table:nil];
				value = [connectionSettings valueForKey:@"title"];
				break;
			case 1:
				subtitle = @"hostname";
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"Hostname" value:@"hostname" table:nil];
				value = [connectionSettings valueForKey:@"hostname"];
				break;
			case 2:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"Username" value:@"username" table:nil];
				value = [connectionSettings valueForKey:@"username"];
				break;
			case 3:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"Password" value:@"password" table:nil];
				value = [connectionSettings valueForKey:@"password"];
				if (value && [value length] > 0)
				{
					value = @"<saved>";
				}
				break;
			case 4:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"Domain" value:@"domain" table:nil];
				value = [connectionSettings valueForKey:@"domain"];
				break;
			case 5:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"Colors" value:@"colors" table:nil];
				if ([[connectionSettings valueForKey:@"colordepth"] intValue] == 16)
					value = [[NSBundle mainBundle] localizedStringForKey:@"Thousands" value:@"Thousands" table:nil];
				else if ([[connectionSettings valueForKey:@"colordepth"] intValue] == 32)
					value = [[NSBundle mainBundle] localizedStringForKey:@"Millions" value:@"Millions" table:nil];
				else
					value = [[NSBundle mainBundle] localizedStringForKey:@"Hundreds" value:@"Hundreds" table:nil];
				break;
			case 6:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"Resolution" value:@"resolution" table:nil];
				value = [NSString stringWithFormat:@"%d x %d", [[connectionSettings valueForKey:@"screenwidth"] intValue], [[connectionSettings valueForKey:@"screenheight"] intValue]];
				break;
			case 7:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"Port" value:@"Port" table:nil];
				value = [NSString stringWithFormat:@"%d", [[connectionSettings valueForKey:@"port"] intValue]];
				break;
			case 8:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"ConnectToConsole" value:@"use console" table:nil];
				value = @"";
				consoleSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(167.0, 9.0, 1.0, 1.0)];
				[consoleSwitch setOn:[[connectionSettings valueForKey:@"console"] boolValue] animated:NO];
				[consoleSwitch addTarget:self action:@selector(userDidChangeConsoleSetting) forControlEvents:UIControlEventValueChanged];
				[cell.contentView addSubview:consoleSwitch];
				cell.accessoryType = UITableViewCellAccessoryNone;
				[consoleSwitch release];
				break;
			case 9:
				subtitle = [[NSBundle mainBundle] localizedStringForKey:@"SoundOnServer" value:@"Leave Sound on Server" table:nil];
				value = @"";
				soundOnServerSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(167.0, 9.0, 1.0, 1.0)];
				[soundOnServerSwitch setOn:[[connectionSettings valueForKey:@"srvsound"] boolValue] animated:NO];
				[soundOnServerSwitch addTarget:self action:@selector(userDidChangeSoundSetting) forControlEvents:UIControlEventValueChanged];
				[cell.contentView addSubview:soundOnServerSwitch];
				cell.accessoryType = UITableViewCellAccessoryNone;
				[soundOnServerSwitch release];
				break;
			default:
				break;
		}
		[cell.contentView addSubview:[self UILabelForSubtitle:subtitle]];
		if (row < 8)
		{
			[cell.contentView addSubview:[self UILabelForValue:value]];
		}
		
	}
	return cell;
}

- (UILabel *)UILabelForSubtitle:(NSString *)subtitle
{
	UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(15, 6, 90, 30)] autorelease];
	subtitleLabel.text = subtitle;
	subtitleLabel.textColor = [UIColor colorWithRed:.392 green:.466 blue:.616 alpha:1.0];
	subtitleLabel.textAlignment = UITextAlignmentRight;
	subtitleLabel.font = [UIFont systemFontOfSize:13];
	[subtitleLabel setLineBreakMode:UILineBreakModeWordWrap];
	[subtitleLabel setNumberOfLines:0];
	return subtitleLabel;
}

- (UILabel *)UILabelForValue:(NSString *)value
{
	UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(116, 11, 150, 20)] autorelease];
	titleLabel.text = value;
	titleLabel.textAlignment = UITextAlignmentLeft;
	titleLabel.font = [UIFont boldSystemFontOfSize:14];
	return titleLabel;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int section = [indexPath indexAtPosition:0];
	int row = [indexPath indexAtPosition:1];
	
	if (section == 0)
	{
		PropertyEditorController *newController;
		switch (row) 
		{
			case 0:
				newController = [[[PropertyEditorController alloc] initWithPropertyType:PropertyTypeTitle] autorelease];
				newController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"EditTitle" value:@"Edit Title" table:nil];
				[newController setTextValue:[connectionSettings valueForKey:@"title"]];
				break;
			case 1:
				newController = [[[PropertyEditorController alloc] initWithPropertyType:PropertyTypeHostname] autorelease];
				newController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"EditHostname" value:@"Edit Hostname" table:nil];
				[newController setTextValue:[connectionSettings valueForKey:@"hostname"]];
				break;
			case 2:
				newController = [[[PropertyEditorController alloc] initWithPropertyType:PropertyTypeUsername] autorelease];
				newController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"EditUsername" value:@"Edit Username" table:nil];
				[newController setTextValue:[connectionSettings valueForKey:@"username"]];
				break;
			case 3:
				newController = [[[PropertyEditorController alloc] initWithPropertyType:PropertyTypePassword] autorelease];
				newController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"EditPassword" value:@"Edit Password" table:nil];
				[newController setTextValue:[KeychainServices retrieveGenericPasswordForConnectionSettings:connectionSettings]];
				break;
			case 4:
				newController = [[[PropertyEditorController alloc] initWithPropertyType:PropertyTypeDomain] autorelease];
				newController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"EditDomain" value:@"Edit Domain" table:nil];
				[newController setTextValue:[connectionSettings valueForKey:@"domain"]];
				break;
			case 5:
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
			case 6:
				newController = [[[PropertyEditorController alloc] initWithPropertyType:PropertyTypeResolution] autorelease];
				[newController setResolutionWidth:[[connectionSettings valueForKey:@"screenwidth"] intValue] 
										   height:[[connectionSettings valueForKey:@"screenheight"] intValue]];
				newController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"EditResolution" value:@"Edit Resolution" table:nil];
				break;
			case 7:
				newController = [[[PropertyEditorController alloc] initWithPropertyType:PropertyTypePort] autorelease];
				[newController setTextValue:[[connectionSettings valueForKey:@"port"] stringValue]];
				newController.navigationItem.title = [[NSBundle mainBundle] localizedStringForKey:@"EditPort" value:@"Edit Port Number" table:nil];
				break;
			default:
				break;
		}
		if (row < 8)
		{
			[newController.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveChangedProperty)]];
			[self.navigationController pushViewController:newController animated:YES];
		}
	}
	else
	{
		//User selected the connect button.
	}
}

- (void)dealloc 
{
	[connectionSettings release];
	[serverList release];
	[consoleSwitch release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning];
}

//////////////////////////////////////
/// Property Save Callback Methods ///
//////////////////////////////////////
- (void)saveChangedProperty
{
	NSDictionary *cachedSettings = [connectionSettings copy];
	int type = [(PropertyEditorController *)[self.navigationController topViewController] propertyType];
	[connectionSettings setValue:[NSNumber numberWithBool:consoleSwitch.on] forKey:@"console"];
	if (type == PropertyTypeTitle)
	{
		NSString *newTitle = [[(PropertyEditorController *)[self.navigationController topViewController] textField] text];
		[connectionSettings setValue:newTitle forKey:@"title"];
		self.navigationItem.title = newTitle;
		[KeychainServices updateGenericPasswordForConnectionSettings:cachedSettings withNewConnectionSettings:connectionSettings];
	}
	else if (type == PropertyTypeHostname)
	{
		NSString *newHostname = [[(PropertyEditorController *)[self.navigationController topViewController] textField] text];
		[connectionSettings setValue:newHostname forKey:@"hostname"];
		[KeychainServices updateGenericPasswordForConnectionSettings:cachedSettings withNewConnectionSettings:connectionSettings];
	}
	else if (type == PropertyTypeUsername)
	{
		NSString *newUsername = [[(PropertyEditorController *)[self.navigationController topViewController] textField] text];
		[connectionSettings setValue:newUsername forKey:@"username"];
		[KeychainServices updateGenericPasswordForConnectionSettings:cachedSettings withNewConnectionSettings:connectionSettings];
	}
	else if (type == PropertyTypePassword)
	{
		NSString *newPassword = [[(PropertyEditorController *)[self.navigationController topViewController] textField] text];
		[connectionSettings setValue:newPassword forKey:@"password"];
		[KeychainServices updateGenericPasswordForConnectionSettings:cachedSettings withNewConnectionSettings:connectionSettings];
	}
	else if (type == PropertyTypeDomain)
	{
		NSString *newDomain = [[(PropertyEditorController *)[self.navigationController topViewController] textField] text];
		[connectionSettings setValue:newDomain forKey:@"domain"];
	}
	else if (type == PropertyTypeColorDepth)
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
	else if (type == PropertyTypePort)
	{
		[connectionSettings setValue:[NSNumber numberWithInt:[(PropertyEditorController *)[self.navigationController topViewController] port]] forKey:@"port"];
	}
	//[KeychainServices removeGenericPasswordForConnectionSettings:cachedSettings];
	//[KeychainServices addGenericPasswordForConnectionSettings:connectionSettings];

	[self.tableView reloadData];
	[self.navigationController popViewControllerAnimated:YES];
	[cachedSettings release];
}

- (void)userDidChangeConsoleSetting
{
	[connectionSettings setValue:[NSNumber numberWithBool:consoleSwitch.on] forKey:@"console"];
}

- (void)userDidChangeSoundSetting
{
	[connectionSettings setValue:[NSNumber numberWithBool:soundOnServerSwitch.on] forKey:@"srvsound"];
}

@end

