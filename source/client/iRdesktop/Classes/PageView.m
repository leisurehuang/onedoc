/*
 ------------------------------------------------------------------------
 Thinstuff iRdesktop
 A RDP client for the iPhone and iPod Touch, based off WinAdmin
 (an iPhone RDP client by Carter Harrison) which is based off CoRD 
 (a Mac OS X RDP client by Craig Dooley and Dorian Johnson) which is in 
 turn based off of the Unix program rdesktop by Matthew Chapman.
 ------------------------------------------------------------------------
 
 PageView.m
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


#import "PageView.h"

@implementation PageView

- (id)initWithFrame:(CGRect)frame 
{
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		HORIZ_SWIPE_DRAG_MIN = 10;
		VERT_SWIPE_DRAG_MAX = 50;
		
		kPageControlDistanceFromBottom = 80;
		kDistanceBetweenPagesPortrait = 55.0;
		kPageTopPortrait = 200.0;
		kPageWidthPortrait = 350.0;
		kPageHeightPortrait = 500.0;
		kTitleLabelTopPortrait = 100.0;
		
		kDistanceBetweenPagesLandscape = 55;
		kPageTopLandscape = 130.0;
		kPageWidthLandscape = 275.0;
		kPageHeightLandscape = 400.0;
		kTitleLabelTopLandscape = 50.0;	
	}
	else
	{
		HORIZ_SWIPE_DRAG_MIN = 10;
		VERT_SWIPE_DRAG_MAX = 25;

		kPageControlDistanceFromBottom = 80;
		kDistanceBetweenPagesPortrait = 35.0;
		kPageTopPortrait = 100.0;
		kPageWidthPortrait = 160.0;
		kPageHeightPortrait = 240.0;
		kTitleLabelTopPortrait = 25.0;
		
		kDistanceBetweenPagesLandscape = 40;
		kPageTopLandscape = 70.0;
		kPageWidthLandscape = 240.0;
		kPageHeightLandscape = 160.0;
		kTitleLabelTopLandscape = 10.0;	
	}
	
	if (self = [super initWithFrame:frame]) 
	{
		// Initialization code
		pageControl = [self setupPageControl];
		titleLabel = [self setupTitleLabel];
		subTitleLabel = [self setupSubTitleLabel];
		[self addSubview:pageControl];
		[self addSubview:titleLabel];
		[self addSubview:subTitleLabel];
		isZoomed = NO;
		views = [[NSMutableArray alloc] initWithCapacity:0];
		closeButtons = [[NSMutableArray alloc] initWithCapacity:0];
		layerDelegate = [[CALayerDelegate alloc] init];
		
		orientationChangeSinceLastLayout = NO;
		
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame delegate:(id)object
{
	if (self = [self initWithFrame:frame])
	{
		[self setDelegate:object];
	}
	return self;
}

- (UIPageControl *)setupPageControl
{
	UIPageControl *pc = [[UIPageControl alloc] initWithFrame:CGRectMake(0.0, self.frame.size.height - kPageControlDistanceFromBottom, self.frame.size.width, 20)];
	[pc addTarget:self action:@selector(userDidChangePage) forControlEvents:UIControlEventValueChanged];
	pc.hidesForSinglePage = NO;
	return pc;
}

- (UILabel *)setupTitleLabel
{
	UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(0.0, kTitleLabelTopPortrait, self.frame.size.width, 25)];
	tl.textAlignment = UITextAlignmentCenter;
	UIFont *font = [UIFont boldSystemFontOfSize:24];
	tl.font = font;
	tl.textColor = [UIColor whiteColor];
	tl.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];				//Black shadow color with 70% opacity.
	tl.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];	//Set the background to any color that has 0% opacity.
	tl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	return tl;
}

- (UILabel *)setupSubTitleLabel
{
	UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(0.0, kTitleLabelTopPortrait + 25, self.frame.size.width, 25)];
	tl.textAlignment = UITextAlignmentCenter;
	UIFont *font = [UIFont boldSystemFontOfSize:16];
	tl.font = font;
	tl.textColor = [UIColor colorWithRed:.714 green:.741 blue:.765 alpha:1.0];
	tl.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.6];				//Black shadow color with 60% opacity.
	tl.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];	//Set the background to any color that has 0% opacity.
	tl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	return tl;
}

- (void)dealloc 
{
	[layerDelegate release];
	[views release];
	[super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    startTouchPosition = [touch locationInView:self];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if ([touches count] == 1)
	{
		UITouch *touch = touches.anyObject;
		CGPoint currentTouchPosition = [touch locationInView:self];

		// If the swipe tracks correctly.
		if (fabsf(startTouchPosition.x - currentTouchPosition.x) >= HORIZ_SWIPE_DRAG_MIN &&
			fabsf(startTouchPosition.y - currentTouchPosition.y) <= VERT_SWIPE_DRAG_MAX)
		{
			// It appears to be a swipe.
			if (startTouchPosition.x < currentTouchPosition.x)
			{
				if (pageControl.currentPage > 0)
				{
					[self scrollToPage:(pageControl.currentPage - 1) animated:YES andZoom:NO];
				}
				 
			}
			else
			{
				if (pageControl.currentPage < pageControl.numberOfPages)
				{
					[self scrollToPage:(pageControl.currentPage + 1) animated:YES andZoom:NO];
				}
				 
			}
		}
		else
		{
			// Process a non-swipe event.
			int left;
			CGRect pageFrame;
			CGRect closeButtonFrame;
			if ([delegate interfaceOrientation] == UIInterfaceOrientationPortrait || [delegate interfaceOrientation] == UIInterfaceOrientationPortraitUpsideDown)
			{
				CGRect r = [UIScreen mainScreen].applicationFrame;
				left = ([UIScreen mainScreen].applicationFrame.size.width - kPageWidthPortrait) / 2;
				pageFrame = CGRectMake(left, kPageTopPortrait, kPageWidthPortrait, kPageHeightPortrait);
				closeButtonFrame = CGRectMake(left - 11.5, kPageTopPortrait - 11.5, 23.0, 23.0);
			}
			else
			{
				CGRect r = [UIScreen mainScreen].applicationFrame;
				left = ([UIScreen mainScreen].applicationFrame.size.height - kPageWidthLandscape) / 2;
				pageFrame = CGRectMake(left, kPageTopLandscape, kPageWidthLandscape, kPageHeightLandscape);
				closeButtonFrame = CGRectMake(left - 11.5, kPageTopLandscape - 11.5, 23.0, 23.0);
			}
			CGPoint touchLocation = [[touches anyObject] locationInView:self];
			if (CGRectContainsPoint(closeButtonFrame, touchLocation))
			{
				if (delegate)
				{
					[delegate userDidClosePageAtPageNumber:pageControl.currentPage];
				}
			}
			else if (CGRectContainsPoint(pageFrame, touchLocation))
			{
				if (delegate && [delegate shouldSelectPageNumber:pageControl.currentPage])
				{
					[self zoomCurrentPage];
				}
			}
		}
	}
}

/////////////////
/// Accessors ///
/////////////////
- (int)currentPageNumber
{
	int numberOfPages = [delegate numberOfPagesToDisplay];
	if (numberOfPages > 0)
	{
		pageControl.numberOfPages = numberOfPages;
	}
	return pageControl.currentPage;
}

- (void)setOrientationChangeSinceLastLayout:(BOOL)value
{
	orientationChangeSinceLastLayout = value;
}


///////////////////////////////
/// Drawing Related Methods ///
///////////////////////////////
- (void)drawRect:(CGRect)rect 
{
	//Draw the background gradient
	[self drawBackgroundGradient];
}

- (void)drawBackgroundGradient
{
	//Setup
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGFloat components[] = {.57, .63, .68, 1.0, .3, .39, .46, 1.0};
	CGFloat locations[] = {0, 1};
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, components, locations, 2);
	
	//Draw
	CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0, 0.0), CGPointMake(self.frame.size.width, self.frame.size.height),0);
	
	//Cleanup
	CGColorSpaceRelease(colorspace);
	CGGradientRelease(gradient);
}

- (void)layoutSubviews
{
	[self setOrientationChangeSinceLastLayout:YES];
	[self layoutPages];
}

//This method lays out the pages into the view.
- (void)layoutPages
{
	if (delegate && [delegate conformsToProtocol:@protocol(PageViewDelegate)])
	{
		if (!isZoomed)
		{
			if ([delegate interfaceOrientation] == UIInterfaceOrientationPortrait || [delegate interfaceOrientation] == UIInterfaceOrientationPortraitUpsideDown)
			{
				titleLabel.frame = CGRectMake(titleLabel.frame.origin.x, kTitleLabelTopPortrait, titleLabel.frame.size.width, titleLabel.frame.size.height);
				subTitleLabel.frame = CGRectMake(0.0, kTitleLabelTopPortrait + 25, self.frame.size.width, 25);
			}
			else
			{
				titleLabel.frame = CGRectMake(titleLabel.frame.origin.x, kTitleLabelTopLandscape, titleLabel.frame.size.width, titleLabel.frame.size.height);
				subTitleLabel.frame = CGRectMake(0.0, kTitleLabelTopLandscape + 25, self.frame.size.width, 25);
			}
			
			int numberOfPages = [delegate numberOfPagesToDisplay];
			if (numberOfPages > 0)
			{
				pageControl.numberOfPages = numberOfPages;
				if (pageControl.currentPage < 0)
				{
					pageControl.currentPage = 0;
				}
				int currentPage = pageControl.currentPage;
				int i;
				for (i = 0 ; i < pageControl.numberOfPages ; i++)
				{
					//Get the view for the current iteration from the delegate.
					UIView *currentView = [delegate viewForPageNumber:i];
					
					if ([delegate interfaceOrientation] == UIInterfaceOrientationPortrait || [delegate interfaceOrientation] == UIInterfaceOrientationPortraitUpsideDown)
					{
						//Calculate frame and location for the current view controller's view based upon the current page.
						int xCoord = (self.frame.size.width / 2) - (kPageWidthPortrait / 2) + (i - pageControl.currentPage)*(kPageWidthPortrait + kDistanceBetweenPagesPortrait);

						//Draw the pages into the right location in the view
						[currentView setFrame:CGRectMake(xCoord, kPageTopPortrait, kPageWidthPortrait, kPageHeightPortrait)];
					}
					else
					{
						//Calculate frame and location for the current view controller's view based upon the current page.
						int xCoord = (self.frame.size.width / 2) - (kPageWidthLandscape / 2) + (i - pageControl.currentPage)*(kPageWidthLandscape + kDistanceBetweenPagesLandscape);
						
						//Draw the pages into the right location in the view
						[currentView setFrame:CGRectMake(xCoord, kPageTopLandscape, kPageWidthLandscape, kPageHeightLandscape)];
					}
					
					//Setup and position the layers responsible for the page's shadow and the page's close button.
					CALayer *closeLayer = [CALayer layer];
					if (![views containsObject:currentView])
					{
						//If this is a view we haven't seen before, add it to the array of views.
						[views addObject:currentView];
						
						//This is a new page.. Add a shadow.
						CALayer *shadowLayer = [CALayer layer];
						CALayer *superLayer = [currentView layer];
						[superLayer addSublayer:shadowLayer];
						shadowLayer.zPosition = -2;
						shadowLayer.anchorPoint = CGPointMake(0.0, 0.0);
						shadowLayer.bounds = CGRectMake(0.0, 0.0, superLayer.frame.size.width + 6, superLayer.frame.size.height + 6);
						
						[shadowLayer setValue:@"page" forKey:@"type"];
						[shadowLayer setDelegate:layerDelegate];
						[shadowLayer setNeedsDisplay];
						
						//This is a new page.. Add a close button.  The delegate actually does the drawing of the layer
						closeLayer.bounds = CGRectMake(0.0, 0.0, 35.0, 35.0);
						closeLayer.position = CGPointMake(6, 6);
						closeLayer.zPosition = 2;
						[closeLayer setValue:@"close" forKey:@"type"];
						[closeLayer setDelegate:layerDelegate];
						[closeLayer setNeedsDisplay];
						[[currentView layer] addSublayer:closeLayer];
						[closeButtons addObject:closeLayer];
					}
					else
					{
						//This code only needs to happen once per page after an orientation change has occurred.
						if (orientationChangeSinceLastLayout)
						{
							int s = 0;
							currentView.layer.frame = currentView.frame;
							for (s = 0 ; s < [[currentView layer] sublayers].count ; s++)
							{
								CALayer *thisLayer = [currentView.layer.sublayers objectAtIndex:s];
								if ([thisLayer valueForKey:@"type"] == @"page")
								{
									thisLayer.anchorPoint = CGPointMake(0.0, 0.0);
									thisLayer.bounds = CGRectMake(0.0, 0.0, [thisLayer superlayer].frame.size.width + 6, [thisLayer superlayer].frame.size.height + 6);
									[thisLayer setNeedsDisplay];
								}
							}
						}
					}
					
					//Check to see if this view is part of this view hierarchy
					if (self != [currentView superview])
					{
						if ([currentView superview])
						{
							[currentView removeFromSuperview];
						}					
						currentView.alpha = 0.0;
						[self addSubview:currentView];
					}
					
					[UIView beginAnimations:@"fadePage" context:nil];
					[UIView setAnimationDuration:.3];
					[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];

					CALayer *thisCloseLayer = [closeButtons objectAtIndex:i];
					if (currentPage == i)
					{
						//Set opacity levels to be correct for current page
						currentView.alpha = 1.0;
						thisCloseLayer.opacity = 1.0;
						
						//Update the title and subtitle
						titleLabel.text = [delegate titleForPageNumber:i];
						subTitleLabel.text = [delegate subTitleForPageNumber:i];
					}
					else
					{
						//Set opacity levels to be correct for non-current page
						currentView.alpha = .4;
						thisCloseLayer.opacity = 0.0;
					}
					[UIView commitAnimations];
				}
				orientationChangeSinceLastLayout = NO;
			}
		}
		
		// adjust pageControl frame
		pageControl.frame = CGRectMake(0.0, self.frame.size.height - kPageControlDistanceFromBottom, self.frame.size.width, 20);		
	}
}

- (void)scrollToPage:(int)pageNumber animated:(BOOL)animated andZoom:(BOOL)zoom
{
	pageControl.numberOfPages = [delegate numberOfPagesToDisplay];
	if (pageNumber <= (pageControl.numberOfPages - 1))
	{
		UIView *thisPage = [delegate viewForPageNumber:pageNumber];
		if (thisPage.superview != self)
		{
			int xCoord = (self.frame.size.width / 2) - (kPageWidthPortrait / 2) + (pageControl.numberOfPages - 1)*(kPageWidthPortrait + kDistanceBetweenPagesPortrait);
			thisPage.frame = CGRectMake(xCoord, kPageTopPortrait, kPageWidthPortrait, kPageHeightPortrait);
		}
		
		int pageDifference = abs(pageControl.currentPage - pageNumber);
		if (pageDifference == 0)
		{
			pageDifference = 1;
		}
		pageControl.currentPage = pageNumber;
		if (animated)
		{
			[UIView beginAnimations:@"changePage" context:nil];
			if (zoom)
			{
				[UIView setAnimationDelegate:self];
				[UIView setAnimationDidStopSelector:@selector(zoomCurrentPage)];
			}
			[UIView setAnimationBeginsFromCurrentState:NO];
			[UIView setAnimationDuration:(.3 * pageDifference)];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[self layoutPages];
			[UIView commitAnimations];
		}
		else
		{
			[self layoutPages];
		}
	}
}

- (void)removePageAtPageNumber:(int)pageNumber animated:(BOOL)animated
{
	UIView *view = [views objectAtIndex:pageNumber];
	[views removeObjectAtIndex:pageNumber];
	[closeButtons removeObjectAtIndex:pageNumber];
	[view removeFromSuperview];
	
	if (animated)
	{
		[UIView beginAnimations:@"removePage" context:nil];
		[UIView setAnimationDuration:.3];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[self layoutPages];
		[UIView commitAnimations];
	}
	else
	{
		[self layoutPages];
	}
	
	if ([views count] == 0)
	{
		titleLabel.text = @"";
		subTitleLabel.text = @"";
	}
}

- (void)userDidChangePage
{
	[self scrollToPage:[pageControl currentPage] animated:YES andZoom:NO];
}

- (void)zoomCurrentPage
{
	if (delegate && [delegate conformsToProtocol:@protocol(PageViewDelegate)])
	{
		[delegate willSelectPageNumber:pageControl.currentPage];
		[delegate willZoomCurrentPage];
		isZoomed = YES;
		[UIView beginAnimations:@"zoomPageIn" context:nil];
		[UIView setAnimationDelegate:delegate];
		[UIView setAnimationDuration:.4];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationBeginsFromCurrentState:NO];
		[UIView setAnimationDidStopSelector:@selector(didZoomCurrentPage)];
		[delegate viewForPageNumber:pageControl.currentPage].frame = [delegate rectForZoomedPage];
		[[closeButtons objectAtIndex:pageControl.currentPage] setOpacity:0.0];
		titleLabel.alpha = 0.0;
		subTitleLabel.alpha = 0.0;
		[UIView commitAnimations];
		[delegate didSelectPageNumber:pageControl.currentPage];
	}
}

- (void)unZoomCurrentPage
{
	if (isZoomed)
	{
		if (delegate && [delegate conformsToProtocol:@protocol(PageViewDelegate)])
		{
			[delegate willUnzoomCurrentPage];
			isZoomed = !isZoomed;
			UIView *thisPage = [delegate viewForPageNumber:[pageControl currentPage]];
			CALayer *closeButton = [closeButtons objectAtIndex:pageControl.currentPage];
			[UIView beginAnimations:@"zoomPageIn" context:nil];
			[UIView setAnimationDuration:.4];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			
			if ([delegate interfaceOrientation] == UIInterfaceOrientationPortrait || [delegate interfaceOrientation] == UIInterfaceOrientationPortraitUpsideDown)
			{
				int xCoord = (self.frame.size.width / 2) - (kPageWidthPortrait / 2) + (kPageWidthPortrait + kDistanceBetweenPagesPortrait);
				
				//Draw the pages into the right location in the view
				[thisPage setFrame:CGRectMake(xCoord, kPageTopPortrait, kPageWidthPortrait, kPageHeightPortrait)];
			}
			else
			{
				//Calculate frame and location for the current view controller's view based upon the current page.
				int xCoord = (self.frame.size.width / 2) - (kPageWidthLandscape / 2) + (kPageWidthLandscape + kDistanceBetweenPagesLandscape);
				
				//Draw the pages into the right location in the view
				[thisPage setFrame:CGRectMake(xCoord, kPageTopLandscape, kPageWidthLandscape, kPageHeightLandscape)];
			}
			thisPage.layer.frame = thisPage.frame;
			[thisPage.layer setNeedsDisplay];
			
			titleLabel.alpha = 1.0;
			subTitleLabel.alpha = 1.0;
			closeButton.opacity = 1.0;
			[UIView commitAnimations];
			[delegate didUnzoomCurrentPage];
		}
	}
}

- (BOOL)isZoomed
{
	return isZoomed;
}

- (void)hideCloseButtonForCurrentPageWithCallbackObject:(id)object selector:(SEL)selector;
{
	UIView *thisPage = [delegate viewForPageNumber:[pageControl currentPage]];
	CALayer *superLayer = [thisPage layer];
	CALayer *closeLayer;
	int i = 0;
	for (i = 0 ; i < superLayer.sublayers.count ; i++)
	{
		if ([[[superLayer.sublayers objectAtIndex:i] valueForKey:@"type"] isEqualToString:@"close"])
		{
			closeLayer = [superLayer.sublayers objectAtIndex:i];
		}
	}
	[UIView beginAnimations:@"hideCloseButton" context:nil];
	[UIView setAnimationDuration:.6];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	if (object)
	{
		[UIView setAnimationDelegate:object];
		[UIView setAnimationDidStopSelector:selector];
	}
	closeLayer.opacity = 0.0;
	[UIView commitAnimations];
}

- (void)showCloseButtonForCurrentPage
{
	UIView *thisPage = [delegate viewForPageNumber:[pageControl currentPage]];
	CALayer *superLayer = [thisPage layer];
	int i = 0;
	for (i = 0 ; i < superLayer.sublayers.count ; i++)
	{
		CALayer *thisLayer = [superLayer.sublayers objectAtIndex:i];
		if ([[thisLayer valueForKey:@"type"] isEqualToString:@"close"])
		{
			[UIView beginAnimations:@"hideCloseButton" context:nil];
			[UIView setAnimationDuration:.2];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			thisLayer.opacity = 1.0;
			[UIView commitAnimations];
		}
	}	
}

////////////////////////////////
/// Delegate Related Methods ///
////////////////////////////////
- (void)setDelegate:(id)object
{
	if (delegate)
	{
		[delegate release];
	}
	delegate = object;
	[object retain];
	
	int numberOfPages = [delegate numberOfPagesToDisplay];
	if (numberOfPages > 0)
	{
		pageControl.numberOfPages = numberOfPages;
	}
}

- (id)delegate
{
	return delegate;
}

@end
