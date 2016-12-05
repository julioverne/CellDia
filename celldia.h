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
@end

@interface PackageCell : UITableViewCell
@property (nonatomic,retain) id info_;
@end