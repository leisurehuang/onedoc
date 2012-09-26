/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDCBitmap.m
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


/*	
 Notes:
		- The ivar 'data' is used because NSBitmapImageRep does not copy the bitmap data.
		- The stored bitmap is ARGB8888 with alpha data regardless if source has
			alpha as a memory-speed tradeoff: vImage can convert RGB565 directly
			only to ARGB8888 (or planar, which would add complexity). Also, (to my
			knowledge from inspecting Shark dumps), Cocoa will translate whatever
			we paint into a 32 bitmap internally, so there's no disadvantage there.
		- Using an accelerated buffer would speed up drawing. An option could be used
			for the situations where an NSImage is required. My tests on a machine
			with a capable graphics card show that CGImage would speed
			normal drawing up about 30-40%, and CGLayer would be 2-12 times quicker.
			The hassle is that some situations, a normal NSImage is needed
			(eg: when using the image as a pattern for UIColor and patblt), so it would 
			either have to create both or have a switch for which to create, and 
			neither CGImage nor CGLayer have a way to draw only a portion of itself,
			meaning the only way to do it is clip drawing to match the origin.
			I've written some basic code to use CFLayer, but it needs more work
			before I commit it.
*/

#import "RDCBitmap.h"
#import "miscellany.h"
#import "RDCView.h"

@implementation RDCBitmap

- (id)initWithBitmapData:(const unsigned char *)sourceBitmap size:(CGSize)s view:(RDCView *)v
{
	if (![super init])
		return nil;

	int bytesPerPixel = [v bitsPerPixel] / 8;

	uint8 *outputBitmap, *nc;
	const uint8 *p, *end;
	unsigned realLength, newLength;
	unsigned int *colorMap;
	int width = (int)s.width, height = (int)s.height;
	
	realLength = width * height * bytesPerPixel;
	newLength = width * height * 4;
	
	p = sourceBitmap;
	end = p + realLength;
	
	nc = outputBitmap = malloc(newLength);
	
	if (bytesPerPixel == 1)
	{
		colorMap = [v colorMap];
		while (p < end)
		{
			nc[0] = 255;
			nc[1] = colorMap[*p] & 0xff;
			nc[2] = (colorMap[*p] >> 8) & 0xff;
			nc[3] = (colorMap[*p] >> 16) & 0xff;
			
			p++;
			nc += 4;
		}
	}
	else if (bytesPerPixel == 2)
	{
		//Each pixel is two bytes.  5 Red bits, 6 Green bits, and 5 Blue Bits.
		//  p[0]	  p[1]
		//GGGBBBBB  RRRRRGGG
		//Need to shift and mask the bits to get the right color components.
		while (p < end)
		{
			nc[0] = 255;																//Alpha
			nc[1] = (((p[1] >> 3) & 0x1F) * 255 + 15) / 31;								//Red
			nc[2] = ((((p[0] >> 5) & 0x07) | ((p[1] << 3) & 0x38)) * 255 + 31) / 63;	//Green
			nc[3] = ((p[0] & 0x1F)  * 255 + 15) / 31;									//Blue
			
			p += bytesPerPixel;
			nc += 4;
		}
	}
	else if (bytesPerPixel == 3 || bytesPerPixel == 4)
	{
		while (p < end)
		{
			nc[0] = 0;
			nc[1] = p[2];
			nc[2] = p[1];
			nc[3] = p[0];
			
			p += bytesPerPixel;
			nc += 4;
		}
	}
	
	data = [[NSData alloc] initWithBytes:(void *)outputBitmap length:newLength];

	CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGBitmapInfo bitmapInfo = kCGImageAlphaFirst;
	CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();
	imageMask = CGImageCreate(width, height, 8, 32, width * 4, imageColorSpace, bitmapInfo, dataProvider, NULL, NO, kCGRenderingIntentDefault);
	CGColorSpaceRelease(imageColorSpace);
	CGDataProviderRelease(dataProvider);
	[data release];
	if (outputBitmap)
	{
		free(outputBitmap);
	}
	return self;
}

- (id)initWithCursorData:(const unsigned char *)d alpha:(const unsigned char *)a size:(CGSize)s
				 hotspot:(CGPoint)hotspot view:(RDCView *)v
{	
	if (![super init])
		return nil;
	
	uint8 *np;
	const uint8 *p, *end;
	
	data = [[NSMutableData alloc] initWithCapacity:(int)s.width * (int)s.height * 4];
	p = a;
	end = a + ((int)s.width * (int)s.height * 3);
	int npOffset = ((int)s.width * (int)s.height * 4) - (4 * s.width);
	np = (uint8 *)[data bytes];
	np += npOffset;
  
	int i = 0, alpha;
	int bytecounter = 0;
	while (p < end)
	{
		np[0] = p[0];
		np[1] = p[1];
		np[2] = p[2];
		
		alpha = d[i / 8] & (0x80 >> (i % 8));
		if (alpha && (np[0] || np[1] || np[2]))
		{
			np[0] = np[1] = np[2] = 0;
			np[3] = 0xff;
		}
		else
		{
			np[3] = alpha ? 0 : 0xff;
		}
		
		i++;
		p += 3;
		np += 4;
		if (bytecounter == s.width)
		{
			bytecounter = 0;
			int npOffset = 2 * 4 * s.width;
			np -= npOffset;
		}
		bytecounter += 1;
	}

	CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst;
	CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();
	imageMask = CGImageCreate(s.width, s.height, 8, 32, s.width * 4, imageColorSpace, bitmapInfo, dataProvider, NULL, NO, kCGRenderingIntentDefault);
	CGColorSpaceRelease(imageColorSpace);
	CGDataProviderRelease(dataProvider);
	
	return self;
}

- (id)initWithGlyphData:(const unsigned char *)d size:(CGSize)s view:(RDCView *)v
{	
	if (![super init])
		return nil;
		
	int scanline = ((int)s.width + 7) / 8;
	
	
	data = [[NSData alloc] initWithBytes:d length:scanline * s.height];

	NSMutableData *flippedBits = [NSMutableData dataWithCapacity:(scanline * s.height)];

	char thisByte;
	int i = 0;
	for (i = 0 ; i < (scanline * s.height) ; i++)
	{
		[data getBytes:&thisByte range:NSMakeRange(i, 1)];
		thisByte = ~thisByte;
		[flippedBits replaceBytesInRange:NSMakeRange(i, 1) withBytes:&thisByte];
	}
	CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)flippedBits);
	imageMask = CGImageMaskCreate (s.width, s.height, 1, 1, scanline, dataProvider, NULL, NO);
	CGDataProviderRelease(dataProvider);
	[data release];
	
	float components[4];
	components[0] = 0.0;
	components[1] = 0.0;
	components[2] = 0.0;
	components[3] = 1.0;
	
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	color = CGColorCreate(colorspace, components);
	CFRelease(colorspace);

	
	return self;
}

#pragma mark -
#pragma mark Accessors

-(void)dealloc
{
	//CFRelease(color);
	if (imageMask)
	{
		CGImageRelease(imageMask);
	}
	[super dealloc];
}

-(void)setColor:(CGColorRef)c
{
	CFRetain(c);	
	CFRelease(color);
	color = c;
}

-(CGColorRef)color
{
	return color;
}

- (CGImageRef)imageMask
{
	return imageMask;
}
@end
