#import <UIKit/UIKit.h>

@interface SBIconImageView: UIView
@end

CGFloat radius = 1.0;
CGFloat cornerRadius = 13.0;
CGFloat opacity = 0.0;
CGSize offset = (CGSize){0.0, 0.0};

%hook SBIconImageView

- (void)setFrame:(CGRect)frame
{
    %orig(frame);
    // Hacky code actually. This leads to only one branch, not two and not three
    if ((int)frame.size.width + (int)frame.size.height == 0) {
        return;
    }

    CGPathRef shadowPath = CGPathCreateWithRoundedRect((CGRect){{0.0, 0.0}, frame.size}, cornerRadius, cornerRadius, NULL);

    CALayer *layer = self.layer;
    layer.shadowPath = shadowPath;
    layer.shadowRadius = radius;
    layer.shadowOpacity = opacity;
    layer.shadowOffset = offset;

    CFRelease(shadowPath);
}

%end

void reloadPrefs()
{
    CFDictionaryRef preferences = CFPreferencesCopyMultiple(NULL, CFSTR("ru.danpashin.striges"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

    CFTypeRef prefsValue = NULL;
    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("radius"), &prefsValue)) {
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &radius);
    }

    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("cornerRadius"), &prefsValue)) {
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &cornerRadius);
    }

    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("opacity"), &prefsValue)) {
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &opacity);
    }

    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("offsetX"), &prefsValue)) {
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &offset.width);
    }

    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("offsetY"), &prefsValue)) {
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &offset.height);
    }


    CFRelease(preferences);
}

%ctor {
    reloadPrefs();
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, nil, ( CFNotificationCallback)reloadPrefs, CFSTR("ru.danpashin.striges/prefs"), nil, CFNotificationSuspensionBehaviorDeliverImmediately);

    %init;
}
