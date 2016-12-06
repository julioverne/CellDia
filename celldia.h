namespace Cytore {
	
static const uint32_t Magic = 'cynd';

struct Header {
    uint32_t magic_;
    uint32_t version_;
    uint32_t size_;
    uint32_t reserved_;
};

template <typename Target_>
class Offset {
  private:
    uint32_t offset_;

  public:
    Offset() :
        offset_(0)
    {
    }

    Offset(uint32_t offset) :
        offset_(offset)
    {
    }

    Offset &operator =(uint32_t offset) {
        offset_ = offset;
        return *this;
    }

    uint32_t GetOffset() const {
        return offset_;
    }

    bool IsNull() const {
        return offset_ == 0;
    }
};

struct Block {
     Cytore::Offset<void> reserved_;
 };
}
struct PackageValue :
     Cytore::Block
 {
     Cytore::Offset<PackageValue> next_;
 
     uint32_t index_ : 23;
     uint32_t subscribed_ : 1;
     uint32_t : 8;
 
     int32_t first_;
     int32_t last_;
 
     uint16_t vhash_;
     uint16_t nhash_;
 
     char version_[8];
     char name_[];
 };
 
@interface Package
- (id)latest;
- (PackageValue *) metadata;
- (id)getField:(id)fp8;
- (size_t) size;
- (BOOL) uninstalled;

- (BOOL) upgradableAndEssential:(BOOL)arg1;

- (void) install;
- (void) remove;
@end

@interface Cydia
- (void) resolve;
- (void) queue;
@end

@interface PackageCell : UITableViewCell
@property (nonatomic,retain) id info_;
@end

@interface PackageListController : UIViewController
-(id)packageAtIndexPath:(id)arg1;
@end

@interface SKUIItemOfferButton : UIControl

+ (id)itemOfferButtonWithAppearance:(id)arg1;
+ (id)_defaultTitleAttributes;
+ (CGSize)_titleSizeThatFitsForSize:(CGSize)arg1 titleStyle:(long long)arg2 mutableAttributedString:(id)arg3;

- (void)setBackgroundColor:(id)arg1;
- (void)setFrame:(CGRect)arg1;
- (void)setProgressType:(long long)arg1;
- (void)setTitle:(id)arg1;

- (bool)setTitle:(id)arg1 confirmationTitle:(id)arg2 itemState:(id)arg3 clientContext:(id)arg4 animated:(bool)arg5;
- (void)setConfirmationTitle:(id)arg1;
- (void)setConfirmationTitleStyle:(long long)arg1;
- (void)setTitleStyle:(long long)arg1;

- (void)setShowingConfirmation:(bool)arg1 animated:(bool)arg2;
- (void)setShowsConfirmationState:(bool)arg1;

@end


