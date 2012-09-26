/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDCKeyboard.m
 Copyright (C) Dorian Johnson    2007
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



/*	Notes: Numlock isn't synchronized because Apple keyboards don't use it.
			CapLock will eventually be properly synchronized.
*/

//#import <Carbon/Carbon.h>

//#import <IOKit/hidsystem/IOHIDTypes.h>

#import "RDCKeyboard.h"
#import "RDInstance.h"
#import "rdesktop.h"
#import "scancodes.h"
#import "miscellany.h"

#define KEYMAP_ENTRY(n) [[virtualKeymap objectForKey:[NSNumber numberWithInt:(n)]] intValue]
#define NUMERIC_ENTRY(n) [[numericKeymap objectForKey:[NSNumber numberWithInt:(n)]] intValue]
#define SET_KEYMAP_ENTRY(n, v) [virtualKeymap setObject:[NSNumber numberWithInt:(v)] forKey:[NSNumber numberWithInt:(n)]]
#define SET_SPECIAL_KEYMAP_ENTRY(n, v) [specialCharacterKeymap setObject:v forKey:n]
#define SET_NUMERIC_ENTRY(n, v) [numericKeymap setObject:[NSNumber numberWithInt:(v)] forKey:[NSNumber numberWithInt:(n)]]

static NSDictionary *windowsKeymapTable = nil;

@interface RDCKeyboard (Private)
	- (BOOL)readKeymap;
	- (BOOL)scancodeIsModifier:(uint8)scancode;
	- (void)setRemoteModifiers:(unsigned)newMods;
@end

#pragma mark -

@implementation RDCKeyboard

- (id) init
{
	if (![super init])
		return nil;
	
	virtualKeymap = [[NSMutableDictionary alloc] init];
	specialCharacterKeymap = [[NSMutableDictionary alloc] init];
	numericKeymap = [[NSMutableDictionary alloc] initWithCapacity:10];
	
	[self readKeymap];		
	
	return self;
}

- (void)dealloc
{
	[virtualKeymap release];
	[super dealloc];
}


#pragma mark -
#pragma mark Key event handling

- (void)registerSpecialKeycodes
{
	//Register special characters
	[specialCharacterKeymap setObject:@"156" forKey:@"£"];
	[specialCharacterKeymap setObject:@"0128" forKey:@"€"];
	[specialCharacterKeymap setObject:@"157" forKey:@"¥"];
	[specialCharacterKeymap setObject:@"0149" forKey:@"•"];
	[specialCharacterKeymap setObject:@"0161" forKey:@"¡"];
	[specialCharacterKeymap setObject:@"0191" forKey:@"¿"];
	[specialCharacterKeymap setObject:@"92" forKey:@"\\"];
	[specialCharacterKeymap setObject:@"35" forKey:@"#"];
	[specialCharacterKeymap setObject:@"126" forKey:@"~"];
	[specialCharacterKeymap setObject:@"124" forKey:@"|"];
	
	[specialCharacterKeymap setObject:@"0224" forKey:@"à"];
	[specialCharacterKeymap setObject:@"0192" forKey:@"À"];
	[specialCharacterKeymap setObject:@"0225" forKey:@"á"];
	[specialCharacterKeymap setObject:@"0193" forKey:@"Á"];
	[specialCharacterKeymap setObject:@"0226" forKey:@"â"];
	[specialCharacterKeymap setObject:@"0194" forKey:@"Â"];
	[specialCharacterKeymap setObject:@"0227" forKey:@"ã"];
	[specialCharacterKeymap setObject:@"0195" forKey:@"Ã"];
	[specialCharacterKeymap setObject:@"0228" forKey:@"ä"];
	[specialCharacterKeymap setObject:@"0196" forKey:@"Ä"];
	[specialCharacterKeymap setObject:@"0229" forKey:@"å"];
	[specialCharacterKeymap setObject:@"0197" forKey:@"Å"];
	[specialCharacterKeymap setObject:@"0230" forKey:@"æ"];
	[specialCharacterKeymap setObject:@"0198" forKey:@"Æ"];
	
	[specialCharacterKeymap setObject:@"0232" forKey:@"è"];
	[specialCharacterKeymap setObject:@"0200" forKey:@"È"];
	[specialCharacterKeymap setObject:@"0233" forKey:@"é"];
	[specialCharacterKeymap setObject:@"0201" forKey:@"É"];
	[specialCharacterKeymap setObject:@"0234" forKey:@"ê"];
	[specialCharacterKeymap setObject:@"0202" forKey:@"Ê"];
	[specialCharacterKeymap setObject:@"0235" forKey:@"ë"];
	[specialCharacterKeymap setObject:@"0203" forKey:@"Ë"];
	
	[specialCharacterKeymap setObject:@"0255" forKey:@"ÿ"];
	[specialCharacterKeymap setObject:@"0159" forKey:@"Ÿ"];
	
	[specialCharacterKeymap setObject:@"0249" forKey:@"ù"];
	[specialCharacterKeymap setObject:@"0217" forKey:@"Ù"];
	[specialCharacterKeymap setObject:@"0250" forKey:@"ú"];
	[specialCharacterKeymap setObject:@"0218" forKey:@"Ú"];
	[specialCharacterKeymap setObject:@"0251" forKey:@"û"];
	[specialCharacterKeymap setObject:@"0219" forKey:@"Û"];
	[specialCharacterKeymap setObject:@"0252" forKey:@"ü"];
	[specialCharacterKeymap setObject:@"0220" forKey:@"Ü"];
	
	[specialCharacterKeymap setObject:@"0236" forKey:@"ì"];
	[specialCharacterKeymap setObject:@"0204" forKey:@"Ì"];
	[specialCharacterKeymap setObject:@"0237" forKey:@"í"];
	[specialCharacterKeymap setObject:@"0205" forKey:@"Í"];
	[specialCharacterKeymap setObject:@"0238" forKey:@"î"];
	[specialCharacterKeymap setObject:@"0206" forKey:@"Î"];
	[specialCharacterKeymap setObject:@"0239" forKey:@"ï"];
	[specialCharacterKeymap setObject:@"0207" forKey:@"Ï"];
	
	[specialCharacterKeymap setObject:@"0242" forKey:@"ò"];
	[specialCharacterKeymap setObject:@"0210" forKey:@"Ò"];
	[specialCharacterKeymap setObject:@"0243" forKey:@"ó"];
	[specialCharacterKeymap setObject:@"0211" forKey:@"Ó"];
	[specialCharacterKeymap setObject:@"0244" forKey:@"ô"];
	[specialCharacterKeymap setObject:@"0212" forKey:@"Ô"];
	[specialCharacterKeymap setObject:@"0245" forKey:@"õ"];
	[specialCharacterKeymap setObject:@"0213" forKey:@"Õ"];
	[specialCharacterKeymap setObject:@"0246" forKey:@"ö"];
	[specialCharacterKeymap setObject:@"0214" forKey:@"Ö"];
	[specialCharacterKeymap setObject:@"0248" forKey:@"ø"];
	[specialCharacterKeymap setObject:@"0216" forKey:@"Ø"];
	[specialCharacterKeymap setObject:@"0248" forKey:@"ø"];
	[specialCharacterKeymap setObject:@"0216" forKey:@"Ø"];
	
	[specialCharacterKeymap setObject:@"0154" forKey:@"š"];
	[specialCharacterKeymap setObject:@"0138" forKey:@"Š"];
	
	[specialCharacterKeymap setObject:@"0231" forKey:@"ç"];
	[specialCharacterKeymap setObject:@"0199" forKey:@"Ç"];
	[specialCharacterKeymap setObject:@"0158" forKey:@"ž"];
	[specialCharacterKeymap setObject:@"0142" forKey:@"Ž"];
	[specialCharacterKeymap setObject:@"164" forKey:@"ñ"];
	[specialCharacterKeymap setObject:@"165" forKey:@"Ñ"];
	
}

// This method is called by the RDCViewController instance when it receives input.
// The decimal value for the key is sent as the keyCode.
- (void)handleKeyCode:(int)keyCode keyDown:(BOOL)down
{
	[self sendKeycode:keyCode modifiers:[self modifiersForKeyCode:keyCode] pressed:down];
	[self setRemoteModifiers:0];
}

#pragma mark -
#pragma mark Sending events to server

// This is the 
- (void)sendKeycode:(uint8)keyCode modifiers:(uint16)rdflags pressed:(BOOL)down
{
	if ([virtualKeymap objectForKey:[NSNumber numberWithInt:keyCode]] != nil)
	{
		if (down)
		{
			[self sendScancode:KEYMAP_ENTRY(keyCode) flags:(rdflags | RDP_KEYPRESS)];
		}
		else
		{
			[self sendScancode:KEYMAP_ENTRY(keyCode) flags:(rdflags | RDP_KEYRELEASE)];
		}
		return;
	}
}

- (void)sendScancode:(uint8)scancode flags:(uint16)flags
{
	if (scancode & SCANCODE_EXTENDED)
	{
		[controller sendInput:RDP_INPUT_SCANCODE flags:(flags | KBD_FLAG_EXT) param1:(scancode & ~SCANCODE_EXTENDED) param2:0];
	}
	else
	{
		[controller sendInput:RDP_INPUT_SCANCODE flags:flags param1:scancode param2:0];
	}
}

- (BOOL)handleSpecialKey:(NSString *)key
{
	if ([specialCharacterKeymap objectForKey:key] != nil)
	{
		#define SCANCODE_KEY_60 0x38
		#define SCANCODE_CHAR_LALT SCANCODE_KEY_60
		#define SCANCODE_KEY_90 0x45
		#define SCANCODE_CHAR_NUMLOCKL SCANCODE_KEY_90
		#define UP_OR_DOWN(b) ( (b) ? RDP_KEYPRESS : RDP_KEYRELEASE )
		
		NSString *code = [specialCharacterKeymap objectForKey:key];
		[self sendScancode:SCANCODE_CHAR_NUMLOCKL flags:RDP_KEYPRESS];
		[self sendScancode:SCANCODE_CHAR_NUMLOCKL flags:RDP_KEYRELEASE];
		
		[self sendScancode:SCANCODE_CHAR_LALT flags:RDP_KEYPRESS];
		int i = 0;
		for (i = 0 ; i < code.length ; i++)
		{
			int thisKey = [[code substringWithRange:NSMakeRange(i, 1)] intValue];
			[controller sendInput:RDP_INPUT_SCANCODE flags:(RDP_KEYPRESS) param1:((uint8)NUMERIC_ENTRY(thisKey)) param2:0];
			[controller sendInput:RDP_INPUT_SCANCODE flags:(RDP_KEYRELEASE) param1:((uint8)NUMERIC_ENTRY(thisKey)) param2:0];
		}
		[self sendScancode:SCANCODE_CHAR_LALT flags:RDP_KEYRELEASE];
		
		[self sendScancode:SCANCODE_CHAR_NUMLOCKL flags:RDP_KEYPRESS];
		[self sendScancode:SCANCODE_CHAR_NUMLOCKL flags:RDP_KEYRELEASE];
		return YES;
	}
	else
	{
		return NO;
	}
}

#pragma mark -
#pragma mark Internal use
// This method examines the flags that it is given and sends the appropriate
// key presses/releases to the remote desktop.
- (void)setRemoteModifiers:(unsigned)newMods
{
	unsigned changedMods = newMods ^ remoteModifiers;
	BOOL keySent;
		
	#define UP_OR_DOWN(b) ( (b) ? RDP_KEYPRESS : RDP_KEYRELEASE )
	
	// keySent is used because some older keyboards may not specify right or left.
	//	It is unknown if it is actually needed.
	
	// Shift key
	if ( (keySent = changedMods & NX_DEVICELSHIFTKEYMASK) )
		[self sendScancode:SCANCODE_CHAR_LSHIFT flags:UP_OR_DOWN(newMods & NX_DEVICELSHIFTKEYMASK)];
	else if ( (keySent |= changedMods & NX_DEVICERSHIFTKEYMASK) )
		[self sendScancode:SCANCODE_CHAR_RSHIFT flags:UP_OR_DOWN(newMods & NX_DEVICERSHIFTKEYMASK)];

	if (!keySent && (changedMods & NSShiftKeyMask))
		[self sendScancode:SCANCODE_CHAR_LSHIFT flags:UP_OR_DOWN(newMods & NSShiftKeyMask)];


	// Control key
	if ( (keySent = changedMods & NX_DEVICELCTLKEYMASK) )
		[self sendScancode:SCANCODE_CHAR_LCTRL flags:UP_OR_DOWN(newMods & NX_DEVICELCTLKEYMASK)];
	else if ( (keySent = changedMods & NX_DEVICERCTLKEYMASK) )
		[self sendScancode:SCANCODE_CHAR_RCTRL flags:UP_OR_DOWN(newMods & NX_DEVICERCTLKEYMASK)];

	if (!keySent && (changedMods & NSControlKeyMask))
		[self sendScancode:SCANCODE_CHAR_LCTRL flags:UP_OR_DOWN(newMods & NSControlKeyMask)];


	// Alt key
	if ( (keySent = changedMods & NX_DEVICELALTKEYMASK) )
		[self sendScancode:SCANCODE_CHAR_LALT flags:UP_OR_DOWN(newMods & NX_DEVICELALTKEYMASK)];
	else if ( (keySent = changedMods & NX_DEVICERALTKEYMASK) )
		[self sendScancode:SCANCODE_CHAR_RALT flags:UP_OR_DOWN(newMods & NX_DEVICERALTKEYMASK)];

	if (!keySent && (changedMods & NSAlternateKeyMask))
		[self sendScancode:SCANCODE_CHAR_LALT flags:UP_OR_DOWN(newMods & NSAlternateKeyMask)];


	// Windows key
	if (changedMods & NSCommandKeyMask)
		[self sendScancode:SCANCODE_CHAR_LWIN flags:UP_OR_DOWN(newMods & NSCommandKeyMask)];


	// Caps lock, for which flagsChanged is only raised once
	if (changedMods & NSAlphaShiftKeyMask)
	{
		[self sendScancode:SCANCODE_CHAR_CAPSLOCK flags:RDP_KEYPRESS];
		[self sendScancode:SCANCODE_CHAR_CAPSLOCK flags:RDP_KEYRELEASE];
	}

   remoteModifiers = newMods;

   #undef UP_OR_DOWN(x)
}



#pragma mark -
#pragma mark Accessors
- (RDInstance *)controller
{
	return controller;
}

- (void)setController:(RDInstance *)cont
{
	controller = cont;
}


#pragma mark -
#pragma mark Keymap file parser
// This method reads in the keymap.txt file from the Resources folder of the bundle.
// The keymap maps the decimal value of the various keys into a hexadecimal value
// that we must send to the remote desktop.  The key/value pairs are stored in 
// a NSMutableDictionary - instance variable "keyTranslator".
- (BOOL)readKeymap
{
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"keymap" ofType:@"txt"];
	NSArray *fileLines = [[NSString stringWithContentsOfFile:filePath] componentsSeparatedByString:@"\n"];
		
	NSCharacterSet *whiteAndHashSet  = [NSCharacterSet characterSetWithCharactersInString:@" \t#"];
	NSScanner *scanner;
	NSString *directive;
	unsigned int scancode;
	int osxVKValue;	
	signed lineNumber = -1;
	BOOL b = YES;
	id line;
	NSEnumerator *enumerator = [fileLines objectEnumerator];
		
	while ( (line = [enumerator nextObject]) )
	{
		lineNumber++;
		
		if (!b)
			DEBUG_KEYBOARD( (@"Uncaught keymap syntax error at line %d. Ignoring.", lineNumber - 1) );

		scanner = [NSScanner scannerWithString:line];
		b = YES;
	
		if (![scanner scanUpToCharactersFromSet:whiteAndHashSet intoString:&directive])
			continue;
		
		if ([directive isEqualToString:@"virt"])
		{
			// Virtual mapping
			b &= [scanner scanInt:&osxVKValue];
			b &= [scanner scanHexInt:&scancode];
			
			if (b)
				SET_KEYMAP_ENTRY(osxVKValue, scancode);
		}	
		else if ([directive isEqualToString:@"num"])
		{
			// Virtual mapping
			b &= [scanner scanInt:&osxVKValue];
			b &= [scanner scanHexInt:&scancode];
			
			if (b)
				SET_NUMERIC_ENTRY(osxVKValue, scancode);
		}
	}
	
	[self registerSpecialKeycodes];
	
	return YES;
}

#pragma mark Class methods

// This method isn't fully re-entrant but shouldn't be a problem in practice
+ (unsigned) windowsKeymapForMacKeymap:(NSString *)keymapName
{
	// Load 'OSX keymap name' --> 'Windows keymap number' lookup table if it isn't already loaded
	if (windowsKeymapTable == nil)
	{
		NSMutableDictionary *dict = [[NSMutableDictionary dictionaryWithCapacity:30] retain];
		NSString *filename = [[NSBundle mainBundle] pathForResource:@"windows_keymap_table" ofType:@"txt"];
		NSArray *lines = [[NSString stringWithContentsOfFile:filename] componentsSeparatedByString:@"\n"];
		NSScanner *scanner;
		NSString *n;
		unsigned i;
		
		id line;
		NSEnumerator *enumerator = [lines objectEnumerator];
		while ( (line = [enumerator nextObject]) )
		{
			line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			scanner = [NSScanner scannerWithString:line];
			[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"="]];
			[scanner scanUpToString:@"=" intoString:&n];
			[scanner scanHexInt:&i];
			
			if (i != 0 && n != nil)
				[dict setObject:[NSNumber numberWithUnsignedInt:i] forKey:n];
		}
		windowsKeymapTable = dict;
	}
	
	
	/* First, look up directly in the table. If not found, try a fuzzy match
		so that input types like "Arabic-QWERTY" will match "Arabic". Finally, 
		if an appropriate keymap isn't found either way, use US keymap as default.
	*/
	
	NSNumber *windowsKeymap = [windowsKeymapTable objectForKey:keymapName];
	
	if (windowsKeymap == nil)
	{
		NSString *prefix;
		
		id potentialKeymapName;
		NSEnumerator *enumerator = [[windowsKeymapTable allKeys] objectEnumerator];
		
		while ( (potentialKeymapName = [enumerator nextObject]) )
		{
			prefix = [keymapName commonPrefixWithString:potentialKeymapName
												options:NSLiteralSearch];
			if ([prefix length] >= 4)
			{ 
				windowsKeymap = [windowsKeymapTable objectForKey:potentialKeymapName];
				DEBUG_KEYBOARD( (@"windowsKeymapForMacKeymap: substituting keymap '%@' for passed '%@', giving Windows keymap '%x'",
								 potentialKeymapName, keymapName, [windowsKeymap intValue]));
				break;
			}
		}
	}
	
	return (windowsKeymap == nil) ? 0x409 : [windowsKeymap unsignedIntValue];
}

+ (NSString *) currentKeymapName
{
	return NULL;
}

// This method sets up the modifier keys for particular types of input.  Mostly
// this is for input that requires we hit the "shift" key prior to typing.
// If a shift key is needed, a call out to setRemoteModifiers: sends the appropriate modifier
// key to the remote desktop.
- (uint16)modifiersForKeyCode:(int)keyCode
{
	uint16 rdFlags = 0;

	if (keyCode == 36 || keyCode == 63 || keyCode == 33 || keyCode == 34 || keyCode == 58 || keyCode == 40 || keyCode == 41 || keyCode == 38 || keyCode == 64 || keyCode == 126)	//User hit the "?"
	{
		[self setRemoteModifiers:NX_DEVICERSHIFTKEYMASK];
	}
	
	if (keyCode == 123 || keyCode == 125 || keyCode == 35 || keyCode == 37 || keyCode == 94 || keyCode == 43 || keyCode == 95 || keyCode == 124 || keyCode == 125 || keyCode == 60 || keyCode == 62)	//User hit the "?"
	{
		[self setRemoteModifiers:NX_DEVICERSHIFTKEYMASK];
	}
	
	if (keyCode >= 65 && keyCode <= 90)
	{
		[self setRemoteModifiers:NX_DEVICERSHIFTKEYMASK];
	}
	return rdFlags;
}

@end
