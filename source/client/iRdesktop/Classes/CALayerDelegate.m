/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 CALayerDelegate.m
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


#import "CALayerDelegate.h"


@implementation CALayerDelegate
////////////////////////////////
/// CALayer Delegate Methods ///
////////////////////////////////
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	if ([layer valueForKey:@"type"] == @"page")
	{
		CGSize myShadowOffset = CGSizeMake(3, -3);
		CGContextSaveGState(ctx);
		CGContextSetShadow (ctx, myShadowOffset, 5);
		CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
		CGContextFillRect(ctx, CGRectMake(layer.bounds.origin.x, layer.bounds.origin.y, layer.bounds.size.width - 6, layer.bounds.size.height - 6));
		CGContextRestoreGState(ctx);
	}
	else if ([layer valueForKey:@"type"] == @"close")
	{
		CGSize myShadowOffset = CGSizeMake(3, -3);
		CGContextSaveGState(ctx);
		CGContextSetShadow (ctx, myShadowOffset, 5);
		CGContextSetRGBFillColor(ctx, 1, 1, 1, 1.0);
		CGContextDrawImage(ctx, 
						   CGRectMake(layer.bounds.origin.x, 
										   layer.bounds.origin.y, 
										   23.0, 
										   23.0), 
						   [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RedX" ofType:@"png"]] CGImage]);
		CGContextRestoreGState(ctx);
	}
}

@end
