/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDCBitmap.h
 Copyright (C) Craig Dooley      2006
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


@class RDCView;

@interface RDCBitmap : NSObject
{
	NSData *data;
	CGColorRef color;
	CGImageRef imageMask;
}

- (id)initWithBitmapData:(const unsigned char *)d size:(CGSize)s view:(RDCView *)v;
- (id)initWithCursorData:(const unsigned char *)d alpha:(const unsigned char *)a size:(CGSize)s hotspot:(CGPoint)hotspot view:(RDCView *)v;
- (id)initWithGlyphData:(const unsigned char *)d size:(CGSize)s view:(RDCView *)v;

- (void)setColor:(CGColorRef)color;
- (CGColorRef)color;
- (CGImageRef)imageMask;

@end
