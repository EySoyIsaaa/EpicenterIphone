import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const root = process.cwd();
const pbxprojPath = join(root, 'ios/App/App.xcodeproj/project.pbxproj');
const infoPlistPath = join(root, 'ios/App/App/Info.plist');
const wrapperPath = join(root, 'client/src/native/iosNativeAudio.ts');
const capConfigPath = join(root, 'ios/App/App/capacitor.config.json');
const podfilePath = join(root, 'ios/App/Podfile');

const pluginPackageSources = [
  'ios/Plugins/EpicenterNativePlugin.swift',
  'ios/NativeAudio/AutoEQStore.swift',
  'ios/NativeAudio/EpicenterAutoEQAnalyzer.swift',
  'ios/NativeAudio/NativeAudioModels.swift',
  'ios/NativeAudio/NativeLibraryDatabase.swift',
  'ios/NativeAudio/NativeTrackImporter.swift',
  'ios/NativeAudio/NativeTrackRepository.swift',
  'ios/NativeAudio/NativeAudioSessionManager.swift',
  'ios/NativeAudio/NativeAudioEngine.swift',
  'ios/NativeAudio/NativeQueueManager.swift',
  'ios/NativeAudio/NativePlaybackController.swift',
  'ios/NativeAudio/NowPlayingManager.swift',
  'ios/NativeAudio/RemoteCommandManager.swift',
  'ios/CarPlay/CarPlaySceneDelegate.swift',
  'ios/DSP/AudioLimiter.swift',
  'ios/DSP/EpicenterDSPBridge.h',
  'ios/DSP/EpicenterDSPBridge.mm',
  'ios/DSP/EpicenterDSPCore.cpp',
  'ios/DSP/EpicenterDSPCore.hpp',
  'ios/DSP/EpicenterHeadphonesCore.hpp',
  'ios/DSP/EQ31BandProcessor.swift',
  'ios/DSP/ReverbProcessor.swift',
];

const requiredPluginMethods = [
  'importTracks',
  'getLibraryPage',
  'getTrack',
  'deleteTrack',
  'setQueue',
  'play',
  'pause',
  'stop',
  'seek',
  'next',
  'previous',
  'getPlaybackState',
];

const fail = (message) => {
  console.error(`❌ ${message}`);
  process.exitCode = 1;
};

for (const path of [pbxprojPath, infoPlistPath, wrapperPath, capConfigPath, podfilePath]) {
  if (!existsSync(path)) {
    fail(`Missing required file: ${path}`);
  }
}

if (process.exitCode) process.exit(process.exitCode);

const pbxproj = readFileSync(pbxprojPath, 'utf8');
const infoPlist = readFileSync(infoPlistPath, 'utf8');
const wrapper = readFileSync(wrapperPath, 'utf8');
const capConfig = readFileSync(capConfigPath, 'utf8');
const podfile = readFileSync(podfilePath, 'utf8');
const plugin = readFileSync(join(root, 'plugins/epicenter-native-ios/ios/Plugins/EpicenterNativePlugin.swift'), 'utf8');

for (const source of pluginPackageSources) {
  if (!existsSync(join(root, 'plugins/epicenter-native-ios', source))) {
    fail(`Missing local Capacitor plugin source: plugins/epicenter-native-ios/${source}`);
  }
}

if (!wrapper.includes("registerPlugin<EpicenterNativePlugin>('EpicenterNative')")) {
  fail('TypeScript wrapper is not registered as EpicenterNative');
}

if (!plugin.includes('@objc(EpicenterNativePlugin)')) {
  fail('EpicenterNativePlugin.swift is missing @objc(EpicenterNativePlugin)');
}

if (!plugin.includes('public class EpicenterNativePlugin: CAPPlugin')) {
  fail('EpicenterNativePlugin.swift is not a CAPPlugin class');
}

if (!plugin.includes('public let jsName = "EpicenterNative"')) {
  fail('EpicenterNativePlugin.swift jsName is not EpicenterNative');
}

for (const method of requiredPluginMethods) {
  if (!plugin.includes(`CAPPluginMethod(name: "${method}"`) || !plugin.includes(`func ${method}(`)) {
    fail(`EpicenterNativePlugin.swift does not register/implement ${method}`);
  }
}

if (!capConfig.includes('"packageClassList"') || !capConfig.includes('"EpicenterNativePlugin"')) {
  fail('Capacitor iOS config does not auto-register EpicenterNativePlugin');
}

if (!podfile.includes("pod 'EpicenterNativeIos'")) {
  fail('Podfile does not include the safe local EpicenterNativeIos pod');
}

if (pbxproj.includes('EpicenterNativePlugin.swift in Sources') || pbxproj.includes('NativeAudioModels.swift in Sources')) {
  fail('project.pbxproj contains manual native plugin source references; use the local pod/manual Xcode instructions instead');
}

if (pbxproj.includes('runOnlyForDeploymentPostprocessing = 0; }};')) {
  fail('project.pbxproj contains the known corrupt Nanaimo }}; pattern');
}

if (!infoPlist.includes('<key>UIBackgroundModes</key>') || !infoPlist.includes('<string>audio</string>')) {
  fail('Info.plist is missing UIBackgroundModes audio');
}

if (!process.exitCode) {
  console.log('✅ EpicenterNative local Capacitor plugin is present.');
  console.log('✅ Capacitor iOS config auto-registers EpicenterNativePlugin.');
  console.log('✅ Podfile installs EpicenterNativeIos without manual project.pbxproj edits.');
  console.log('✅ Info.plist contains UIBackgroundModes audio.');
}
