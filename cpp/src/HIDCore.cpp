#include "HIDCore.h"
#include <mutex>
#include <atomic>
#include <vector>
#include <string>

extern "C" {
  #include "../../third-party/hidapi/hidapi.h"
}

#ifdef _WIN32
  #include <windows.h>
  static std::string w2u(const wchar_t* w) {
    if (!w) return {};
    int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 1) return {};
    std::string s(n - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, s.data(), n, nullptr, nullptr);
    return s;
  }
#else
  #include <wchar.h>
  #include <cstdlib>
  static std::string w2u(const wchar_t* w) {
    if (!w) return {};
    std::mbstate_t st{};
    const wchar_t* src = w;
    size_t len = wcsrtombs(nullptr, &src, 0, &st);
    if (len == (size_t)-1) return {};
    std::string s(len, '\0');
    st = std::mbstate_t{};
    src = w;
    wcsrtombs(s.data(), &src, len, &st);
    return s;
  }
#endif

namespace {
std::mutex g_api_mutex;        // protects init/exit + enumerate
std::atomic<int> g_init_refs{0};
bool g_inited = false;

void ensure_inited_locked() {
  if (!g_inited) {
    // hidapi Darwin schedules a global IOHIDManager on the calling thread’s runloop.
    // Calling from the main thread is the safest default.
    hid_init();
    g_inited = true;
  }
}
} // namespace

namespace hidcore {

void init() {
  std::lock_guard<std::mutex> lk(g_api_mutex);
  ensure_inited_locked();
  ++g_init_refs;
}

void shutdown() {
  std::lock_guard<std::mutex> lk(g_api_mutex);
  if (g_init_refs > 0 && --g_init_refs == 0) {
    // Only tear down when nobody is using hidapi anymore.
    hid_exit();
    g_inited = false;
  }
}

std::vector<DeviceInfo> listAllDevices() {
  std::lock_guard<std::mutex> lk(g_api_mutex); // serialize hidapi global use

  ensure_inited_locked(); // lazy init if caller didn’t call init()

  std::vector<DeviceInfo> out;
  hid_device_info* devs = hid_enumerate(0, 0);
  for (auto* cur = devs; cur; cur = cur->next) {
    DeviceInfo d;
    d.vendorId     = cur->vendor_id;
    d.productId    = cur->product_id;
    d.usagePage    = cur->usage_page;
    d.usage        = cur->usage;
    d.path         = cur->path ? cur->path : "";
    d.manufacturer = w2u(cur->manufacturer_string);
    d.product      = w2u(cur->product_string);
    d.serialNumber = w2u(cur->serial_number);
    out.emplace_back(std::move(d));
  }
  hid_free_enumeration(devs);

  // IMPORTANT: DO NOT call hid_exit() here.
  return out;
}

} // namespace hidcore
