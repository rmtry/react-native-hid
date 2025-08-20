#include "HIDMonitor.h"
#include <chrono>

namespace hidcore {

HIDMonitor::~HIDMonitor() {
  stop();
}

void HIDMonitor::start(DeviceCallback onAttached,
                       DeviceCallback onDetached,
                       int pollMs) {
  stop();
  onAttached_ = std::move(onAttached);
  onDetached_ = std::move(onDetached);
  running_ = true;
  // Seed initial snapshot (will emit "attached" for current devices)
  snapshot_.clear();
  thread_ = std::thread([this, pollMs]{ loop(pollMs); });
}

void HIDMonitor::stop() {
  if (!running_) return;
  running_ = false;
  if (thread_.joinable()) thread_.join();
  snapshot_.clear();
}

void HIDMonitor::loop(int pollMs) {
  using namespace std::chrono;
  // initial enumeration
  {
    auto now = listAllDevices();
    for (auto& d : now) {
      snapshot_[d.path] = d;
      if (onAttached_) onAttached_(d);
    }
  }

  while (running_) {
    auto next = listAllDevices();
    std::unordered_map<std::string, DeviceInfo> nextMap;
    nextMap.reserve(next.size());
    for (auto& d : next) nextMap.emplace(d.path, d);

    // Detect attached
    for (auto& kv : nextMap) {
      if (snapshot_.find(kv.first) == snapshot_.end()) {
        if (onAttached_) onAttached_(kv.second);
      }
    }
    // Detect detached
    for (auto& kv : snapshot_) {
      if (nextMap.find(kv.first) == nextMap.end()) {
        if (onDetached_) onDetached_(kv.second);
      }
    }
    snapshot_.swap(nextMap);

    for (int i=0; i<pollMs/50 && running_; ++i)
      std::this_thread::sleep_for(50ms);
  }
}

} // namespace hidcore
