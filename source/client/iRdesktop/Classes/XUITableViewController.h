/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 XUITableViewController.h
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

#import <UIKit/UIKit.h>

@interface XUITableView : UITableView {
	
}
- (UIView *)hitTest:(CGPoint)_point withEvent:(UIEvent *)_event;

@end


@interface XUITableViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {
	XUITableView* tableView;
	UITableViewStyle tableViewStyle;
}
- (id) initWithStyle:(UITableViewStyle)tableViewStyle;

@property (nonatomic, retain) XUITableView *tableView;


@end
