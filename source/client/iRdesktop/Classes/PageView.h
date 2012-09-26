/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 PageView.h
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


#import <UIKit/UIKit.h>
#import <QuartzCore/CoreAnimation.h>
#import "CALayerDelegate.h"


@interface PageView : UIView 
{
	id delegate;
	BOOL isZoomed;
	UIPageControl *pageControl;
	UILabel *titleLabel;
	UILabel *subTitleLabel;
	NSMutableArray *views;
	NSMutableArray *closeButtons;
	CALayerDelegate *layerDelegate;
	
	CGPoint startTouchPosition;
	
	BOOL orientationChangeSinceLastLayout;

	CGFloat HORIZ_SWIPE_DRAG_MIN;
	CGFloat VERT_SWIPE_DRAG_MAX;

	
	CGFloat kPageControlDistanceFromBottom;
	CGFloat kDistanceBetweenPagesPortrait;
	CGFloat kPageTopPortrait;
	CGFloat kPageWidthPortrait;
	CGFloat kPageHeightPortrait;
	CGFloat kTitleLabelTopPortrait;
		
	CGFloat kDistanceBetweenPagesLandscape;
	CGFloat kPageTopLandscape;
	CGFloat kPageWidthLandscape;
	CGFloat kPageHeightLandscape;
	CGFloat kTitleLabelTopLandscape;	
}

////////////////////
/// Initializers ///
////////////////////
- (id)initWithFrame:(CGRect)frame delegate:(id)object;

/////////////////
/// Accessors ///
/////////////////
- (int)currentPageNumber;
- (void)setOrientationChangeSinceLastLayout:(BOOL)value;

///////////////////////////////
/// Drawing Related Methods ///
///////////////////////////////
- (void)drawBackgroundGradient;
- (UIPageControl *)setupPageControl;
- (UILabel *)setupTitleLabel;
- (UILabel *)setupSubTitleLabel;
- (void)layoutPages;
- (void)scrollToPage:(int)pageNumber animated:(BOOL)animated andZoom:(BOOL)zoom;
- (void)removePageAtPageNumber:(int)pageNumber animated:(BOOL)animated;
- (void)userDidChangePage;
- (void)zoomCurrentPage;
- (void)unZoomCurrentPage;
- (BOOL)isZoomed;
- (void)hideCloseButtonForCurrentPageWithCallbackObject:(id)object selector:(SEL)selector;
- (void)showCloseButtonForCurrentPage;

////////////////////////////////
/// Delegate Related Methods ///
////////////////////////////////
- (void)setDelegate:(id)object;
- (id)delegate;

@end

@protocol PageViewDelegate
- (int)numberOfPagesToDisplay;
- (UIView *)viewForPageNumber:(int)pageNumber;
- (CGRect)rectForZoomedPage;
@optional
- (NSString *)titleForPageNumber:(int)page;
- (NSString *)subTitleForPageNumber:(int)page;
- (BOOL)shouldSelectPageNumber:(int)page;
- (void)willSelectPageNumber:(int)page;
- (void)didSelectPageNumber:(int)page;
- (void)willUnzoomCurrentPage;
- (void)didUnzoomCurrentPage;
- (void)willZoomCurrentPage;
- (void)didZoomCurrentPage;
- (void)userDidClosePageAtPageNumber:(int)pageNumber;
@end