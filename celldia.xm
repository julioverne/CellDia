#import <objc/runtime.h>
#import <substrate.h>
#import "celldia.h"

extern "C" void UISetColor(CGColorRef color);

static UIImage* kMaskForBlur;
static NSString* kNew;
static NSString* kUpdate;

static CGSize iconSize_;

static UIFont* FontSource_;
static UIFont* FontDescription_;
static UIFont* FontName_;

static CGColorRef Black_;
static CGColorRef White_;
static CGColorRef Gray_;
static CGColorRef Purple_;
static CGColorRef Purplish_;

CGFloat ScreenScale_;
static inline CGRect Retina(CGRect value) {
    value.origin.x *= ScreenScale_;
    value.origin.y *= ScreenScale_;
    value.size.width *= ScreenScale_;
    value.size.height *= ScreenScale_;
    value = CGRectIntegral(value);
    value.origin.x /= ScreenScale_;
    value.origin.y /= ScreenScale_;
    value.size.width /= ScreenScale_;
    value.size.height /= ScreenScale_;
    return value;
}

@implementation UIImage (CyCellImage)
+ (UIImage *)imageWithImage:(UIImage *)image size:(CGSize)imgSize Radius:(float)Radius isNew:(BOOL)isNew useSash:(BOOL)useSash
{
	if (&UIGraphicsBeginImageContextWithOptions != NULL) {
		UIGraphicsBeginImageContextWithOptions(imgSize, NO, 0.0);
	} else {
		UIGraphicsBeginImageContext(imgSize);
	}
	[[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, imgSize.width, imgSize.height) cornerRadius:Radius] addClip];
	[image drawInRect:CGRectMake(0, 0, imgSize.width, imgSize.height)];
	if (useSash) {
		CIImage *inputImage = [[CIImage alloc] initWithImage:image];
		CIContext *contextd = [CIContext contextWithOptions:nil];
		CGAffineTransform transform = CGAffineTransformIdentity;
		CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
		[clampFilter setValue:inputImage forKeyPath:kCIInputImageKey];
		[clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKeyPath:@"inputTransform"];
		CIImage *clampedImage = [clampFilter outputImage];
		CIFilter* blackGenerator = [CIFilter filterWithName:@"CIConstantColorGenerator"];
		CIColor* black = [CIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
		[blackGenerator setValue:black forKey:@"inputColor"];
		CIImage* blackImage = [blackGenerator valueForKey:@"outputImage"];
		CIFilter *compositeFilter = [CIFilter filterWithName:@"CIMultiplyBlendMode"];
		[compositeFilter setValue:blackImage forKey:@"inputImage"];
		[compositeFilter setValue:clampedImage forKey:@"inputBackgroundImage"];
		CIImage *darkenedImage = [compositeFilter outputImage];
		CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
		[blurFilter setDefaults];
		[blurFilter setValue:@(12.0f) forKey:@"inputRadius"];
		[blurFilter setValue:darkenedImage forKey:kCIInputImageKey];
		CIImage *blurredImage = [blurFilter outputImage];
		CGImageRef cgimg = [contextd createCGImage:blurredImage fromRect:inputImage.extent];
		UIImage *blurredAndDarkenedImage = [UIImage imageWithCGImage:cgimg];

		CGImageRef maskRef = kMaskForBlur.CGImage;
		CGBitmapInfo bitmapInfo = kCGImageAlphaNone;
		CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
		CGImageRef mask = CGImageCreate(CGImageGetWidth(maskRef),
				CGImageGetHeight(maskRef),
				CGImageGetBitsPerComponent(maskRef),
				CGImageGetBitsPerPixel(maskRef),
				CGImageGetBytesPerRow(maskRef),
				CGColorSpaceCreateDeviceGray(),
				bitmapInfo,
				CGImageGetDataProvider(maskRef),
				nil, NO,
				renderingIntent);
		CGImageRef masked = CGImageCreateWithMask([blurredAndDarkenedImage CGImage], mask);
		UIImage* invertMask = [UIImage imageWithCGImage:masked];
		[invertMask drawInRect:CGRectMake(imgSize.width/3, 0, imgSize.width/1.5, imgSize.height/1.5)];
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGPoint point = CGPointMake(imgSize.width/1.4, imgSize.height/20);
		CGContextSaveGState(context);
		CGContextTranslateCTM(context, point.x, point.y);
		CGAffineTransform textTransform = CGAffineTransformMakeRotation ( (M_PI * (45) / 180.0) );
		CGContextConcatCTM(context, textTransform);
		CGContextTranslateCTM(context, -point.x, -point.y);
		[[UIColor whiteColor] set];
		if(!kNew) {
			kNew = [[NSBundle mainBundle] localizedStringForKey:@"NEW" value:@"New" table:nil];
		}
		if(!kUpdate) {
			kUpdate = [[NSBundle mainBundle] localizedStringForKey:@"UPGRADE" value:@"Upgrade" table:nil];
		}
		[isNew?kNew:kUpdate
		drawAtPoint:point forWidth:imgSize.height/2 withFont:[UIFont boldSystemFontOfSize:isNew?9:8]
		fontSize:isNew?9:8 lineBreakMode:NSLineBreakByTruncatingTail baselineAdjustment:UITextAlignmentCenter];
		
		CGContextRestoreGState(context);
	}
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}
@end

static __strong NSString* kBs = @"%ld B";
static __strong NSString* kKs = @"%.1f KB";
static __strong NSString* kMs = @"%.2f MB";
static __strong NSString* kGs = @"%.3f GB";

NSString *bytesFormat(long bytes)
{
	if(bytes < 1024) {
		return [NSString stringWithFormat:kBs, bytes];
	} else if(bytes >= 1024 && bytes < 1024 * 1024) {
		return [NSString stringWithFormat:kKs, (double)bytes / 1024];
	} else if(bytes >= 1024 * 1024 && bytes < 1024 * 1024 * 1024) {
		return [NSString stringWithFormat:kMs, (double)bytes / (1024 * 1024)];
	} else {
		return [NSString stringWithFormat:kGs, (double)bytes / (1024 * 1024 * 1024)];
	}
}

%hook Package
- (time_t)seen
{
	return [self metadata]->last_;
}
- (UIImage *)icon
{
	UIImage* ret = %orig;
	if(ret) {
		BOOL useSash = NO;
		BOOL isNew = NO;
		time_t now_ = [[NSDate date] timeIntervalSince1970];
		PackageValue *metadata([self metadata]);
		if((now_ - metadata->last_) < 2*86400) {
			useSash = YES;
		}
		if(useSash) {
			if(metadata->first_ >= metadata->last_) {
				isNew = YES;
			}
		}
		ret = [UIImage imageWithImage:ret size:iconSize_ Radius:13.0f isNew:isNew useSash:useSash];
	}
	return ret;
}
%end

static __strong NSString* kSize = @"Size";
static __strong NSString* kInfoFormat = @"%@ • %@";


%hook PackageListController
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = %orig;
	if(cell) {
		if(UIView* oldBT = [cell viewWithTag:6656]) {
			[oldBT removeFromSuperview];
		}
		UIView* contentBT = [UIView new];
		contentBT.frame = CGRectMake(0,0,60,23);
		contentBT.tag = 6656;
		SKUIItemOfferButton*ButtonInstall = [%c(SKUIItemOfferButton) itemOfferButtonWithAppearance:nil];
		[ButtonInstall addTarget:self action:@selector(intPress:) forControlEvents:UIControlEventTouchUpInside];
		if (Package* myPackage = (Package*)[self packageAtIndexPath:indexPath]) {
			[ButtonInstall setTitle:[[NSBundle mainBundle] localizedStringForKey:[myPackage uninstalled]?@"INSTALL":[myPackage upgradableAndEssential:NO]?@"UPGRADE":@"REMOVE" value:nil table:nil]];
		}
		[ButtonInstall setBackgroundColor:[UIColor whiteColor]];
		[ButtonInstall setProgressType:0];
		[ButtonInstall setFrame:CGRectMake(0,0,60,23)];
		[contentBT addSubview:ButtonInstall];
		
		[contentBT setTranslatesAutoresizingMaskIntoConstraints:NO];
		[cell addSubview:contentBT];
		
		NSDictionary *viewDict = @{@"contentBT" : contentBT};
		[cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-24-[contentBT]-0-|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:viewDict]];
		[cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[contentBT]-26-|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:viewDict]];
		[contentBT addConstraint:[NSLayoutConstraint constraintWithItem:contentBT attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:contentBT attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
	}
	return cell;
}
%new
- (void)intPress:(UIView*)sender
{
	if(sender&&[sender respondsToSelector:@selector(superview)]) {
		UITableViewCell* cell = (UITableViewCell*)[[sender superview] superview];
		if(UITableView *tableHere = (UITableView *)object_getIvar(self, class_getInstanceVariable([self class], "list_"))) {
			NSIndexPath* indexPath = [tableHere indexPathForCell:cell];
			if (Package* myPackage = (Package*)[self packageAtIndexPath:indexPath]) {
				if([myPackage uninstalled] || [myPackage upgradableAndEssential:NO]) {
					[myPackage install];
				} else {
					[myPackage remove];
				}				
				[(Cydia*)[[UIApplication sharedApplication] delegate] resolve];
				[(Cydia*)[[UIApplication sharedApplication] delegate] queue];
			}
		}			
	}
}
%end

%hook PackageCell
%property (nonatomic,retain) id info_;
- (void) setPackage:(Package *)package asSummary:(bool)summary
{
	%orig;
	if(package != nil) {
		long sizeBytes = 0;
		@try {
			sizeBytes = [[package getField:kSize] intValue];
		} @catch (NSException * e) {
			@try {
				sizeBytes = [package size];
			} @catch (NSException * e) {
			}
		}
		self.info_ = [NSString stringWithFormat:kInfoFormat, [package latest], bytesFormat(sizeBytes)];		
	}
}

- (void) drawNormalContentRect:(CGRect)rect
{
	bool highlighted_ = (bool)object_getIvar(self, class_getInstanceVariable([self class], "highlighted_"));
	bool commercial_ = (bool)object_getIvar(self, class_getInstanceVariable([self class], "commercial_"));
	UIImage* icon_ = (UIImage *)object_getIvar(self, class_getInstanceVariable([self class], "icon_"));
	UIImage* badge_ = (UIImage *)object_getIvar(self, class_getInstanceVariable([self class], "badge_"));
	UIImage* placard_ = (UIImage *)object_getIvar(self, class_getInstanceVariable([self class], "placard_"));
	NSString* name_ = (NSString *)object_getIvar(self, class_getInstanceVariable([self class], "name_"));
	NSString* source_ = (NSString *)object_getIvar(self, class_getInstanceVariable([self class], "source_"));
	NSString* description_ = (NSString *)object_getIvar(self, class_getInstanceVariable([self class], "description_"));
	
	placard_ = nil;
	
    bool highlighted(highlighted_);
    float width([self bounds].size.width);
	
    if (icon_ != nil) {		
        CGRect rect;
        rect.size = [(UIImage *) icon_ size];
        while (rect.size.width > 50 || rect.size.height > 50) {
            rect.size.width /= 2;
            rect.size.height /= 2;
        }
        rect.origin.x = 36 - rect.size.width / 2;
        rect.origin.y = 36 - rect.size.height / 2;
        [icon_ drawInRect:Retina(rect)];
    }
	
    if (badge_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) badge_ size];
        rect.size.width /= 2;
        rect.size.height /= 2;
        rect.origin.x = 55 - rect.size.width / 2;
        rect.origin.y = 55 - rect.size.height / 2;
        [badge_ drawInRect:Retina(rect)];
    }
	
    if (highlighted && kCFCoreFoundationVersionNumber < 800) {
		UISetColor(White_);
	}
	
    if (!highlighted) {
		UISetColor(commercial_ ? Purple_ : Black_);
	}
	
    [name_ drawAtPoint:CGPointMake(70, 8) forWidth:(width - (placard_ == nil ? 80 : 106)) withFont:FontName_ lineBreakMode:NSLineBreakByTruncatingTail];
	[self.info_ drawAtPoint:CGPointMake(70, 23) forWidth:(width - 150) withFont:FontSource_ lineBreakMode:NSLineBreakByTruncatingTail];
    [source_ drawAtPoint:CGPointMake(70, 35) forWidth:(width - 150) withFont:FontSource_ lineBreakMode:NSLineBreakByTruncatingTail];
	
    if (!highlighted) {
		UISetColor(commercial_ ? Purplish_ : Gray_);
	}
	
	[description_ drawAtPoint:CGPointMake(70, 50) forWidth:(width - 80) withFont:FontDescription_ lineBreakMode:NSLineBreakByTruncatingTail];
	
	if (placard_ != nil) {
		[placard_ drawAtPoint:CGPointMake(width - 52, 9)];
	}
	
}
%end


__attribute__((constructor)) static void initialize_CyCell()
{
	UIScreen *screen([UIScreen mainScreen]);
	if ([screen respondsToSelector:@selector(scale)]) {
		ScreenScale_ = [screen scale];
	} else {
		ScreenScale_ = 1;
	}
	iconSize_ = CGSizeMake(50, 50);
	FontSource_ = [UIFont systemFontOfSize:10];
	FontDescription_ = [UIFont systemFontOfSize:11];
	FontName_ = [UIFont boldSystemFontOfSize:12];
	Black_ = [[UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0] CGColor];
	White_ = [[UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0] CGColor];
	Gray_ = [[UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0] CGColor];
	Purple_ = [[UIColor colorWithRed:0.0 green:0.0 blue:0.7 alpha:1.0] CGColor];
	Purplish_ = [[UIColor colorWithRed:0.4 green:0.4 blue:0.8 alpha:1.0] CGColor];
	if (!kMaskForBlur) {
		unsigned char MaskForBlurData[] = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x01, 0x02, 0x01, 0x03, 0x00, 0x00, 0x00, 0x2F, 0x81, 0x4B, 0x13, 0x00, 0x00, 0x00, 0x06, 0x50, 0x4C, 0x54, 0x45, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xA5, 0xD9, 0x9F, 0xDD, 0x00, 0x00, 0x00, 0x01, 0x74, 0x52, 0x4E, 0x53, 0x00, 0x40, 0xE6, 0xD8, 0x66, 0x00, 0x00, 0x01, 0x3A, 0x49, 0x44, 0x41, 0x54, 0x68, 0xDE, 0xED, 0xD0, 0xB1, 0x0D, 0x15, 0x41, 0x0C, 0x00, 0x51, 0xAF, 0x1C, 0x38, 0x74, 0x09, 0x2E, 0x65, 0xE9, 0x6C, 0x29, 0x8D, 0x52, 0x28, 0x81, 0x90, 0x00, 0xF1, 0x89, 0x4F, 0x87, 0xF4, 0x42, 0x24, 0xB4, 0x13, 0xBF, 0x68, 0xE2, 0x7C, 0x1E, 0x7D, 0x8D, 0x57, 0xFB, 0x29, 0xBE, 0xBD, 0xC5, 0x3C, 0xC5, 0xF7, 0xB7, 0xE8, 0xA7, 0xF8, 0xF1, 0x16, 0xF5, 0x14, 0x3F, 0xDF, 0x22, 0x9F, 0xE2, 0xD7, 0x5B, 0xAC, 0xA7, 0xF8, 0x1D, 0xEF, 0x3E, 0xCF, 0xDE, 0xE0, 0x0E, 0xB9, 0x43, 0xEE, 0x90, 0x3B, 0xE4, 0x0E, 0xF9, 0x1F, 0x87, 0x34, 0x87, 0x14, 0x87, 0x24, 0x87, 0x2C, 0x0F, 0xF9, 0x70, 0xC8, 0xE1, 0x90, 0xCD, 0x21, 0x73, 0x87, 0xDC, 0x21, 0x77, 0xC8, 0x1D, 0x72, 0x87, 0xDC, 0x21, 0x77, 0xC8, 0x1D, 0x72, 0x87, 0xDC, 0x21, 0xFF, 0x7E, 0xC8, 0x5F, 0xC4, 0x50, 0x34, 0x45, 0x51, 0x24, 0xC5, 0xA2, 0x08, 0x8B, 0x43, 0xB1, 0x29, 0x86, 0xA2, 0x29, 0x8A, 0x22, 0x29, 0x16, 0x45, 0x58, 0x1C, 0x8A, 0x4D, 0x31, 0x14, 0x4D, 0x51, 0x14, 0x49, 0xB1, 0x28, 0xC2, 0xE2, 0x50, 0x6C, 0x8A, 0xA1, 0x68, 0x8A, 0xA2, 0x48, 0x8A, 0x45, 0x11, 0x16, 0x87, 0x62, 0x53, 0x0C, 0x45, 0x53, 0x14, 0x45, 0x52, 0x2C, 0x8A, 0xB0, 0x38, 0x14, 0x9B, 0x62, 0x28, 0x9A, 0xA2, 0x28, 0x92, 0x62, 0x51, 0x84, 0xC5, 0xA1, 0xD8, 0x14, 0x43, 0xD1, 0x14, 0x45, 0x91, 0x14, 0x8B, 0x22, 0x2C, 0x0E, 0xC5, 0xA6, 0x18, 0x8A, 0xA6, 0x28, 0x8A, 0xA4, 0x58, 0x14, 0x61, 0x71, 0x28, 0x36, 0xC5, 0x50, 0x34, 0x45, 0x51, 0x24, 0xC5, 0xA2, 0x08, 0x8B, 0x43, 0xB1, 0x29, 0x86, 0xA2, 0x29, 0x8A, 0x22, 0x29, 0x16, 0x45, 0x58, 0x1C, 0x8A, 0x4D, 0x31, 0x14, 0x4D, 0x51, 0x14, 0x49, 0xB1, 0x28, 0xC2, 0xE2, 0x50, 0x6C, 0x8A, 0xA1, 0x68, 0x8A, 0xA2, 0x48, 0x8A, 0x45, 0x11, 0x16, 0x87, 0x62, 0x53, 0x0C, 0x45, 0x53, 0x14, 0x45, 0x52, 0x2C, 0x8A, 0xB0, 0x38, 0x14, 0x9B, 0x62, 0x28, 0x9A, 0xA2, 0x28, 0x92, 0x62, 0x51, 0x84, 0xC5, 0xA1, 0xD8, 0x14, 0x43, 0xD1, 0x14, 0x45, 0x91, 0x14, 0x8B, 0x22, 0x2C, 0xBE, 0xFC, 0x01, 0x47, 0x65, 0xB7, 0x95, 0x7A, 0xFA, 0xDB, 0x98, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82 };
		kMaskForBlur = [[UIImage imageWithData:[NSData dataWithBytes:MaskForBlurData length:sizeof(MaskForBlurData)]] copy];
	}
	%init;
}
