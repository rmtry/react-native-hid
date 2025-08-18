#include "NativeHidModule.h"

namespace facebook::react {

NativeHidModule::NativeHidModule(std::shared_ptr<CallInvoker> jsInvoker)
    : NativeHidModuleCxxSpec(std::move(jsInvoker)) {}

std::string NativeHidModule::reverseString(jsi::Runtime& rt, std::string input) {
  return std::string(input.rbegin(), input.rend());
}

} // namespace facebook::react