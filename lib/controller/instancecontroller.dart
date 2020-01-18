import 'package:mobilemon/controller/appsettings.dart';
import 'package:mobilemon/models/icingainstance.dart';
import 'package:mobilemon/models/instancesettings.dart';

class InstanceController {
  List<IcingaInstance> instances = [];

  void addInstance(IcingaInstance instance) {
    this.instances.add(instance);
  }

  void reset() {
    this.instances.clear();
  }

  InstanceController.fromSettings(AppSettings settings) {
    this.loadFromInstances(settings.instances.instances);
  }

  void loadFromInstances(List<InstanceSetting> settings) {
    this.reset();

    settings.forEach((settings) {
      this.addInstance(IcingaInstance(
        settings.name,
        settings.url,
        settings.username,
        settings.password,
      ));
    });
  }
}