/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 ui_stubs.m
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



#include "rdesktop.h"

#import <sys/types.h>
#import <sys/time.h>
#import <dirent.h>
#import <stdio.h>

// for device redirection code in ui_select
#import <sys/stat.h>
#import <sys/times.h>

#import "RDCView.h"
#import "RDCBitmap.h"
#import "RDInstance.h"

#import "miscellany.h"

/* Opcodes
    GXclear,			0  0
    GXnor,				1  !src & !dst
    GXandInverted,		2  !src & dst
    GXcopyInverted,		3  !src
    GXandReverse,		4  src & !dst
    GXinvert,			5  !dst
    GXxor,				6  src ^ dst
    GXnand,				7  !src | !dst
    GXand,				8  src & dst
    GXequiv,			9  !src ^ dst
    GXnoop,				10 dst
    GXorInverted,		11 !src | dst
    GXcopy,				12 src
    GXorReverse,		13 src | !dst
    GXor,				14 src or dst
    GXset				15 1
*/

/*
 * File status flags: these are used by open(2), fcntl(2).
 * They are also used (indirectly) in the kernel file structure f_flags,
 * which is a superset of the open/fcntl flags.  Open flags and f_flags
 * are inter-convertible using OFLAGS(fflags) and FFLAGS(oflags).
 * Open/fcntl flags begin with O_; kernel-internal flags begin with F.
 */
/* open-only flags */
#define	O_RDONLY	0x0000		/* open for reading only */
#define	O_WRONLY	0x0001		/* open for writing only */
#define	O_RDWR		0x0002		/* open for reading and writing */
#define	O_ACCMODE	0x0003		/* mask for above modes */

/*
 * Kernel encoding of open mode; separate read and write bits that are
 * independently testable: 1 greater than the above.
 *
 * XXX
 * FREAD and FWRITE are excluded from the #ifdef KERNEL so that TIOCFLUSH,
 * which was documented to use FREAD/FWRITE, continues to work.
 */
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
#define	FREAD		0x0001
#define	FWRITE		0x0002
#endif
#define	O_NONBLOCK	0x0004		/* no delay */
#define	O_APPEND	0x0008		/* set append mode */
#define	O_SYNC		0x0080		/* synchronous writes */
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
#define	O_SHLOCK	0x0010		/* open with shared file lock */
#define	O_EXLOCK	0x0020		/* open with exclusive file lock */
#define	O_ASYNC		0x0040		/* signal pgrp when data ready */
#define	O_FSYNC		O_SYNC		/* source compatibility: do not use */
#define O_NOFOLLOW  0x0100      /* don't follow symlinks */
#endif /* (_POSIX_C_SOURCE && !_DARWIN_C_SOURCE) */
#define	O_CREAT		0x0200		/* create if nonexistant */
#define	O_TRUNC		0x0400		/* truncate to zero length */
#define	O_EXCL		0x0800		/* error if already exists */
#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
#define	O_EVTONLY	0x8000		/* descriptor requested for event notifications only */
#endif

/* record locking flags (F_GETLK, F_SETLK, F_SETLKW) */
#define	F_RDLCK		1		/* shared or read lock */
#define	F_UNLCK		2		/* unlock */
#define	F_WRLCK		3		/* exclusive or write lock */

/* command values */
#define	F_DUPFD		0		/* duplicate file descriptor */
#define	F_GETFD		1		/* get file descriptor flags */
#define	F_SETFD		2		/* set file descriptor flags */
#define	F_GETFL		3		/* get file status flags */
#define	F_SETFL		4		/* set file status flags */
#define	F_GETOWN	5		/* get SIGIO/SIGURG proc/pgrp */
#define F_SETOWN	6		/* set SIGIO/SIGURG proc/pgrp */
#define	F_GETLK		7		/* get record locking information */
#define	F_SETLK		8		/* set record locking information */
#define	F_SETLKW	9		/* F_SETLK; wait if blocked */

/*
 * Advisory file segment locking data type -
 * information passed to system by user
 */

struct flockie {
	off_t	l_start;	/* starting offset */
	off_t	l_len;		/* len = 0 means until end of file */
	pid_t	l_pid;		/* lock owner */
	short	l_type;		/* lock type: read/write, etc. */
	short	l_whence;	/* type of l_start */
};

// For managing the current draw session (the time bracketed between ui_begin_update and ui_end_update)
static void schedule_display(rdcConnection conn);
static void schedule_display_in_rect(rdcConnection conn, CGRect r);

// Callback functions for drawing patterns with Quartz.
void drawHatchPatternCallback(void *info, CGContextRef myContext);
void drawPatternCallback(void *info, CGContextRef myContext);

//Setup drawing callback for CGPatternRef
static const CGPatternCallbacks hatchCallbacks = {0, &drawHatchPatternCallback,NULL};
static const CGPatternCallbacks patternCallbacks = {0, &drawPatternCallback,NULL};

static RDCBitmap *nullCursor = nil;


#pragma mark -
#pragma mark Colormap 

HCOLOURMAP ui_create_colourmap(COLOURMAP * colors)
{
	unsigned int *colorMap = malloc(colors->ncolours * sizeof(unsigned));
	int i;
	for (i = 0; i < colors->ncolours; i++)
	{
		COLOURENTRY colorEntry = colors->colours[i];
		colorMap[i] = (colorEntry.blue << 16) | (colorEntry.green << 8) | colorEntry.red;
	}
	
	return colorMap;
}

void ui_set_colourmap(rdcConnection conn, HCOLOURMAP map)
{
	RDCView *v = conn->ui;
	[v setColorMap:(unsigned int *)map];
}


#pragma mark -
#pragma mark Bitmap

HBITMAP ui_create_bitmap(rdcConnection conn, int width, int height, uint8 *data)
{
	return [[RDCBitmap alloc] initWithBitmapData:data size:CGSizeMake(width, height) view:conn->ui];
}

void ui_paint_bitmap(rdcConnection conn, int x, int y, int cx, int cy, int width, int height, uint8 * data)
{
	RDCBitmap *bitmap = [[RDCBitmap alloc] initWithBitmapData:data size:CGSizeMake(width, height) view:conn->ui];
	ui_memblt(conn, 0, x, y, cx, cy, bitmap, 0, 0);
	[bitmap release];
}

void ui_memblt(rdcConnection conn, uint8 opcode, int x, int y, int cx, int cy, HBITMAP src, int srcx, int srcy)
{
	RDCView *v = conn->ui;
	RDCBitmap *bmp = (RDCBitmap *)src;
	CGRect r = CGRectMake(x, y, cx, cy);
	CGPoint p = CGPointMake(srcx, srcy);
	
	if (opcode != 0)
	{ 
		/* Treat opcode 0 just like copy */
		CHECKOPCODE(opcode);
	}
	
	[v memblt:r from:bmp withOrigin:p];
	schedule_display_in_rect(conn, r);
}

void ui_destroy_bitmap(HBITMAP bmp)
{
	id image = bmp;
	[image release];
}


#pragma mark -
#pragma mark Desktop Cache

// Takes a section of the desktop cache and saves it into a RDCBitmap compatible byte array
//	This is far less performance critical than -[RDCBitmap initWithBitmapData:]
void ui_desktop_save(rdcConnection conn, uint32 offset, int x, int y, int cx, int cy)
{
	RDCView *v = conn->ui;

	CGContextRef context = [v context];
	CFRetain(context);
	CGContextSaveGState(context);
	CGContextFlush(context);
	CGImageRef backingStore = CGBitmapContextCreateImage(context);
	CGImageRef sectionToCache = CGImageCreateWithImageInRect(backingStore, CGRectMake(x, conn->screenHeight - y - cy, cx, cy));
	CGContextRef cacheContext = CGBitmapContextCreate(malloc(CGImageGetHeight(sectionToCache) * CGImageGetBytesPerRow(sectionToCache)), 
													  CGImageGetWidth(sectionToCache), 
													  CGImageGetHeight(sectionToCache), 
													  CGImageGetBitsPerComponent(sectionToCache),
													  CGImageGetBytesPerRow(sectionToCache),
													  CGImageGetColorSpace(sectionToCache),
													  CGImageGetBitmapInfo(sectionToCache));
	CGContextDrawImage(cacheContext, CGRectMake(0.0, 0.0, CGImageGetWidth(sectionToCache), CGImageGetHeight(sectionToCache)), sectionToCache);
	CGContextRestoreGState(context);
	
	
	// Translate the 32-bit RGBA screen dump into RDP colors
	// NSBitmapImageRep seems to ignore bitmapFormat:NSAlphaFirstBitmapFormat, so
	// vImage acceleration isn't possible
	uint8 *output, *o, *src, *p, *data;
	int i=0, len=cx*cy, bytespp = conn->serverBpp/8;

	data = CGBitmapContextGetData(cacheContext);

	output = o = malloc(cx*cy*bytespp);
	if (!output)
	{
		NSLog(@"Couldn't malloc space for output/o");
	}
	unsigned int *colorMap = [v colorMap], j, q;
	p = src = data;
	if (bytespp == 2)
	{
		while (i++ < len)
		{
			*((unsigned short *)o) =
							(((p[0] * 31 + 127) / 255) << 11) |
							(((p[1] * 63 + 127) / 255) << 5)  |
							((p[2] * 31 + 127) / 255);
			p += 4;
			o += bytespp;
		}	
	}
	else if (bytespp == 1)
	{
		// Find color's index on colormap, use it as color
		while (i++ < len)
		{
			j = (p[2] << 16) | (p[1] << 8) | p[0];
			o[0] = 0;
			for (q = 0; q <= 0xff; q++) {
				if (colorMap[q] == j) {
					o[0] = q;
					break;
				}
			}
				
			p += 4;
			o += bytespp;
		}
	}
	else // 24
	{
		while (i++ < len)
		{
			o[2] = p[0];
			o[1] = p[1];
			o[0] = p[2];
			
			p += 4;
			o += bytespp;
		}
	}
	
	// Put the translated screen dump into the rdesktop bitmap cache
	offset *= bytespp;
	cache_put_desktop(conn, offset, cx, cy, cx*bytespp, bytespp, output);

	//Cleanup
	CFRelease(cacheContext);
	CFRelease(backingStore);
	CFRelease(sectionToCache);
	CFRelease(context);
	if (output)
	{
		free(output);
	}
	if (data)
	{
		free(data);
	}
}

void ui_desktop_restore(rdcConnection conn, uint32 offset, int x, int y, int cx, int cy)
{
	RDCView *v = conn->ui;
	uint8 *data;
	
	offset *= conn->serverBpp/8;
	data = cache_get_desktop(conn, offset, cx, cy, conn->serverBpp/8);
	
	CGRect r = CGRectMake(x, y, cx, cy);
	RDCBitmap *b = [[RDCBitmap alloc] initWithBitmapData:(const unsigned char *)data size:CGSizeMake(cx, cy) view:v];
	CGImageRef cachedBitmap = [b imageMask];
	CGContextRef context = [v context];
	CFRetain(context);
	CGContextSaveGState(context);
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	CGContextDrawImage(context, CGRectMake(x, y, cx, cy), cachedBitmap);
	CGContextRestoreGState(context);
	CFRelease(context);	
	[b release];
	schedule_display_in_rect(conn, r);
}


#pragma mark -
#pragma mark Managing Draw Session

void ui_begin_update(rdcConnection conn)
{
	[(id)conn->rectsNeedingUpdate release];
	conn->rectsNeedingUpdate = [[NSMutableArray alloc] init];
	conn->updateEntireScreen = NO;
}

void ui_end_update(rdcConnection conn)
{
	RDCView *v = (RDCView *)conn->ui;
	
	if (conn->updateEntireScreen)
	{
		//[v performSelectorOnMainThread:@selector(setNeedsDisplayOnMainThread:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
		[v setNeedsDisplayOnMainThread:[NSNumber numberWithBool:YES]];
	}
	else
	{
		[(id)conn->rectsNeedingUpdate retain];
		//[v performSelectorOnMainThread:@selector(setNeedsDisplayInRects:) withObject:(id)conn->rectsNeedingUpdate waitUntilDone:YES];
		[v setNeedsDisplayInRects:(id)conn->rectsNeedingUpdate];
	}

	[(id)conn->rectsNeedingUpdate release];
	conn->rectsNeedingUpdate = NULL;
	conn->updateEntireScreen = NO;
}

static void schedule_display(rdcConnection conn)
{
	conn->updateEntireScreen = YES;
}

static void schedule_display_in_rect(rdcConnection conn, CGRect r)
{
	//[(id)conn->rectsNeedingUpdate addObject:[NSValue valueWithRect:r]];
	[(id)conn->rectsNeedingUpdate addObject:[NSValue value: &r withObjCType:@encode(CGRect)]];
}


#pragma mark -
#pragma mark General Drawing

void ui_rect(rdcConnection conn, int x, int y, int cx, int cy, int colour)
{
	RDCView *v = conn->ui;
	CGRect r = CGRectMake(x , y, cx, cy);
	CGColorRef cgcolor = [v CGColorForRDCColor:colour];
	[v fillRect:r withColor:cgcolor];
	CGColorRelease(cgcolor);
	schedule_display_in_rect(conn, r);
}

void ui_line(rdcConnection conn, uint8 opcode, int startx, int starty, int endx, int endy, PEN * pen)
{
	RDCView *v = conn->ui;
	CGPoint start = CGPointMake(startx + 0.5, starty + 0.5);
	CGPoint end = CGPointMake(endx + 0.5, endy + 0.5);
	
	if (opcode == 15)
	{
		float components[4] = {255.0, 255.0, 255.0, 1.0};
		CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
		CGColorRef whiteColor = CGColorCreate(colorspace, components);
		[v drawLineFrom:start to:end color:whiteColor width:pen->width];
		CGColorRelease(whiteColor);
		CGColorSpaceRelease(colorspace);
		return;
	}
	
	CHECKOPCODE(opcode);
	CGColorRef cgcolor = [v CGColorForRDCColor:pen->colour];
	[v drawLineFrom:start to:end color:cgcolor width:pen->width];
	CGColorRelease(cgcolor);
	schedule_display(conn);
	// xxx: this should work quicker, but I haven't been able to test it (never called by rdesktop in use)
	//schedule_display_in_rect(conn, NSMakeRect(startx, starty, endx, endy));
}

void ui_screenblt(rdcConnection conn, uint8 opcode, int x, int y, int cx, int cy, int srcx, int srcy)
{
	RDCView *v = conn->ui;
	CGRect src = CGRectMake(srcx, srcy, cx, cy);
	CGPoint dest = CGPointMake(x, y);
	
	CHECKOPCODE(opcode);
	[v screenBlit:src to:dest];
	schedule_display_in_rect(conn, CGRectMake(x, y, cx, cy));
}

void ui_destblt(rdcConnection conn, uint8 opcode, int x, int y, int cx, int cy)
{
	RDCView *v = conn->ui;
	CGRect r = CGRectMake(x, y, cx, cy);
	float components[4];
	CGColorSpaceRef colorspace;
	/* XXX */
	switch (opcode)
	{
		case 0:
			components[0] = 0.0;
			components[1] = 0.0;
			components[2] = 0.0;
			components[3] = 1.0;
			colorspace = CGColorSpaceCreateDeviceRGB();
			CGColorRef blackColor = CGColorCreate(colorspace, components);
			[v fillRect:r withColor:blackColor];
			CGColorRelease(blackColor);
			CGColorSpaceRelease(colorspace);

			break;
		case 5:
			[v swapRect:r];
			break;
		case 15:
			components[0] = 1.0;
			components[1] = 1.0;
			components[2] = 1.0;
			components[3] = 1.0;
			colorspace = CGColorSpaceCreateDeviceRGB();
			CGColorRef whiteColor = CGColorCreate(colorspace, components);
			[v fillRect:r withColor:whiteColor];
			CGColorRelease(whiteColor);
			CGColorSpaceRelease(colorspace);
			break;
		default:
			CHECKOPCODE(opcode);
			break;
	}
	
	schedule_display_in_rect(conn, r);
}

void ui_polyline(rdcConnection conn, uint8 opcode, POINT * points, int npoints, PEN *pen)
{
	RDCView *v = conn->ui;
	CHECKOPCODE(opcode);
	CGColorRef cgcolor = [v CGColorForRDCColor:pen->colour];
	[v polyline:points npoints:npoints color:cgcolor width:pen->width];
	CGColorRelease(cgcolor);
	schedule_display(conn);
}

void ui_polygon(rdcConnection conn, uint8 opcode, uint8 fillmode, POINT * point, int npoints, BRUSH *brush, int bgcolour, int fgcolour)
{
	RDCView *v = conn->ui;
	int r;
	int style;
	CHECKOPCODE(opcode);
	
	switch (fillmode)
	{
		case ALTERNATE:
			r = 1;
			break;
		case WINDING:
			r = 0;
			break;
		default:
			UNIMPL;
			return;
	}
	
	style = brush != NULL ? brush->style : 0;
	
	CGColorRef cgcolor = [v CGColorForRDCColor:fgcolour];
	switch (style)
	{
		case 0:
			[v polygon:point npoints:npoints color:cgcolor winding:r];
			break;
		default:
			UNIMPL;
			break;
	}
	CGColorRelease(cgcolor);
	schedule_display(conn);
}

static const uint8 hatch_patterns[] =
{
    0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00, /* 0 - bsHorizontal */
    0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, /* 1 - bsVertical */
    0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01, /* 2 - bsFDiagonal */
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, /* 3 - bsBDiagonal */
    0x08, 0x08, 0x08, 0xff, 0x08, 0x08, 0x08, 0x08, /* 4 - bsCross */
    0x81, 0x42, 0x24, 0x18, 0x18, 0x24, 0x42, 0x81  /* 5 - bsDiagCross */
};

struct patternInfoStruct {
	int backgroundColor;
	int foregroundColor;
	BRUSH *brush;
	rdcConnection connection;
};

/* XXX Still needs origins */
void ui_patblt(rdcConnection conn, uint8 opcode, int x, int y, int cx, int cy, BRUSH * brush, int bgcolor, int fgcolor)
{
	RDCView *v = conn->ui;
	CGRect dest = CGRectMake(x, y, cx, cy);
	struct patternInfoStruct patternInfo;
	CGPatternRef hatchPattern;
	if (opcode == 6)
	{
		[v swapRect:dest];
		schedule_display_in_rect(conn, dest);
		return;
	}
	
	CGColorRef cgcolor = [v CGColorForRDCColor:fgcolor];
	CHECKOPCODE(opcode);
	
	switch (brush->style)
	{
		case 0: /* Solid */
			[v fillRect:dest withColor:cgcolor];
			break;
			
		case 2: /* Hatch */
			//Create the pattern
			patternInfo.backgroundColor = bgcolor;
			patternInfo.foregroundColor = fgcolor;
			patternInfo.connection = conn;
			patternInfo.brush = brush;
			hatchPattern = CGPatternCreate(&patternInfo, CGRectMake(0, 0, 8, 8), CGAffineTransformIdentity, 8.0, 8.0, kCGPatternTilingNoDistortion, true, &hatchCallbacks);
			
			//Paint the pattern
			[v fillRect:dest withPattern:hatchPattern patternOrigin:CGPointMake(brush->xorigin, brush->yorigin)];
			
			//Cleanup
			CGPatternRelease(hatchPattern);
			break;
			
		case 3: /* Pattern */
			//Create the pattern
			patternInfo.backgroundColor = bgcolor;
			patternInfo.foregroundColor = fgcolor;
			patternInfo.connection = conn;
			patternInfo.brush = brush;
			hatchPattern = CGPatternCreate(&patternInfo, CGRectMake(0, 0, 8, 8), CGAffineTransformIdentity, 8.0, 8.0, kCGPatternTilingNoDistortion, true, &patternCallbacks);
			
			//Paint the pattern
			[v fillRect:dest withPattern:hatchPattern patternOrigin:CGPointMake(brush->xorigin, brush->yorigin)];
			
			//Cleanup
			CGPatternRelease(hatchPattern);

			break;
		default:
			unimpl("brush %d\n", brush->style);
			break;
	}
	CGColorRelease(cgcolor);
	schedule_display_in_rect(conn, dest);
}

void drawPatternCallback(void *info, CGContextRef myContext)
{
	//Cast *info into a pointer to our custom info struct.
	struct patternInfoStruct *infoStruct;
	infoStruct = (struct patternInfoStruct *)info;
	
	rdcConnection connection = (*infoStruct).connection;
	RDCView *view = connection->ui;
	BRUSH *brush = (*infoStruct).brush;	
	uint8 i, ipattern[8];
	for (i = 0; i != 8; i++)
	{
		ipattern[7 - i] = brush->pattern[i];
	}
	
	RDCBitmap *bitmap = bitmap = ui_create_glyph(connection, 8, 8, ipattern);
 	CGContextDrawImage(myContext, CGRectMake(0.0, 0.0, 8.0, 8.0), [bitmap imageMask]);
	
	CGColorRef fgcolor = [view CGColorForRDCColor:(*infoStruct).foregroundColor];
	CGContextSetBlendMode(myContext, kCGBlendModeSourceAtop);
	CGContextSetFillColorWithColor(myContext, fgcolor);
	CGColorRelease(fgcolor);
	CGContextFillRect(myContext, CGRectMake(0, 0, 8, 8));
	
	CGColorRef bgcolor = [view CGColorForRDCColor:(*infoStruct).backgroundColor];
	CGContextSetBlendMode(myContext, kCGBlendModeDestinationAtop);
	CGContextSetFillColorWithColor(myContext, bgcolor);
	CGColorRelease(bgcolor);
	CGContextFillRect(myContext, CGRectMake(0, 0, 8, 8));
	
	//Cleanup
	ui_destroy_glyph(bitmap);
}

void drawHatchPatternCallback(void *info, CGContextRef myContext)
{
	//Cast *info into a pointer to our custom info struct.
	struct patternInfoStruct *infoStruct;
	infoStruct = (struct patternInfoStruct *)info;
	
	rdcConnection connection = (*infoStruct).connection;
	RDCView *view = connection->ui;
	BRUSH *brush = (*infoStruct).brush;
	RDCBitmap *bitmap = ui_create_glyph(connection, 8, 8, hatch_patterns + brush->pattern[0] * 8);

 	CGContextDrawImage(myContext, CGRectMake(0.0, 0.0, 8.0, 8.0), [bitmap imageMask]);
	
	CGColorRef fgcolor = [view CGColorForRDCColor:(*infoStruct).foregroundColor];
	CGContextSetBlendMode(myContext, kCGBlendModeSourceAtop);
	CGContextSetFillColorWithColor(myContext, fgcolor);
	CGColorRelease(fgcolor);
	CGContextFillRect(myContext, CGRectMake(0, 0, 8, 8));

	CGColorRef bgcolor = [view CGColorForRDCColor:(*infoStruct).backgroundColor];
	CGContextSetBlendMode(myContext, kCGBlendModeDestinationAtop);
	CGContextSetFillColorWithColor(myContext, bgcolor);
	CGColorRelease(bgcolor);
	CGContextFillRect(myContext, CGRectMake(0, 0, 8, 8));

	//Cleanup
	ui_destroy_glyph(bitmap);
}

#pragma mark -
#pragma mark Text drawing

HGLYPH ui_create_glyph(rdcConnection conn, int width, int height, const uint8 *data)
{
	return [[RDCBitmap alloc] initWithGlyphData:data size:CGSizeMake(width, height) view:conn->ui];
}

void ui_destroy_glyph(HGLYPH glyph)
{
	id image = glyph;
	[image release];
}

void ui_drawglyph(rdcConnection conn, int x, int y, int w, int h, RDCBitmap *glyph, CGColorRef fgcolor, CGColorRef bgcolor);

void ui_drawglyph(rdcConnection conn, int x, int y, int w, int h, RDCBitmap *glyph, CGColorRef fgcolor, CGColorRef bgcolor)
{
	RDCView *v = conn->ui;
	CGRect r = CGRectMake(x, y, w, h);
	[v drawGlyph:glyph at:r fg:fgcolor bg:bgcolor];
}

#define DO_GLYPH(ttext,idx) \
{\
  glyph = cache_get_font (conn, font, ttext[idx]);\
  if (!(flags & TEXT2_IMPLICIT_X))\
  {\
    xyoffset = ttext[++idx];\
    if ((xyoffset & 0x80))\
    {\
      if (flags & TEXT2_VERTICAL)\
        y += ttext[idx+1] | (ttext[idx+2] << 8);\
      else\
        x += ttext[idx+1] | (ttext[idx+2] << 8);\
      idx += 2;\
    }\
    else\
    {\
      if (flags & TEXT2_VERTICAL)\
        y += xyoffset;\
      else\
        x += xyoffset;\
    }\
  }\
  if (glyph != NULL)\
  {\
    x1 = x + glyph->offset;\
    y1 = y + glyph->baseline;\
	ui_drawglyph(conn, x1, y1, glyph->width, glyph->height, glyph->pixmap, foregroundColor, backgroundColor); \
    if (flags & TEXT2_IMPLICIT_X)\
      x += glyph->width;\
  }\
}

void ui_draw_text(rdcConnection conn, uint8 font, uint8 flags, uint8 opcode, int mixmode, int x, int y, int clipx, int clipy,
				  int clipcx, int clipcy, int boxx, int boxy, int boxcx, int boxcy, BRUSH * brush, int bgcolour,
				  int fgcolour, uint8 * text, uint8 length)
{
	int i = 0, j;
	int xyoffset;
	int x1, y1;
	FONTGLYPH *glyph;
	DATABLOB *entry;
	RDCView *v = conn->ui;
	CGRect box;
	CGColorRef foregroundColor = [v CGColorForRDCColor:fgcolour];
	CGColorRef backgroundColor = [v CGColorForRDCColor:bgcolour];
	
	CHECKOPCODE(opcode);
	
	if (boxx + boxcx >= [v width])
		boxcx = [v width] - boxx;
	
	// Paint background
	box = (boxcx > 1) ? CGRectMake(boxx, boxy, boxcx, boxcy) : CGRectMake(clipx, clipy, clipcx, clipcy);
	
	if (boxcx > 1 || mixmode == MIX_OPAQUE)
		[v fillRect:box withColor:backgroundColor];
	
	[v startUpdate];
	
	/* Paint text, character by character */
	for (i = 0; i < length;)
	{                       
		switch (text[i])
		{           
			case 0xff:  
				if (i + 2 < length)
				{
					cache_put_text(conn, text[i + 1], text, text[i + 2]);
				} 
				else
				{
					error("this shouldn't be happening\n");
					exit(1);
				} /* this will move pointer from start to first character after FF command */ 

				length -= i + 3;
				text = &(text[i + 3]);
				i = 0;
				break;

			case 0xfe:
				entry = cache_get_text(conn, text[i + 1]);
				if (entry != NULL)
				{
					if ((((uint8 *) (entry->data))[1] == 0) && (!(flags & TEXT2_IMPLICIT_X)))
					{
						if (flags & TEXT2_VERTICAL)
							y += text[i + 2];
						else
							x += text[i + 2]; 
					}
					
					for (j = 0; j < entry->size; j++)
						DO_GLYPH(((uint8 *) (entry->data)), j);
				} 

				i += (i + 2 < length) ? 3 : 2;
				length -= i;
				/* this will move pointer from start to first character after FE command */
				text = &(text[i]);
				i = 0;
				break;

			default:
				DO_GLYPH(text, i);
				i++;
				break;
		}
	}  
	
	[v stopUpdate];
	CGColorRelease(foregroundColor);
	CGColorRelease(backgroundColor);
	schedule_display_in_rect(conn, box);
}


#pragma mark -
#pragma mark Clipping drawing

void ui_set_clip(rdcConnection conn, int x, int y, int cx, int cy)
{
	RDCView *v = conn->ui;
	[v setClip:CGRectMake(x, y, cx, cy)];
}

void ui_reset_clip(rdcConnection conn)
{
	RDCView *v = conn->ui;
	[v resetClip];
}

void ui_bell(void)
{
	//NSBeep();
}


#pragma mark -
#pragma mark Cursors and Pointers

HCURSOR ui_create_cursor(rdcConnection conn, unsigned int x, unsigned int y, int width, int height,
						 uint8 * andmask, uint8 * xormask)
{
	return  [[RDCBitmap alloc] initWithCursorData:andmask alpha:xormask size:CGSizeMake(width, height) hotspot:CGPointMake(x, y) view:conn->ui];
}

void ui_set_null_cursor(rdcConnection conn)
{
	if (nullCursor == nil)
		nullCursor = ui_create_cursor(conn, 0, 0, 0, 0, NULL, NULL);
	
	ui_set_cursor(conn, nullCursor);
}

void ui_set_cursor(rdcConnection conn, HCURSOR cursor)
{
	RDInstance *controller = (RDInstance *)conn->controller;
	RDCBitmap *c = (RDCBitmap *)cursor;
	[controller setCursor:[c imageMask]];
}

void ui_destroy_cursor(HCURSOR cursor)
{
	id c = (RDCBitmap *)cursor;
	[c release];
}

void ui_move_pointer(rdcConnection conn, int x, int y)
{
	UNIMPL;
}


#pragma mark -
#pragma mark Non-UI
char *
next_arg(char *src, char needle)
{
	char *nextval;
	char *p;
	char *mvp = 0;

	/* EOS */
	if (*src == (char) 0x00)
		return 0;

	p = src;
	/*  skip escaped needles */
	while ((nextval = strchr(p, needle)))
	{
		mvp = nextval - 1;
		/* found backslashed needle */
		if (*mvp == '\\' && (mvp > src))
		{
			/* move string one to the left */
			while (*(mvp + 1) != (char) 0x00)
			{
				*mvp = *(mvp + 1);
				*mvp++;
			}
			*mvp = (char) 0x00;
			p = nextval;
		}
		else
		{
			p = nextval + 1;
			break;
		}
	}

	/* more args available */
	if (nextval)
	{
		*nextval = (char) 0x00;
		return ++nextval;
	}

	/* no more args after this, jump to EOS */
	nextval = src + strlen(src);
	return nextval;
}

void toupper_str(char *p)    
{
	while (*p)
	{
		if ((*p >= 'a') && (*p <= 'z'))
			*p = toupper((int) *p);
		p++;
	}
}

void * xmalloc(int size)
{
    void *mem = malloc(size);
    if (mem == NULL)
    {
        error("xmalloc %d\n", size);
		//Debugger();
        exit(1);
    }
    return mem;
}

/* realloc; exit if out of memory */
void * xrealloc(void *oldmem, int size)
{
    void *mem;
	
    if (size < 1)
        size = 1;
	
    mem = realloc(oldmem, size);
    if (mem == NULL)
    {
        error("xrealloc %d\n", size);
		//Debugger();
        exit(1);
    }
    return mem;
}

void xfree(void *mem)
{
    free(mem);
}

/* report an error */
void error(char *format, ...)
{
    va_list ap;
	
    fprintf(stderr, "ERROR: ");
	
    va_start(ap, format);
    vfprintf(stderr, format, ap);
    va_end(ap);
}

/* report a warning */
void warning(char *format, ...)
{
    va_list ap;
	
    fprintf(stderr, "WARNING: ");
	
    va_start(ap, format);
    vfprintf(stderr, format, ap);
    va_end(ap);
}

/* report an unimplemented protocol feature */
void unimpl(char *format, ...)
{
    va_list ap;
	
    fprintf(stderr, "NOT IMPLEMENTED: ");
	
    va_start(ap, format);
    vfprintf(stderr, format, ap);
    va_end(ap);
}

/* produce a hex dump */
void hexdump(unsigned char *p, unsigned int len)
{
    unsigned char *line = p;
    int i, thisline, offset = 0;
	
    while (offset < len)
    {
        printf("%04x ", offset);
        thisline = len - offset;
        if (thisline > 16)
            thisline = 16;
		
        for (i = 0; i < thisline; i++)
            printf("%02x ", line[i]);
		
        for (; i < 16; i++)
            printf("   ");
		
        for (i = 0; i < thisline; i++)
            printf("%c", (line[i] >= 0x20 && line[i] < 0x7f) ? line[i] : '.');
		
        printf("\n");
        offset += thisline;
        line += thisline;
    }
}

/* Generate a 32-byte random for the secure transport code. */
void generate_random(uint8 *randomValue)
{
    int fd, n;
    if ( (fd = open("/dev/urandom", O_RDONLY)) != -1)
    {
        n = read(fd, randomValue, 32);
        close(fd);
		return;
    }
}

/* Create the bitmap cache directory */
int rd_pstcache_mkdir(void)
{
    char *home;
    char bmpcache_dir[256];
	
    home = getenv("HOME");
	
    if (home == NULL)
        return False;
	
    sprintf(bmpcache_dir, "%s/%s", home, ".rdesktop");
	
    if ((mkdir(bmpcache_dir, S_IRWXU) == -1) && errno != EEXIST)
    {
        perror(bmpcache_dir);
        return False;
    }
	
    sprintf(bmpcache_dir, "%s/%s", home, ".rdesktop/cache");
	
    if ((mkdir(bmpcache_dir, S_IRWXU) == -1) && errno != EEXIST)
    {
        perror(bmpcache_dir);
        return False;
    }
	
    return True;
}

/* open a file in the .rdesktop directory */
int rd_open_file(char *filename)
{
    char *home;
    char fn[256];
    int fd;
	
    home = getenv("HOME");
    if (home == NULL)
        return -1;
    sprintf(fn, "%s/.rdesktop/%s", home, filename);
    fd = open(fn, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
    if (fd == -1)
        perror(fn);
    return fd;
}

/* close file */
void rd_close_file(int fd)
{
    close(fd);
}

/* read from file*/
int rd_read_file(int fd, void *ptr, int len)
{
    return read(fd, ptr, len);
}

/* write to file */
int rd_write_file(int fd, void *ptr, int len)
{
    return write(fd, ptr, len);
}

/* move file pointer */
int rd_lseek_file(int fd, int offset)
{
    return lseek(fd, offset, SEEK_SET);
}

/* do a write lock on a file */
int rd_lock_file(int fd, int start, int len)
{
    struct flockie lock;
	
    lock.l_type = F_WRLCK;
    lock.l_whence = SEEK_SET;
    lock.l_start = start;
    lock.l_len = len;
    if (fcntl(fd, F_SETLK, &lock) == -1)
        return False;
    return True;
}

void ui_resize_window(void)
{
	UNIMPL;
}

#define LTOA_BUFSIZE (sizeof(long) * 8 + 1)
char *l_to_a(long N, int base)
{
    char *ret;
    
	ret = malloc(LTOA_BUFSIZE);
	
    char *head = ret, buf[LTOA_BUFSIZE], *tail = buf + sizeof(buf);

    register int divrem;

    if (base < 36 || 2 > base)
        base = 10;

    if (N < 0)
    {
        *head++ = '-';
        N = -N;
    }

    tail = buf + sizeof(buf);
    *--tail = 0;

    do
    {
        divrem = N % base;
        *--tail = (divrem <= 9) ? divrem + '0' : divrem + 'a' - 10;
        N /= base;
    }
    while (N);

    strcpy(head, tail);
    return ret;
}

void ui_triblt(uint8 opcode, 
			   int x, int y, int cx, int cy,
			   HBITMAP src, int srcx, int srcy,
			   BRUSH *brush, int bgcolour, int fgcolour)
{
	CHECKOPCODE(opcode);
	UNIMPL;
}

void ui_ellipse(rdcConnection conn, uint8 opcode, uint8 fillmode, int x, int y, int cx, int cy,
				BRUSH *brush, int bgcolour, int fgcolour)
{
	RDCView *v = conn->ui;
	//CGRect r = NSMakeRect(x + 0.5, y + 0.5, cx, cy);
	CGRect r = CGRectMake(x + 0.4, y + 0.5, cx, cy);
	int style;
	CGColorRef cgcolor = [v CGColorForRDCColor:fgcolour];
	CHECKOPCODE(opcode);

	style = brush != NULL ? brush->style : 0;
	
	switch (style)
	{
		case 0:
			[v ellipse:r color:cgcolor];
			break;
		default:
			UNIMPL;
			return;
	}
	CGColorRelease(cgcolor);
	schedule_display_in_rect(conn, r);
}

void save_licence(unsigned char *data, int length)
{
	UNIMPL;
}

int load_licence(unsigned char **data)
{
	UNIMPL;
	return 0;
}

#pragma mark Disk forwarding
int ui_select(rdcConnection conn)
{
	int n = 0;
	fd_set rfds, wfds;

	// If there are no pending IO requests, no need to check any files
	if (!conn->ioRequest)
		return 1;
	
	FD_ZERO(&rfds);
	FD_ZERO(&wfds);	

	//rdpdr_add_fds(conn, &n, &rfds, &wfds, &tv, &s_timeout);
	
	struct timeval noTimeout;
	noTimeout.tv_sec = 0;
	noTimeout.tv_usec = 500; // one millisecond is 1000

	switch (select(n, &rfds, &wfds, NULL, &noTimeout))
	{
		case -1:
			error("select: %s\n", strerror(errno));
			break;
		case 0:
			//rdpdr_check_fds(conn, &rfds, &wfds, 1);
			break;
		default:
			//rdpdr_check_fds(conn, &rfds, &wfds, 0);
			break;
	}
	
	return 1;
}


#pragma mark Numlock

unsigned int read_keyboard_state()
{
	return 0;
}

unsigned short ui_get_numlock_state(unsigned int state)
{
	return 1;
}


#pragma mark -
#pragma mark Clipboard

void ui_clip_format_announce(rdcConnection conn, uint8 *data, uint32 length) 
{

}

void ui_clip_handle_data(rdcConnection conn, uint8 *data, uint32 length) 
{	
	//RDInstance *inst = (RDInstance *)conn->controller;
	//[inst setLocalClipboard:[NSData dataWithBytes:data length:length] format:conn->clipboardRequestType];
}

void ui_clip_request_data(rdcConnection conn, uint32 format) 
{	
	//RDInstance *inst = (RDInstance *)conn->controller;
	 
	//if ( (format == CF_UNICODETEXT) || (format == CF_TEXT) )
		//[inst setRemoteClipboard:format];
}

void ui_clip_sync(rdcConnection conn) 
{
	cliprdr_send_simple_native_format_announce(conn, CF_UNICODETEXT);	
}

void ui_clip_request_failed(rdcConnection conn)
{

	
}

void ui_clip_set_mode(rdcConnection conn, const char *optarg)
{

}


