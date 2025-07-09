//
//  ZintDataMatrix.h
//  ZintDataMatrix
//
//  Created by Alessandro Maroso on 13/05/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//! Project version number for ZintDataMatrix.
FOUNDATION_EXPORT double ZintDataMatrixVersionNumber;

//! Project version string for ZintDataMatrix.
FOUNDATION_EXPORT const unsigned char ZintDataMatrixVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ZintDataMatrix/PublicHeader.h>


@interface ZintDataMatrix : NSObject
+(UIImage * _Nullable)generateDataMatrix:(NSString * _Nonnull)data scale:(float)scale;
@end
