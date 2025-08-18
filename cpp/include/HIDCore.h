#pragma once
#include <string>
#include <vector>
#include <cstdint>

namespace hidcore {

struct DeviceInfo {
  uint16_t vendorId = 0;
  uint16_t productId = 0;
  std::string path;           // OS-specific path
  std::string manufacturer;   // UTF-8
  std::string product;        // UTF-8
  std::string serialNumber;   // UTF-8
  uint16_t usagePage = 0;
  uint16_t usage = 0;
};

std::vector<DeviceInfo> listAllDevices();

} // namespace hidcore
