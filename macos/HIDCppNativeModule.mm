#import "HIDCppNativeModule.h"
#include "../cpp/include/HIDCore.h"

@implementation HIDCppNativeModule
RCT_EXPORT_MODULE();

static NSDictionary *ToDict(const hidcore::DeviceInfo &d) {
  return @{
    @"vendorId":    @(d.vendorId),
    @"productId":   @(d.productId),
    @"path":        [NSString stringWithUTF8String:d.path.c_str()],
    @"manufacturer":[NSString stringWithUTF8String:d.manufacturer.c_str()],
    @"product":     [NSString stringWithUTF8String:d.product.c_str()],
    @"serialNumber":[NSString stringWithUTF8String:d.serialNumber.c_str()],
    @"usagePage":   @(d.usagePage),
    @"usage":       @(d.usage),
  };
}

RCT_REMAP_METHOD(listAllDevices,
  listAllDevicesWithResolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    @try {
      auto vec = hidcore::listAllDevices();
      NSMutableArray *arr = [NSMutableArray arrayWithCapacity:vec.size()];
      for (const auto &d : vec) { [arr addObject:ToDict(d)]; }
      resolve(arr);
    } @catch (NSException *e) {
      reject(@"hid_error", e.reason, nil);
    }
  });
}

@end
