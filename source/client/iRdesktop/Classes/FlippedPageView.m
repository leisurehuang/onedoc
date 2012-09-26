/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 FlippedPageView.m
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


#import "FlippedPageView.h"


@implementation FlippedPageView


- (id)initWithFrame:(CGRect)frame 
{
	if (self = [super initWithFrame:frame]) 
	{
		// Initialization code
		self.backgroundColor = [UIColor redColor];
	}
	return self;
}

- (id)init
{
	if (self = [super init])
	{
		self.backgroundColor = [UIColor redColor];
	}
	return self;
}

- (void)drawRect:(CGRect)rect 
{
	[super drawRect:rect];
	// Drawing code
}


- (void)dealloc 
{
	[super dealloc];
}


@end
