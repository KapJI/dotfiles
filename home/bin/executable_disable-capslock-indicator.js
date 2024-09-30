#!/usr/bin/env osascript -l JavaScript

const App = Application.currentApplication();
App.includeStandardAdditions = true;

const kCFPrefsFeatureFlagsDir = '/Library/Preferences/FeatureFlags/Domain';
const kCFPrefsFeatureEnabledKey = 'Enabled';

const kUIKitDomainPrefsTemporaryPath = '/tmp/UIKit.plist';
const kUIKitRedesignedTextCursorKey = 'redesigned_text_cursor';

function run(_) {
  const dict = $.NSMutableDictionary.new;

  const enabled = $.NSMutableDictionary.new;
  enabled.setValueForKey(false, kCFPrefsFeatureEnabledKey);

  dict.setValueForKey(enabled, kUIKitRedesignedTextCursorKey);

  const error = $();
  dict.writeToURLError(
    $.NSURL.fileURLWithPath(kUIKitDomainPrefsTemporaryPath),
    error,
  );

  if (typeof error.js != 'undefined') {
    return `🫤: ${error.localizedDescription}`;
  }

  return App.doShellScript(
    [
      `mkdir -p '${kCFPrefsFeatureFlagsDir}'`,
      `mv '${kUIKitDomainPrefsTemporaryPath}' '${kCFPrefsFeatureFlagsDir}'`,
    ].join(' && '),
    {
      administratorPrivileges: true,
    },
  ).length == 0 ? '😃' : '🫤';
}
