/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDCView.m
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


#import "RDCView.h"
#import "RDCKeyboard.h"
#import "RDCBitmap.h"
#import "RDInstance.h"

#import "scancodes.h"

@interface RDCView (Private)
	- (void)send_modifiers:(UIEvent *)ev enable:(BOOL)en;
	- (void)focusBackingStore;
	- (void)releaseBackingStore;
	- (void)recheckScheduledMouseInput:(NSTimer*)timer;
@end

#pragma mark -

@implementation RDCView

#pragma mark NSObject

- (void)dealloc
{
	[keyTranslator release];
	CFRelease(context);
	free(colorMap);
	colorMap = NULL;
	
	[super dealloc];
}


#pragma mark -
#pragma mark UIView

- (id)initWithFrame:(CGRect)frame
{
	if (![super initWithFrame:frame])
		return nil;

	// Setup the graphics context we will use to paint to.
	CGColorSpaceRef contextColorSpace = CGColorSpaceCreateDeviceRGB();
	context = CGBitmapContextCreate(NULL, frame.size.width, frame.size.height, 8, frame.size.width * 4, contextColorSpace, kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(contextColorSpace);
	
	// Other initializations
	clipRect = frame;	//Need to do this to get a clean first draw
	colorMap = malloc(0xff * sizeof(unsigned int));
	memset(colorMap, 0, 0xff * sizeof(unsigned int));
	keyTranslator = [[RDCKeyboard alloc] init];

	screenSize = frame.size;
	
	//Setup the last touch date to now - just to initialize
	dragSequenceBegan = NO;
    return self;
}

- (void)drawRect:(CGRect)rect
{
	//Setup
	CGContextSaveGState(context);
	CGContextSetBlendMode(context, kCGBlendModeNormal);
	CGImageRef backingStore = CGBitmapContextCreateImage(context);

	//Draw the rect handed to us
	CGContextRef currentContext = UIGraphicsGetCurrentContext();
	CGImageRef thisRectsImage = CGImageCreateWithImageInRect(backingStore, CGRectMake(rect.origin.x, [controller screenHeight] - rect.origin.y - rect.size.height, rect.size.width, rect.size.height));
	CGContextDrawImage(currentContext, CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height), thisRectsImage);
	CFRelease(thisRectsImage);

	//Cleanup
	CGContextRestoreGState(context);
	CFRelease(backingStore);
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)isOpaque
{
	return YES;
}

- (void)setFrame:(CGRect)frame
{	
	[super setFrame:frame];
	CGRect bounds = CGRectMake(0.0, 0.0, screenSize.width, screenSize.height);

	if (frame.size.width > bounds.size.width)
		bounds.origin.x = (frame.size.width - bounds.size.width)/2.0;
		
	if (frame.size.height > bounds.size.height)
		bounds.origin.y = (frame.size.height - bounds.size.height)/2.0;
		
	[self setBounds:bounds];
}

- (void)viewDidEndLiveResize
{
	[self setNeedsDisplay];
}


#pragma mark -
#pragma mark NSResponder Event Handlers

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (BOOL)resignFirstResponder
{
	return [super resignFirstResponder];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Iterate over all of the touches that we received.
	NSArray *theseTouches = [touches allObjects];
	int i = 0;
	for (i = 0 ; i < theseTouches.count ; i++)
	{
		//Add the touch's begin location to the touchBeginLocation Dictionary
		UITouch *thisTouch = [theseTouches objectAtIndex:i];
		CGPoint thisTouchPoint = [thisTouch locationInView:self];
		NSValue *pointValue = [NSValue value:&thisTouchPoint withObjCType:@encode(CGPoint)];
		
		//If this is the first tap for this touch, then record the location
		//of the touch.  Additionally we will perform a right click after a delay.
		//if the tap sequence ends before the delay expires, then the action will be
		//cancelled.
		if (thisTouch.tapCount == 1)
		{
			dragSequenceBegan = NO;
			[self performSelector:@selector(performRightClick:) withObject:pointValue afterDelay:.8];
		}
		
		//If this is the second tap for this touch, cancel the action that we
		//executed for a right click.
		if (thisTouch.tapCount == 2)
		{
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (dragSequenceInMotion)
	{
		[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_BUTTON1 param1:lrintf(lastDragPoint.x) param2:lrintf(lastDragPoint.y)];
		dragSequenceInMotion = NO;
	}
	
	//Cancel any pending right click operations.
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	//Iterate over all of the touches that we received.
	NSArray *theseTouches = [touches allObjects];
	int i = 0;
	for (i = 0 ; i < theseTouches.count ; i++)
	{
		UITouch *thisTouch = [theseTouches objectAtIndex:i];
		CGPoint thisTouchPoint = [thisTouch locationInView:self];
		NSValue *pointValue = [NSValue value:&thisTouchPoint withObjCType:@encode(CGPoint)];
		if (thisTouch.tapCount == 1)
		{
			if (!dragSequenceBegan)
			{
				[self performLeftClickAtPoint:pointValue];
				lastTouchPoint = thisTouchPoint;
				dragSequenceBegan = YES;
			}
			else
			{
				lastTouchPoint = thisTouchPoint;
				[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_BUTTON1 param1:lrintf(thisTouchPoint.x) param2:lrintf(thisTouchPoint.y)];
				dragSequenceBegan = NO;
			}
		}
		
		//If this is the second tap for this touch, then
		//send a double-click.
		if (thisTouch.tapCount == 2)
		{
			pointValue = [NSValue value:&lastTouchPoint withObjCType:@encode(CGPoint)];
			[self performLeftClickAtPoint:pointValue];
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *thisTouch = [touches anyObject];
	CGPoint dragPoint = [thisTouch locationInView:self];
	if (dragSequenceBegan)
	{
		dragSequenceInMotion = YES;
		[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_MOVE param1:lrintf(dragPoint.x) param2:lrintf(dragPoint.y)];
		lastDragPoint = dragPoint;
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	//This method is probably called when the user taps, but then
	//begins scrolling the view.  When this happens, the UIScrollView
	//will send the touchesCancelled message.  We take the opportunity
	//to cancel any pending right click operations.
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)performLeftMouseDown
{
	[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_DOWN | MOUSE_FLAG_BUTTON1 param1:lrintf(lastTouchPoint.x + 3) param2:lrintf(lastTouchPoint.y - 3)];	
}

- (void)performRightClick:(NSValue *)point
{
	CGPoint touchPoint;
	[point getValue:&touchPoint];
	[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_DOWN | MOUSE_FLAG_BUTTON2 param1:lrintf(touchPoint.x) param2:lrintf(touchPoint.y)];
	[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_BUTTON2 param1:lrintf(touchPoint.x) param2:lrintf(touchPoint.y)];
}

- (void)performLeftClickAtPoint:(NSValue *)point
{
	CGPoint touchPoint;
	[point getValue:&touchPoint];
	[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_DOWN | MOUSE_FLAG_BUTTON1 param1:lrintf(touchPoint.x) param2:lrintf(touchPoint.y)];
	[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_BUTTON1 param1:lrintf(touchPoint.x) param2:lrintf(touchPoint.y)];
}

- (void)performDoubleClickAtPoint:(NSValue *)point
{
	CGPoint touchPoint;
	[point getValue:&touchPoint];
	[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_DOWN | MOUSE_FLAG_BUTTON1 param1:lrintf(touchPoint.x) param2:lrintf(touchPoint.y)];
	[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_BUTTON1 param1:lrintf(touchPoint.x) param2:lrintf(touchPoint.y)];	
	[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_DOWN | MOUSE_FLAG_BUTTON1 param1:lrintf(touchPoint.x) param2:lrintf(touchPoint.y)];
	[controller sendInput:RDP_INPUT_MOUSE flags:MOUSE_FLAG_BUTTON1 param1:lrintf(touchPoint.x) param2:lrintf(touchPoint.y)];	
}

- (void)colorTouchPoint:(CGPoint)point
{
	float components[4];
	components[0] = 1.0;
	components[1] = 0.0;
	components[2] = 0.0;
	components[3] = 1.0;
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGColorRef redColor = CGColorCreate(colorspace, components);
	[self fillRect:CGRectMake(point.x - 1, point.y - 1, 3, 3) withColor:redColor];
	CGColorRelease(redColor);
	CGColorSpaceRelease(colorspace);
	[super setNeedsDisplayInRect:CGRectMake(point.x - 1, point.y - 1, 3, 3)];
}

#pragma mark -
#pragma mark Drawing to the backing store 

- (void)ellipse:(CGRect)r color:(CGColorRef)c
{
	//Convert rect to user space
	[self focusBackingStore];
	CGContextSetLineWidth(context, 1.0);
	CGMutablePathRef path = CGPathCreateMutable();
	CGContextSetStrokeColorWithColor(context, c);
	CGPathAddEllipseInRect(path, NULL, r);
	CGContextStrokePath(context);
	[self releaseBackingStore];
}


- (void)polygon:(POINT *)points npoints:(int)nPoints color:(CGColorRef)c
		winding:(int)winding
{
	//Setup
	[self focusBackingStore];

	//Construct Path
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, points[0].x + 0.5, points[0].y + 0.5);
	int i;
	for (i = 1 ; i < nPoints ; i++)
	{
		//Calculate new point since the ones given are relative to the previous point.
		int newX = points[i - 1].x + points[i].x;
		int newY = points[i - 1].y + points[i].y;
		CGContextAddLineToPoint(context, newX, newY);
		points[i].x = newX;
		points[i].y = newY;
	}
	CGContextClosePath(context);
	
	//Perform fill of polygon
	CGContextSetFillColorWithColor(context, c);
	if (winding == 0)
	{
		CGContextFillPath(context);
	}
	else if (winding == 1)
	{
		CGContextEOFillPath(context);
	}
	
	//Finish up
	[self releaseBackingStore];
}

- (void)polyline:(POINT *)points npoints:(int)nPoints color:(CGColorRef)c width:(int)w
{
	//Setup
	[self focusBackingStore];
	
	//Construct Path
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, points[0].x + 0.5, points[0].y + 0.5);
	int i;
	for (i = 1 ; i < nPoints ; i++)
	{
		//Calculate new point since the ones given are relative to the previous point.
		int newX = points[i - 1].x + points[i].x;
		int newY = points[i - 1].y + points[i].y;
		CGContextAddLineToPoint(context, newX, newY);
		points[i].x = newX;
		points[i].y = newY;
	}
	CGContextClosePath(context);
	
	//Paint Path
	CGContextSetStrokeColorWithColor(context, c);
	CGContextStrokePath(context);
	
	//Finish up
	[self releaseBackingStore];
}

- (void)fillRect:(CGRect)rect withColor:(CGColorRef)color
{	
	//Setup
	[self focusBackingStore];

	//Construct rectangle
	CGContextSetBlendMode(context, kCGBlendModeNormal);
	CGContextSetFillColorSpace(context, CGColorSpaceCreateDeviceRGB());
	CGContextSetFillColorWithColor(context, color);
	CGContextFillRect(context, rect);
	CGContextFlush(context);
	
	//Finish up
	[self releaseBackingStore];
}

- (void)fillRect:(CGRect)rect withPattern:(CGPatternRef)pattern patternOrigin:(CGPoint)origin
{
	//Setup
	
	[self focusBackingStore];
	CGContextSetPatternPhase(context, CGSizeMake(origin.x, origin.y));
	
	//Fill the rectangle with the given pattern
	float alpha = 1.0;
	CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern (NULL);
	CGContextSetFillColorSpace(context, patternSpace);
	CGColorSpaceRelease(patternSpace);
	CGContextSetFillPattern(context, pattern, &alpha);
	CGContextFillRect(context, rect);
	CGContextFlush(context);
	
	//Cleanup
	[self releaseBackingStore];
}

- (void)memblt:(CGRect)to from:(RDCBitmap *)image withOrigin:(CGPoint)origin
{
	//Setup
	CFRetain(context);
	[self focusBackingStore];
	
	//Get bitmap, modify CTM to draw flipped image.
	CGRect viewsFrame = CGRectMake([self frame].origin.x, [self frame].origin.y, [self frame].size.width, [self frame].size.height);
	CGImageRef newBitmap = CGImageCreateWithImageInRect([image imageMask], CGRectMake(origin.x, origin.y, to.size.width, to.size.height));
	CGContextConcatCTM(context, CGAffineTransformMakeTranslation(0.0, viewsFrame.size.height));
	CGContextConcatCTM(context, CGAffineTransformMakeScale(1.0, -1.0));
	CGContextConcatCTM(context, CGAffineTransformMakeTranslation(to.origin.x, [self frame].size.height - to.origin.y - to.size.height));
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, to.size.width, to.size.height), newBitmap);
	
	//Finish up
	[self releaseBackingStore];
	CFRelease(context);
	CFRelease(newBitmap);
}

- (void)screenBlit:(CGRect)from to:(CGPoint)to
{
	//Setup
	[self focusBackingStore];
	
	//Draw a copy of the rect "from" to the point "to".
	//The coordinates of the rect and point passed to this function are goofy.  It assumes (0, 0) is at the top left corner of
	//the backing store and the from.origin and to are referenced from the window's top left corner.
	CGImageRef backingStore = CGBitmapContextCreateImage(context);
	CGImageRef thisRectsImage = CGImageCreateWithImageInRect(backingStore, CGRectMake(from.origin.x, screenSize.height - from.origin.y - from.size.height, from.size.width, from.size.height));
	CGContextDrawImage(context, CGRectMake(to.x, to.y, from.size.width, from.size.height), thisRectsImage);
	CGContextFlush(context);
	
	//Finish up
	[self releaseBackingStore];
	CFRelease(backingStore);
	
	//Checking to see if thisRectsImage still exists
	//seems to fix a bug in which we crash when using
	//scrollbars when the view is scaled way up.
	if (thisRectsImage)
	{
		CFRelease(thisRectsImage);
	}
}

- (void)drawLineFrom:(CGPoint)start to:(CGPoint)end color:(CGColorRef)color width:(int)width
{
	//Setup
	[self focusBackingStore];
	
	//Draw Line
	CGContextSetLineWidth(context, 0.0);
	CGContextMoveToPoint(context, start.x, start.y);
	CGContextAddLineToPoint(context, end.x, end.y);
	CGContextSetStrokeColorWithColor(context, color);
	CGContextStrokePath(context);
	
	//Finish Up
	[self releaseBackingStore];
}

- (void)drawGlyph:(RDCBitmap *)glyph at:(CGRect)r fg:(CGColorRef)fgcolor bg:(CGColorRef)bgcolor
{
	//Setup
	[self focusBackingStore];
	
	//Translate CTM to allow drawing of upside down bitmap.
	CGRect viewsFrame = CGRectMake([self frame].origin.x, [self frame].origin.y, [self frame].size.width, [self frame].size.height);
	CGContextTranslateCTM(context, 0.0, viewsFrame.size.height);
	CGContextConcatCTM(context, CGAffineTransformMakeScale(1.0, -1.0));
	CGContextConcatCTM(context, CGAffineTransformMakeTranslation(r.origin.x, [self frame].size.height - r.size.height - r.origin.y));
	
	//Draw Image Mask.
	CGImageRef bitmap = [glyph imageMask];
	bitmap = CGImageCreateWithImageInRect(bitmap, CGRectMake(0.0, 0.0, r.size.width, r.size.height));
	CGContextSetFillColorWithColor(context, fgcolor);
	CGContextSetBlendMode(context, kCGBlendModeNormal);
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, r.size.width, r.size.height), bitmap);
	
	//Finish up
	[self releaseBackingStore];
}

- (void)swapRect:(CGRect)r
{
	//Setup
	[self focusBackingStore];
	
	//Fill the rectangle
	CGContextSetBlendMode(context, kCGBlendModeDifference);
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextFillRect(context, r);
	CGContextFlush(context);
	
	//Finish up
	[self releaseBackingStore];
}


#pragma mark -
#pragma mark Clipping backing store drawing

- (void)setClip:(CGRect)r
{
	clipRect = r;
}

- (void)resetClip
{
	CGRect r = CGRectMake(0.0, 0.0, 0.0, 0.0);
	//r.size = [self frame].size;
	r.size = CGSizeMake([controller screenWidth], [controller screenHeight]);
	clipRect = r;
}


#pragma mark -
#pragma mark Controlling drawing to the backing store

- (void)startUpdate
{
	[self focusBackingStore];
}

- (void)stopUpdate
{
	[self releaseBackingStore];
}

- (void)focusBackingStore
{
	CGContextSaveGState(context);
	CGContextClipToRect(context, CGRectMake(clipRect.origin.x, clipRect.origin.y, clipRect.size.width, clipRect.size.height));
}

- (void)releaseBackingStore
{
	CGContextRestoreGState(context);
}


#pragma mark -
#pragma mark Converting RDP Colors

- (void)rgbForRDCColor:(int)col r:(unsigned char *)r g:(unsigned char *)g b:(unsigned char *)b
{
	if (bitdepth == 16)
	{
		*r = (( (col >> 11) & 0x1f) * 255 + 15) / 31;
		*g = (( (col >> 5) & 0x3f) * 255 + 31) / 63;
		*b = ((col & 0x1f) * 255 + 15) / 31;
		return;
	}
	
	int t = (bitdepth == 8) ? colorMap[col] : col;

	*b = (t >> 16) & 0xff;
	*g = (t >> 8)  & 0xff;
	*r = t & 0xff;
}

- (CGColorRef)CGColorForRDCColor:(int)col
{
	int r, g, b;
	if (bitdepth == 16)
	{
		r = (( (col >> 11) & 0x1f) * 255 + 15) / 31;
		g = (( (col >> 5) & 0x3f) * 255 + 31) / 63;
		b = ((col & 0x1f) * 255 + 15) / 31;
	}
	else // 8, 24, 32
	{
		int t = (bitdepth == 8) ? colorMap[col] : col;
		b = (t >> 16) & 0xff;
		g = (t >> 8)  & 0xff;
		r = t & 0xff;
	}
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	float components[4] = {(float)r / 255.0, (float)g / 255.0, (float)b / 255.0, 1.0};
	CGColorRef retColor = CGColorCreate(colorSpace, components);
	CGColorSpaceRelease(colorSpace);
	return retColor;
}


#pragma mark -
#pragma mark Other
- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (void)setNeedsDisplayInRects:(NSArray *)rects
{
	NSEnumerator *enumerator = [rects objectEnumerator];
	id dirtyRect;
	
	while ( (dirtyRect = [enumerator nextObject]) )
		[self setNeedsDisplayInRectAsValue:dirtyRect];
	
	[rects release];
}

- (void)setNeedsDisplayInRectAsValue:(NSValue *)rectValue
{
	CGRect r;
	[rectValue getValue:&r];
	
	// Hack: make the box 1px bigger all around; seems to make updates much more
	//	reliable when the screen is stretched
	r.origin.x = (int)r.origin.x - 1.0;
	r.origin.y = (int)r.origin.y - 1.0;
	r.size.width = (int)r.size.width + 2.0;
	r.size.height = (int)r.size.height + 2.0;

	[self setNeedsDisplayInRect:r];
}

- (void)setNeedsDisplayInRect:(CGRect)invalidRect
{
	// Hack: make the box 1px bigger all around; seems to make updates much more
	//	reliable when the screen is stretched
	invalidRect.origin.x = (int)invalidRect.origin.x - 1.0;
	invalidRect.origin.y = (int)invalidRect.origin.y - 1.0;
	invalidRect.size.width = (int)invalidRect.size.width + 2.0;
	invalidRect.size.height = (int)invalidRect.size.height + 2.0;
	
	[super setNeedsDisplayInRect:invalidRect];
}

- (void)setNeedsDisplayOnMainThread:(id)object
{
	[self setNeedsDisplay];
}

#pragma mark -
#pragma mark Accessors

- (void)setController:(RDInstance *)instance
{
	//Weak reference to controller.
	controller = instance;
	[keyTranslator setController:instance];
	bitdepth = [instance conn]->serverBpp;
}

- (int)bitsPerPixel
{
	return bitdepth;
}

- (int)width
{
	return [self bounds].size.width;
}

- (int)height
{
	return [self bounds].size.height;
}

- (unsigned int *)colorMap
{
	return colorMap;
}

- (void)setColorMap:(unsigned int *)map
{
	free(colorMap);
	colorMap = map;
}

- (void)setBitdepth:(int)depth
{
	bitdepth = depth;
}

- (CGContextRef)context
{
	return context;
}

- (RDCKeyboard *)keyTranslator
{
	return keyTranslator;
}

- (BOOL)dragSequenceBegan
{
	return dragSequenceBegan;
}

@end
