#pragma once
#include "HIDCore.h"
#include <atomic>
#include <functional>
#include <thread>
#include <unordered_map>

namespace hidcore {

using DeviceCallback = std::function<void(const DeviceInfo&)>;

class HIDMonitor {
public:
  HIDMonitor() = default;
  ~HIDMonitor();

  // Start polling every pollMs milliseconds (e.g., 800ms)
  void start(DeviceCallback onAttached,
             DeviceCallback onDetached,
             int pollMs = 800);

  void stop();
  bool running() const { return running_; }

private:
  void loop(int pollMs);

  std::atomic<bool> running_{false};
  std::thread thread_;
  DeviceCallback onAttached_;
  DeviceCallback onDetached_;
  // Keyed by device `path` (stable identifier from hidapi)
  std::unordered_map<std::string, DeviceInfo> snapshot_;
};

} // namespace hidcore
