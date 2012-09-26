/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 RDCKeyboard.h
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


#import "rdesktop.h"

#define	NX_DEVICELCTLKEYMASK	0x00000001
#define	NX_DEVICELSHIFTKEYMASK	0x00000002
#define	NX_DEVICERSHIFTKEYMASK	0x00000004
#define	NX_DEVICELCMDKEYMASK	0x00000008
#define	NX_DEVICERCMDKEYMASK	0x00000010
#define	NX_DEVICELALTKEYMASK	0x00000020
#define	NX_DEVICERALTKEYMASK	0x00000040
#define NX_DEVICERCTLKEYMASK	0x00002000

@class RDInstance;

@interface RDCKeyboard : NSObject
{
	@private
		unsigned remoteModifiers;
		NSMutableDictionary *virtualKeymap;
		NSMutableDictionary *specialCharacterKeymap;
		NSMutableDictionary *numericKeymap;
		RDInstance *controller;
}

- (void)registerSpecialKeycodes;
- (void)handleKeyCode:(int)keyCode keyDown:(BOOL)down;
- (RDInstance *)controller;
- (void)setController:(RDInstance *)cont;
- (void)sendKeycode:(uint8)keyCode modifiers:(uint16)rdflags pressed:(BOOL)down;
- (void)sendScancode:(uint8)scancode flags:(uint16)flags;
- (BOOL)handleSpecialKey:(NSString *)key;

+ (unsigned)windowsKeymapForMacKeymap:(NSString *)keymapName;
+ (NSString *) currentKeymapName;
- (uint16)modifiersForKeyCode:(int)keyCode;

enum {
    NSAlphaShiftKeyMask         = 1 << 16,
    NSShiftKeyMask              = 1 << 17,
    NSControlKeyMask            = 1 << 18,
    NSAlternateKeyMask          = 1 << 19,
    NSCommandKeyMask            = 1 << 20,
    NSNumericPadKeyMask         = 1 << 21,
    NSHelpKeyMask               = 1 << 22,
    NSFunctionKeyMask           = 1 << 23,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
    NSDeviceIndependentModifierFlagsMask    = 0xffff0000UL
#endif
};

@end
