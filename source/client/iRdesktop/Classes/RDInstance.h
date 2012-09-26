/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDInstance.h
 Copyright (C) Craig Dooley      2006
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


#import "rdesktop.h"
#import "miscellany.h"

@class RDCView;

@interface RDInstance : NSObject
{
	// Represented rdesktop object
	rdcConnection conn;
	id delegate;
	
	// User configurable RDP settings
	NSDictionary *connectionSettings;
	NSString *label, *hostName, *username, *password, *domain;	
	BOOL savePassword, forwardDisks, cacheBitmaps, drawDesktop, windowDrags,
			windowAnimation, themes, consoleSession, fullscreen, leaveSound;
	int startDisplay, forwardAudio, screenDepth, screenWidth, screenHeight, port;
	NSMutableDictionary *otherAttributes;
	
	// Allows disconnect to be called from any thread
	BOOL inputLoopFinished;
	NSRunLoop *inputRunLoop;

	// General information about instance
	BOOL temporary, modified, temporarilyFullscreen;
	int preferredRowIndex;
	CRDConnectionStatus connectionStatus;
	
	// Represented file
	NSString *rdpFilename;
	NSStringEncoding fileEncoding;
	
	// Clipboard
	NSString *remoteClipboardContents;

	// UI elements
	RDCView *view;
	UIScrollView *scrollEnclosure;
	UIWindow *window;
}

- (id)initWithHost:(NSString *)host userName:(NSString *)user password:(NSString *)pass domain:(NSString *)dom colorDepth:(int)colors delegate:(id)object;

// Working with rdesktop
- (BOOL)connect:(id)callbackObject;
- (void)handleStreamError;
- (void)disconnect;
- (void)disconnectAsync:(NSNumber *)block;
- (void)sendInput:(uint16)type flags:(uint16)flags param1:(uint16)param1 param2:(uint16)param2;

// Working with the rest of CoRD
- (void)cancelConnection;
- (NSComparisonResult)compareUsingPreferredOrder:(id)compareTo;

// Working with the mouse cursor
- (void)setCursor:(CGImageRef)cursor;

// Keyboard combos:
- (void)sendCTRLALTDELETE;
- (void)sendWINKEY;
- (void)sendScancode:(uint8)scancode flags:(uint16)flags;

// Accessors
- (rdcConnection)conn;
- (NSString *)label;
- (RDCView *)view;
- (NSString *)rdpFilename;
- (void)setRdpFilename:(NSString *)path;
- (BOOL)temporary;
- (void)setTemporary:(BOOL)temp;
- (BOOL)modified;
- (CRDConnectionStatus)status;
- (void)setStatusAsNumber:(NSNumber *)status;
- (UIWindow *)window;
- (int)screenWidth;
- (int)screenHeight;

- (void)setLabel:(NSString *)s;
- (void)setHostName:(NSString *)s;
- (void)setUsername:(NSString *)s;
- (void)setPassword:(NSString *)pass;
- (void)setScreenWidth:(int)width;
- (void)setScreenHeight:(int)height;
- (void)setPort:(int)aPort;
- (void)useConsole:(BOOL)value;
- (void)leaveSound:(BOOL)value;

@end

@protocol RDInstanceDelegate
- (void)instanceDidDisconnect:(RDInstance *)instance;
- (void)instanceDidConnect:(RDInstance *)instance;
- (void)instanceDidFailToConnect:(RDInstance *)instance;
- (void)setCursor:(CGImageRef)cursor;
@end
