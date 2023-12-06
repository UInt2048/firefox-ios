#ifndef Client_Client_Bridging_Header_h
#define Client_Client_Bridging_Header_h

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

#import "FSReadingList.h"

#import "ThirdParty/Apple/UIImage+ImageEffects.h"

#import "Account-Bridging-Header.h"
#import "Shared-Bridging-Header.h"
#import "Storage-Bridging-Header.h"

// Inform older SDK versions that viewIsAppearing is defined.
#import "Availability.h"
#if !defined(__IPHONE_17_0)
@import UIKit;
@interface UIViewController (UpcomingLifecycleMethods)
- (void)viewIsAppearing:(BOOL)animated API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
@end
#endif

#endif
