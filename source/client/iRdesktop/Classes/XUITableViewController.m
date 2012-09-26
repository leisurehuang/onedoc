/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 XUITableViewController.m
 Copyright (C) Thinstuff s.r.o.   2009

 Replacement for UITableViewController with an increased tapable area
 for the accessory view in UITableViewCell
 
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


#import "XUITableViewController.h"

@implementation XUITableView

- (UIView *)hitTest:(CGPoint)_point withEvent:(UIEvent *)_event;
{
	NSIndexPath *indexPath = [self indexPathForRowAtPoint:_point];
	UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
	if(cell && cell.accessoryType == UITableViewCellAccessoryDetailDisclosureButton 
	   && !self.editing 
	   && _point.x >= cell.frame.size.width - 80 
	   && _point.x <= cell.frame.size.width)
	{
		[self.delegate tableView:self accessoryButtonTappedForRowWithIndexPath:indexPath];
		return cell.accessoryView;
	}
	return [super hitTest:_point withEvent:_event];
}

@end


@implementation XUITableViewController

@synthesize tableView;

- (id) initWithStyle:(UITableViewStyle)_tableViewStyle {
	if (self = [super init]) {
		tableViewStyle = _tableViewStyle;
	}
    return self;
}


- (void) loadView {
	if (self.nibName)
    {
        [super loadView];
        NSAssert(tableView != nil, @"NIB file did not set tableView property.");
        return;
    }
	
	self.tableView = [[[XUITableView alloc] initWithFrame:CGRectZero style:tableViewStyle] autorelease];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	tableView.autoresizesSubviews = YES;
	
	self.view = tableView;
}

- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated { 
	[self.tableView flashScrollIndicators]; 
} 

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
	self.tableView = nil;
	[super dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    return cell;
}

@end
