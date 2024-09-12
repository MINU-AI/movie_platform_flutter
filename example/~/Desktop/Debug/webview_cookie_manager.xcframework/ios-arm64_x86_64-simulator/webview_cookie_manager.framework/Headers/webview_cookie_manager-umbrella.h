#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "WebviewCookieManagerPlugin.h"

FOUNDATION_EXPORT double webview_cookie_managerVersionNumber;
FOUNDATION_EXPORT const unsigned char webview_cookie_managerVersionString[];

