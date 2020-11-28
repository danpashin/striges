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
    // Check if view has size. There's no reason to set shadow for hidden view.
    // Hacky code actually. This leads to only one branch, not two and not three
    if ((int)frame.size.width + (int)frame.size.height == 0) {
        return;
    }

    // CoreGraphics is 4.125 times faster than UIKit!
    CGPathRef shadowPath = CGPathCreateWithRoundedRect((CGRect){{0.0, 0.0}, frame.size}, cornerRadius, cornerRadius, NULL);

    CALayer *layer = self.layer;
    // Setter retains object
    layer.shadowPath = shadowPath;
    layer.shadowRadius = radius;
    layer.shadowOpacity = opacity;
    layer.shadowOffset = offset;

    // shadowPath was created by calling create method and retained by shadowPath setter - so release
    CFRelease(shadowPath);
}

%end

void reloadPrefs()
{
    // CoreFoundation is at least 2 times faster than Foundation for getting one preference value!
    CFDictionaryRef preferences = CFPreferencesCopyMultiple(NULL, CFSTR("ru.danpashin.striges"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

    CFTypeRef prefsValue = NULL;
    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("radius"), &prefsValue)) {
        // no need to free prefsValue as it was got via get method
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &radius);
    }

    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("cornerRadius"), &prefsValue)) {
        // no need to free prefsValue as it was got via get method
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &cornerRadius);
    }

    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("opacity"), &prefsValue)) {
        // no need to free prefsValue as it was got via get method
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &opacity);
    }

    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("offsetX"), &prefsValue)) {
        // no need to free prefsValue as it was got via get method
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &offset.width);
    }

    if (CFDictionaryGetValueIfPresent(preferences, CFSTR("offsetY"), &prefsValue)) {
        // no need to free prefsValue as it was got via get method
        CFNumberGetValue(prefsValue, kCFNumberCGFloatType, &offset.height);
    }

    // preferences were created by calling copy method - so release
    CFRelease(preferences);
}

%ctor {
    reloadPrefs();
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();

    // Sign for prefs change notification
    CFNotificationCenterAddObserver(
        center, nil, (CFNotificationCallback)reloadPrefs, CFSTR("ru.danpashin.striges/prefs"),
        nil, CFNotificationSuspensionBehaviorDeliverImmediately
    );

    // Init hooks manually to avoid creating second constructor
    %init;
}
