/****************************************************************************
 Copyright (c) 2010 cocos2d-x.org
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#import "AccelerometerDelegateWrapper.h"

#import <CoreMotion/CoreMotion.h>

@interface AccelerometerDispatcher ()

@property (retain) CMMotionManager	*motionManager;
@property (retain) NSOperationQueue	*motionManagerOperationQueue;

@end

@implementation AccelerometerDispatcher

static AccelerometerDispatcher* s_pAccelerometerDispatcher;

@synthesize delegate_;
@synthesize acceleration_;
@synthesize motionManager = _motionManager;
@synthesize motionManagerOperationQueue = _motionManagerOperationQueue;

+ (id) sharedAccelerometerDispather
{
    if (s_pAccelerometerDispatcher == nil) {
        s_pAccelerometerDispatcher = [[self alloc] init];
    }
    
    return s_pAccelerometerDispatcher;
}

- (id) init
{
	_motionManagerOperationQueue = [[NSOperationQueue alloc] init];
	_motionManager = [[CMMotionManager alloc] init];
    acceleration_ = new cocos2d::CCAcceleration();
    return self;
}

- (void) dealloc
{
	[_motionManager release], _motionManager = nil;
	[_motionManagerOperationQueue release], _motionManagerOperationQueue = nil;
    s_pAccelerometerDispatcher = 0;
    delegate_ = 0;
    delete acceleration_;
    [super dealloc];
}

- (void) addDelegate: (cocos2d::CCAccelerometerDelegate *) delegate
{
    delegate_ = delegate;
    
    if (delegate_)
    {
		__block CMMotionManager *motionManager = self.motionManager;
		[self.motionManager startGyroUpdates];
		[self.motionManager startAccelerometerUpdatesToQueue:self.motionManagerOperationQueue
												 withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
													 if (error)
													 {
														 [motionManager stopAccelerometerUpdates];
														 return;
													 }
													 if (!delegate_)
													 {
														 return;
													 }
													 CMAcceleration acceleration = accelerometerData.acceleration;
													 acceleration_->x = acceleration.x;
													 acceleration_->y = acceleration.y;
													 acceleration_->z = acceleration.z;
													 acceleration_->g = -motionManager.gyroData.rotationRate.y;
													 
													 double tmp = acceleration_->x;
													 
													 switch ([[UIApplication sharedApplication] statusBarOrientation])
													 {
														 case UIInterfaceOrientationLandscapeRight:
															 acceleration_->x = -acceleration_->y;
															 acceleration_->y = tmp;
															 acceleration_->g = motionManager.gyroData.rotationRate.x;
															 break;
															 
														 case UIInterfaceOrientationLandscapeLeft:
															 acceleration_->x = acceleration_->y;
															 acceleration_->y = -tmp;
															 acceleration_->g = -motionManager.gyroData.rotationRate.x;
															 break;
															 
														 case UIInterfaceOrientationPortraitUpsideDown:
															 acceleration_->x = -acceleration_->y;
															 acceleration_->y = -tmp;
															 acceleration_->g = motionManager.gyroData.rotationRate.y;
															 break;
															 
														 case UIInterfaceOrientationPortrait:
															 break;
													 }
													 
													 delegate_->didAccelerate(acceleration_);
												 }];
    }
    else 
    {
		[self.motionManager stopGyroUpdates];
		[self.motionManager stopAccelerometerUpdates];
    }
}

-(void) setAccelerometerInterval:(float)interval
{
	[self.motionManager setAccelerometerUpdateInterval:interval];
	[self.motionManager setGyroUpdateInterval:interval];
}

@end

