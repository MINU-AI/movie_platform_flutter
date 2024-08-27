import 'package:flutter_test/flutter_test.dart';
import 'package:player/player.dart';
import 'package:player/player_platform_interface.dart';
import 'package:player/player_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPlayerPlatform
    with MockPlatformInterfaceMixin
    implements PlayerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PlayerPlatform initialPlatform = PlayerPlatform.instance;

  test('$MethodChannelPlayer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPlayer>());
  });


}
