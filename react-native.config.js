// react-native.config.js
module.exports = {
  dependency: {
    platforms: {
      windows: {
        sourceDir: 'windows',
        solutionFile: 'ReactNativeHid.sln',
        projects: [
          {
            projectFile: 'ReactNativeHid/ReactNativeHid.vcxproj',
            directDependency: true,
          },
        ],
        // Helps RNW generate includes and registrations
        cppHeaders: ['ReactNativeHid/ReactPackageProvider.h'],
        cppPackageProviders: ['ReactNativeHid::ReactPackageProvider'],
      },
      // macOS autolinking goes through CocoaPods, no special entry needed here
    },
  },
};
