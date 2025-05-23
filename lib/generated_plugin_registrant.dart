// Flutter web plugin registrant file.
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:geolocator_web/geolocator_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:mobile_scanner/mobile_scanner_web.dart';

void registerPlugins(Registrar registrar) {
  GeolocatorPlugin.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  MobileScannerWebPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
} 