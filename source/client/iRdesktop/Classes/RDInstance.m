/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDInstance.m
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


#import "RDInstance.h"
#import "RDCView.h"
#import "RDCKeyboard.h"


// Number of polls per second to check IO
#define NOTIFY_POLL_SPEED 10.0
#define NUM_ELEMENTS(array) (sizeof(array) / sizeof(array[0]))

@interface RDInstance (Private)
	- (void)updateKeychainData:(NSString *)newHost user:(NSString *)newUser password:(NSString *)newPassword force:(BOOL)force;
	- (void)setStatus:(CRDConnectionStatus)status;
	- (void)createScrollEnclosure:(CGRect)frame;
@end

#pragma mark -

@implementation RDInstance

#pragma mark NSObject methods
- (id)init
{
	preferredRowIndex = -1;
	screenDepth = 16;
	themes = cacheBitmaps = YES;
	fileEncoding = NSASCIIStringEncoding; 
	
	//return [self initWithRDPFile:nil];
	return [super init];
}

- (void)dealloc
{
	if (connectionStatus == CRDConnectionConnected)
		[self disconnect];
	[label release];
	[hostName release];
	[username release];
	[password release];
	[domain release];
	[otherAttributes release];
	[rdpFilename release];
	[delegate release];
	
	//[cellRepresentation release];
	[super dealloc];
}

- (id)initWithHost:(NSString *)host userName:(NSString *)user password:(NSString *)pass domain:(NSString *)dom colorDepth:(int)colors delegate:(id)object;
{
	if (![super init])
		return nil;
	hostName = [[NSString alloc] initWithString:host];
	if (pass && pass != nil)
	{
		password = [[NSString alloc] initWithString:pass];
	}
	else
	{
		password = @"";
	}
	if (user && user != nil)
	{
		username = [[NSString alloc] initWithString:user];
	}
	else
	{
		username = @"";
	}
	if (dom && dom != nil)
	{
		domain = [[NSString alloc] initWithString:dom];
	}
	else
	{
		domain = @"";
	}
	delegate = [object retain];
	screenWidth = 640;
	screenHeight = 480;
	screenDepth = colors;
	consoleSession = NO;
	leaveSound = NO;
	drawDesktop = NO;
	cacheBitmaps = YES;
	themes = NO;
	windowDrags = NO;
	
	temporary = YES;
	[self setStatus:CRDConnectionClosed];
	
	// Other initializations
	otherAttributes = [[NSMutableDictionary alloc] init];
	return self;
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return [otherAttributes objectForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	if ([self valueForKey:key] != value)
	{
		modified |= ![key isEqualToString:@"view"];
		[super setValue:value forKey:key];
	}
}


#pragma mark -
#pragma mark Working with rdesktop

- (void)handleStreamError;
{
	// Low level removal
	tcp_disconnect(conn);
	
	// UI cleanup
	[view removeFromSuperview];
	[view release];
	view = nil;
	
	// Clear out the bitmap cache
	int i, k;
	for (i = 0; i < NBITMAPCACHE; i++)
	{
		for (k = 0; k < NBITMAPCACHEENTRIES; k++)
		{	
			ui_destroy_bitmap(conn->bmpcache[i][k].bitmap);
			conn->bmpcache[i][k].bitmap = NULL;
		}
	}
	
	// Clear out the font cache
	FONTGLYPH *glyph;		
	for (i = 0; i < NUM_ELEMENTS(conn->fontCache); i++)
	{
		for (k = 0; k < NUM_ELEMENTS(conn->fontCache[0]); k++)
		{
			glyph = &conn->fontCache[i][k];
			if (glyph->pixmap != NULL)
				ui_destroy_glyph(glyph->pixmap);
		}
	}			
	
	//Clear out the text cache
	DATABLOB *text;
	for (i = 0; i < NUM_ELEMENTS(conn->textCache); i++)
	{
		text = &conn->textCache[i];
		if (text->data != NULL)
		{
			xfree(text->data);
		}
	}
	
	memset(conn, 0, sizeof(struct rdcConn));
	free(conn);
	conn = NULL;
	[self setStatus:CRDConnectionClosed];
	
	
	//NSInputStream *is = conn->inputStream;
	//NSOutputStream *os = conn->outputStream;
	//[is removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	//[is release];
	//[os release];
	
	connectionStatus = CRDConnectionClosed;
	if (delegate)
	{
		[delegate instanceDidDisconnect:self];
	}
	return;
}

// Invoked on incoming data arrival, starts the processing of incoming packets
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent
{
	if (streamEvent == NSStreamEventErrorOccurred)
	{
		[self handleStreamError];
		return;
	}
	
	uint8 type;
	STREAM s;
	uint32 ext_disc_reason;
	
	if (connectionStatus != CRDConnectionConnected)
	{
		NSLog(@"not connected!");
		return;
	}
	
	do
	{
		s = rdp_recv(conn, &type);
		if (s == NULL)
		{
			[self handleStreamError];
			//[g_appController performSelectorOnMainThread:@selector(disconnectInstance:) withObject:self waitUntilDone:NO];
			return;
		}
		
		switch (type)
		{
			case RDP_PDU_DEMAND_ACTIVE:
				process_demand_active(conn, s);
				break;
			case RDP_PDU_DEACTIVATE:
				DEBUG(("RDP_PDU_DEACTIVATE\n"));
				break;
			case RDP_PDU_DATA:
				if (process_data_pdu(conn, s, &ext_disc_reason))
				{
					//[g_appController performSelectorOnMainThread:@selector(disconnectInstance:) withObject:self waitUntilDone:NO];
					return;
				}
				break;
			case RDP_PDU_REDIRECT:
				process_redirect_pdu(conn, s);
				break;
			case 0:
				break;
			default:
				unimpl("PDU %d\n", type);
		}
		
	} while ( (conn->nextPacket < s->end) && (connectionStatus == CRDConnectionConnected) );
}

// Using the current properties, attempt to connect to a server. Blocks until timeout or failure.
- (BOOL)connect:(id)callbackObject
{
	NSAutoreleasePool *arp = [[NSAutoreleasePool alloc] init];
	if (connectionStatus == CRDConnectionDisconnecting)
	{
		while (connectionStatus == CRDConnectionDisconnecting)
			usleep(1000);
	}
	else if (connectionStatus != CRDConnectionClosed)
	{
		[arp release];
		return NO;
	}
		
	if (conn)
	{
		free(conn);
	}
	
	conn = malloc(sizeof(struct rdcConn));
	fill_default_connection(conn);
	conn->controller = self;
	
	// Fail quickly if it's a totally bogus host
	if ([hostName length] < 2)
	{
		conn->errorCode = ConnectionErrorHostResolution;
		[arp release];
		return NO;
	}
	
	// Set status to connecting. Do on main thread so that the cell's progress
	//	indicator timer is on the main thread.
	[self setStatusAsNumber:[NSNumber numberWithInt:CRDConnectionConnecting]];

	// RDP5 performance flags
	int performanceFlags = RDP5_DISABLE_NOTHING;
	if (!windowDrags)
		performanceFlags |= RDP5_NO_FULLWINDOWDRAG;
	
	if (!themes)
		performanceFlags |= RDP5_NO_THEMING;
	
	if (!drawDesktop)
		performanceFlags |= RDP5_NO_WALLPAPER;
	
	if (!windowAnimation)
		performanceFlags |= RDP5_NO_MENUANIMATIONS;
	
	performanceFlags |= RDP5_NO_CURSOR_SHADOW;
	
	conn->rdp5PerformanceFlags = performanceFlags;
	
	// RDP logon flags
	int logonFlags = RDP_LOGON_NORMAL | RDP_LOGON_COMPRESSION2 | RDP_LOGON_LEAVE_AUDIO;
	if ([username length] > 0 && ([password length] > 0 || savePassword))
		logonFlags |= RDP_LOGON_AUTO;
	
	if (leaveSound) {
		logonFlags |= RDP_LOGON_LEAVE_AUDIO;
	}
	// Other various settings
	conn->bitmapCache = cacheBitmaps;
	conn->serverBpp = (screenDepth==8 || screenDepth==24) ? screenDepth : 16;
	conn->consoleSession = consoleSession;
	conn->screenWidth = screenWidth ? screenWidth : 1024;
	conn->screenHeight = screenHeight ? screenHeight : 768;
	conn->tcpPort = (!port || port>=65536) ? DEFAULT_PORT : port;
	strncpy(conn->username, safe_string_conv(username), sizeof(conn->username));
	
	// Set remote keymap to match local OS X input type
	conn->keyboardLayout = 0x409;
	
	
	
	// Make the connection
	BOOL connected = rdp_connect(conn, safe_string_conv(hostName), logonFlags, safe_string_conv(domain), safe_string_conv(password), "", "");
							
	// Upon success, set up the input socket
	if (connected)
	{
		[self setStatus:CRDConnectionConnected];
		
		inputRunLoop = [NSRunLoop mainRunLoop];
	
		if (!view)
		{
			view = [[RDCView alloc] initWithFrame:CGRectMake(0.0, 0.0, conn->screenWidth, conn->screenHeight)];
		}
		[view setController:self];
		conn->ui = view;
		
		NSStream *is = conn->inputStream;
		[is setDelegate:self];
		[is scheduleInRunLoop:inputRunLoop forMode:NSDefaultRunLoopMode];
	}
	else
	{	
		[self setStatus:CRDConnectionClosed];
	}
	
	//Check on the status of the connection now that is has connected or failed.  Call the appropriate
	//callback function on the main thread.
	switch ([self status])
	{
		case CRDConnectionConnected:
			[delegate performSelectorOnMainThread:@selector(instanceDidConnect:) withObject:self waitUntilDone:NO];
			break;
		case CRDConnectionClosed:
			[delegate performSelectorOnMainThread:@selector(instanceDidFailToConnect:) withObject:self waitUntilDone:NO];
			break;
		default:
			break;
	}
	[arp release];
	return connected;
}

- (void) disconnect
{
	[self retain];
	[self disconnectAsync:[NSNumber numberWithBool:NO]];
}

- (void) disconnectAsync:(NSNumber *)block
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self setStatus:CRDConnectionDisconnecting];
	if (inputLoopFinished || [block boolValue])
	{
		while (!inputLoopFinished)
			usleep(1000);
		
		// Low level removal
		tcp_disconnect(conn);
		
		// UI cleanup
		[view removeFromSuperview];
		[view release];
		view = nil;
		
		// Clear out the bitmap cache
		int i, k;
		for (i = 0; i < NBITMAPCACHE; i++)
		{
			for (k = 0; k < NBITMAPCACHEENTRIES; k++)
			{	
				ui_destroy_bitmap(conn->bmpcache[i][k].bitmap);
				conn->bmpcache[i][k].bitmap = NULL;
			}
		}
		
		// Clear out the font cache
		FONTGLYPH *glyph;		
		for (i = 0; i < NUM_ELEMENTS(conn->fontCache); i++)
		{
			for (k = 0; k < NUM_ELEMENTS(conn->fontCache[0]); k++)
			{
				glyph = &conn->fontCache[i][k];
				if (glyph->pixmap != NULL)
					ui_destroy_glyph(glyph->pixmap);
			}
		}			
		
		//Clear out the text cache
		DATABLOB *text;
		for (i = 0; i < NUM_ELEMENTS(conn->textCache); i++)
		{
			text = &conn->textCache[i];
			if (text->data != NULL)
			{
				xfree(text->data);
			}
		}
		
		memset(conn, 0, sizeof(struct rdcConn));
		free(conn);
		conn = NULL;
		[self setStatus:CRDConnectionClosed];
	}
	else
	{
		[self retain];
		[NSThread detachNewThreadSelector:@selector(disconnectAsync:) toTarget:self
					withObject:[NSNumber numberWithBool:YES]];	
	}
	
	[pool release];
	[self release];
}

- (void)sendInput:(uint16) type flags:(uint16)flags param1:(uint16)param1 param2:(uint16)param2
{
	if (connectionStatus == CRDConnectionConnected)
		rdp_send_input(conn, time(NULL), type, flags, param1, param2);
}

- (void)pollDiskNotifyRequests:(NSTimer *)timer
{
	if (connectionStatus != CRDConnectionConnected)
	{
		[timer invalidate];
		return;
	}
	
	ui_select(conn);
}

// Working with the mouse cursor
- (void)setCursor:(CGImageRef)cursor
{
	[delegate setCursor:cursor];
}


- (void)sendCTRLALTDELETE
{
	[self sendScancode:(0x00 | 0x1d) flags:RDP_KEYPRESS];
	[self sendScancode:(0x00 | 0x38) flags:RDP_KEYPRESS];
	[self sendScancode:(0x80 | 0x53) flags:RDP_KEYPRESS];

	[self sendScancode:(0x80 | 0x53) flags:RDP_KEYRELEASE];
	[self sendScancode:(0x00 | 0x38) flags:RDP_KEYRELEASE];
	[self sendScancode:(0x00 | 0x1d) flags:RDP_KEYRELEASE];	
	
}


- (void)sendWINKEY
{
	[self sendScancode:(0x80 | 0x5b) flags:RDP_KEYPRESS];
	[self sendScancode:(0x80 | 0x5b) flags:RDP_KEYRELEASE];	
}


- (void)sendScancode:(uint8)scancode flags:(uint16)flags
{
	if (scancode & 0x80)
	{
		[self sendInput:RDP_INPUT_SCANCODE flags:(flags | KBD_FLAG_EXT) param1:(scancode & ~0x80) param2:0];
	}
	else
	{
		[self sendInput:RDP_INPUT_SCANCODE flags:flags param1:scancode param2:0];
	}
}

#pragma mark -
#pragma mark Working With CoRD

- (void)cancelConnection
{
	if ( (connectionStatus != CRDConnectionConnecting) || (conn == NULL))
		return;
	
	conn->errorCode = ConnectionErrorCanceled;
}

- (NSComparisonResult)compareUsingPreferredOrder:(id)compareTo
{
	int otherOrder = [[compareTo valueForKey:@"preferredRowIndex"] intValue];
	
	if (preferredRowIndex == otherOrder)
		return [[compareTo label] compare:label];
	else
		return (preferredRowIndex - otherOrder > 0) ? NSOrderedDescending : NSOrderedAscending;
}

#pragma mark -
#pragma mark Accessors
- (rdcConnection)conn
{
	return conn;
}

- (NSString *)label
{
	return label;
}

- (RDCView *)view
{
	return view;
}

- (NSString *)rdpFilename
{
	return rdpFilename;
}

- (void)setRdpFilename:(NSString *)path
{
	[path retain];
	[rdpFilename release];
	rdpFilename = path;
}

- (BOOL)temporary
{
	return temporary;
}

- (void)setTemporary:(BOOL)temp
{
	temporary = temp;
	//[self updateCellData];
}

- (BOOL)modified
{
	return modified;
}

- (CRDConnectionStatus)status
{
	return connectionStatus;
}

- (UIWindow *)window
{
	return window;
}

- (int)screenWidth
{
	return screenWidth;
}

- (int)screenHeight
{
	return screenHeight;
}

- (void)setStatus:(CRDConnectionStatus)status
{
	connectionStatus = status;
}

// Status needs to be set on the main thread when setting it to Connecting
//	so the the CRDServerCell will create its progress indicator timer in the main run loop
- (void)setStatusAsNumber:(NSNumber *)status
{
	[self setStatus:[status intValue]];
}


/* Do a few simple setters that would otherwise be caught by key-value coding so that
	updateCellData can be called and keychain data can be updated. Keychain data
	must be done here and not at save time because the keychain item might already 
	exist so it has to be edited.
*/
- (void)setLabel:(NSString *)s
{
	[label autorelease];
	label = [s retain];
	//[self updateCellData];
}

- (void)setHostName:(NSString *)s
{
	[self updateKeychainData:s user:username password:password force:NO];
	[hostName autorelease];
	hostName = [s retain];
	//[self updateCellData];
}

- (void)setUsername:(NSString *)s
{
	[username autorelease];
	username = [s retain];
	//[self updateCellData];
}

- (void)setPassword:(NSString *)pass
{
	[self updateKeychainData:hostName user:username password:pass force:NO];
	[password autorelease];
	password = [pass retain];
}

- (void)setScreenWidth:(int)width
{
	screenWidth = width;
}

- (void)setScreenHeight:(int)height
{
	screenHeight = height;
}

- (void)setPort:(int)aPort
{
	port = aPort;
}

- (void)useConsole:(BOOL)value
{
	consoleSession = value;
}

- (void)leaveSound:(BOOL)value
{
	leaveSound = value;
}

@end


