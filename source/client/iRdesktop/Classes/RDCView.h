/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDCView.h
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


//#import <ApplicationServices/ApplicationServices.h>
#import <UIKit/UIKit.h>

#import "rdesktop.h"

@class RDInstance;
@class RDCBitmap;
@class RDCKeyboard;

@interface RDCView : UIView
{
	RDInstance *controller;
	CGContextRef context;
	CGRect clipRect;
	int bitdepth;
	RDCKeyboard *keyTranslator;
	unsigned int *colorMap;	// always a size of 0xff+1
	CGSize screenSize;
	
	// Variables to control state when
	// tracking touches.
	BOOL dragSequenceBegan;
	BOOL dragSequenceInMotion;
	CGPoint lastTouchPoint;
	CGPoint lastDragPoint;
}

// Drawing
- (void)ellipse:(CGRect)r color:(CGColorRef)c;
- (void)polygon:(POINT *)points npoints:(int)nPoints color:(CGColorRef)c winding:(int)winding;
- (void)polyline:(POINT *)points npoints:(int)nPoints color:(CGColorRef)c width:(int)w;
- (void)fillRect:(CGRect)rect withColor:(CGColorRef)color;
- (void)fillRect:(CGRect)rect withPattern:(CGPatternRef)pattern patternOrigin:(CGPoint)origin;
- (void)memblt:(CGRect)to from:(RDCBitmap *)image withOrigin:(CGPoint)origin;
- (void)screenBlit:(CGRect)from to:(CGPoint)to;
- (void)drawLineFrom:(CGPoint)start to:(CGPoint)end color:(CGColorRef)color width:(int)width;
- (void)drawGlyph:(RDCBitmap *)glyph at:(CGRect)r fg:(CGColorRef)fgcolor bg:(CGColorRef)bgcolor;
- (void)swapRect:(CGRect)r;
- (void)colorTouchPoint:(CGPoint)point;

//Touch and Clicking
- (void)performLeftMouseDown;
- (void)performRightClick:(NSValue *)point;
- (void)performLeftClickAtPoint:(NSValue *)point;
- (void)performDoubleClickAtPoint:(NSValue *)point;

// Other rdesktop handlers
- (void)setClip:(CGRect)r;
- (void)resetClip;
- (void)startUpdate;
- (void)stopUpdate;

// Converting colors
- (void)rgbForRDCColor:(int)col r:(unsigned char *)r g:(unsigned char *)g b:(unsigned char *)b;
- (CGColorRef)CGColorForRDCColor:(int)col;

// Other
- (void)setNeedsDisplayInRects:(NSArray *)rects;
- (void)setNeedsDisplayInRectAsValue:(NSValue *)rectValue;
- (void)setNeedsDisplayOnMainThread:(id)object;

// Accessors
- (void)setController:(RDInstance *)instance;
- (int)bitsPerPixel;
- (void)setBitdepth:(int)depth;
- (int)width;
- (int)height;
- (unsigned int *)colorMap;
- (void)setColorMap:(unsigned int *)map;
- (CGContextRef)context;
- (RDCKeyboard *)keyTranslator;
- (BOOL)dragSequenceBegan;

@end
