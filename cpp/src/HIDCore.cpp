#include "HIDCore.h"
#include <vector>
#include <string>
#include <cstdlib>

extern "C" {
  #include "../../third-party/hidapi/hidapi.h"
}

#ifdef _WIN32
  #include <windows.h>
  static std::string wstr_to_utf8(const wchar_t* w) {
    if (!w) return {};
    int len = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (len <= 1) return {};
    std::string s(len - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, s.data(), len, nullptr, nullptr);
    return s;
  }
#else
  #include <wchar.h>
  static std::string wstr_to_utf8(const wchar_t* w) {
    if (!w) return {};
    std::mbstate_t st{};
    const wchar_t* src = w;
    size_t len = wcsrtombs(nullptr, &src, 0, &st);
    if (len == static_cast<size_t>(-1)) return {};
    std::string s(len, '\0');
    st = std::mbstate_t{};
    src = w;
    wcsrtombs(s.data(), &src, len, &st);
    return s;
  }
#endif

namespace hidcore {

std::vector<DeviceInfo> listAllDevices() {
  std::vector<DeviceInfo> out;

  if (hid_init() != 0) {
    return out;
  }

  hid_device_info* devs = hid_enumerate(0, 0); // enumerate all devices
  for (auto* cur = devs; cur; cur = cur->next) {
    DeviceInfo d;
    d.vendorId   = cur->vendor_id;
    d.productId  = cur->product_id;
    d.path       = cur->path ? cur->path : "";
    d.manufacturer = wstr_to_utf8(cur->manufacturer_string);
    d.product      = wstr_to_utf8(cur->product_string);
    d.serialNumber = wstr_to_utf8(cur->serial_number);
    d.usagePage  = cur->usage_page;
    d.usage      = cur->usage;
    out.emplace_back(std::move(d));
  }

  hid_free_enumeration(devs);
  hid_exit();
  return out;
}

} // namespace hidcore
