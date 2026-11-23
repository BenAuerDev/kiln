import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/services/finish_detection_service.dart';

void main() {
  const service = FinishDetectionService();

  test('maps the Veazy colour index like the official app', () {
    expect(service.fromVeazyColorIndex(2), DeviceFinish.blue);
    expect(service.fromVeazyColorIndex(3), DeviceFinish.pink);
    expect(service.fromVeazyColorIndex(4), DeviceFinish.ember);
  });

  test('anything else is black', () {
    expect(service.fromVeazyColorIndex(1), DeviceFinish.mono);
    expect(service.fromVeazyColorIndex(0), DeviceFinish.mono);
    expect(service.fromVeazyColorIndex(255), DeviceFinish.mono);
  });
}
