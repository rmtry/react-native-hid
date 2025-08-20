#pragma once
#include <cstdint>
#include <string>
#include <vector>

namespace hidcore {

struct DeviceInfo {
  uint16_t vendorId = 0;
  uint16_t productId = 0;
  uint16_t usagePage = 0;
  uint16_t usage = 0;
  std::string path;
  std::string manufacturer;
  std::string product;
  std::string serialNumber;
};

// Call once when your module starts (or lazily inside listAllDevices)
void init();       // idempotent, thread-safe
void shutdown();   // safe; balances init()

std::vector<DeviceInfo> listAllDevices();  // thread-safe

} // namespace hidcore
