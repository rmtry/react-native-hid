// HIDCppNativeModule.mm
#import "HIDCppNativeModule.h"
#import <React/RCTBridge.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTUtils.h> // for bridge notifications

#include <memory>
#include "../cpp/include/HIDCore.h"
#include "../cpp/include/HIDMonitor.h"

static NSDictionary *ToDict(const hidcore::DeviceInfo &d) {
  return @{
    @"vendorId":    @(d.vendorId),
    @"productId":   @(d.productId),
    @"path":        (d.path.empty() ? @"" : [NSString stringWithUTF8String:d.path.c_str()]),
    @"manufacturer":(d.manufacturer.empty() ? @"" : [NSString stringWithUTF8String:d.manufacturer.c_str()]),
    @"product":     (d.product.empty() ? @"" : [NSString stringWithUTF8String:d.product.c_str()]),
    @"serialNumber":(d.serialNumber.empty() ? @"" : [NSString stringWithUTF8String:d.serialNumber.c_str()]),
    @"usagePage":   @(d.usagePage),
    @"usage":       @(d.usage),
  };
}

@interface HIDCppNativeModule ()
- (void)startMonitorIfNeeded;
- (void)stopMonitor;
@end

@implementation HIDCppNativeModule {
  std::unique_ptr<hidcore::HIDMonitor> _monitor;
  NSInteger _listenerCount;
}

RCT_EXPORT_MODULE();
+ (BOOL)requiresMainQueueSetup { return NO; }

- (instancetype)init {
  if (self = [super init]) {
    // Keep hidapi alive for this module’s lifetime (and across listeners).
    // This runs on the main thread in RN-macos by default.
    hidcore::init();

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopMonitor)
                                                 name:RCTBridgeWillReloadNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopMonitor)
                                                 name:RCTBridgeWillBeInvalidatedNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self stopMonitor];
  hidcore::shutdown(); // balanced with init()
}

- (void)setBridge:(RCTBridge *)bridge {
  [super setBridge:bridge];
  // When a new bridge is set up, we’ll start again on the first addListener.
}

- (NSArray<NSString *> *)supportedEvents {
  return @[@"attached", @"detached"];
}

RCT_EXPORT_METHOD(addListener:(NSString *)eventName)
{
  [super addListener:eventName];
  _listenerCount++;
  if (_listenerCount == 1) {
    [self startMonitorIfNeeded];
  }
}

RCT_EXPORT_METHOD(removeListeners:(double)count)
{
  [super removeListeners:count];
  _listenerCount = MAX(0, _listenerCount - (NSInteger)count);
  if (_listenerCount == 0) {
    [self stopMonitor];
  }
}

RCT_EXPORT_METHOD(removeAllListeners)
{
  _listenerCount = 0;
  [self stopMonitor];
}

- (void)invalidate {
  // Called when the module is being torn down
  [self stopMonitor];
  [super invalidate];
}

- (void)startMonitorIfNeeded {
  if (_monitor) return;
  if (!self.bridge || !self.bridge.isValid) return; // don’t start during teardown

  _monitor = std::make_unique<hidcore::HIDMonitor>();
  __weak HIDCppNativeModule *weakSelf = self;

  _monitor->start(
    // onAttached
    [weakSelf](const hidcore::DeviceInfo& d){
      HIDCppNativeModule *selfRef = weakSelf;
      if (!selfRef || !selfRef.bridge || !selfRef.bridge.isValid) return;
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!selfRef.bridge || !selfRef.bridge.isValid) return;
        [selfRef sendEventWithName:@"attached" body:ToDict(d)];
      });
    },
    // onDetached
    [weakSelf](const hidcore::DeviceInfo& d){
      HIDCppNativeModule *selfRef = weakSelf;
      if (!selfRef || !selfRef.bridge || !selfRef.bridge.isValid) return;
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!selfRef.bridge || !selfRef.bridge.isValid) return;
        [selfRef sendEventWithName:@"detached" body:ToDict(d)];
      });
    },
    /*pollMs=*/800
  );
}

- (void)stopMonitor {
  // Safe to call multiple times; ensures thread joins before reload
  if (_monitor) {
    _monitor->stop();
    _monitor.reset();
  }
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
