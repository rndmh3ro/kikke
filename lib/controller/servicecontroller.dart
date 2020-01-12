import 'package:mobilemon/controller/icingacontroller.dart';
import 'package:mobilemon/controller/instancecontroller.dart';
import 'package:mobilemon/models/host.dart';
import 'package:mobilemon/models/service.dart';

import 'package:queries/collections.dart';

class ServiceController implements IcingaObjectController {
  InstanceController controller;

  ServiceController({this.controller});

  Future fetch() async {
    List<Future> futures = [];
    this.controller.instances.forEach((instance) {
      futures.add(instance.fetchServices());
    });

    await Future.wait(futures);
  }
  
  Future<void> checkUpdate() async {
    List<Future> futures = [];
    this.controller.instances.forEach((instance) {
      futures.add(instance.checkUpdateServices());
    });

    await Future.wait(futures);
  }

  Future<Collection<Service>> getServicesForHost(Host host) async {
    await this.checkUpdate();

    List<Service> l = new List();
    this.controller.instances.forEach((instance) {
      instance.services.forEach((name, service) => l.add(service));
    });

    var m = new Collection<Service>(l);
    return m.where((service) => service.host == host);
  }

  Future<Collection<Service>> getAll() async {
    await this.checkUpdate();

    List<Service> l = new List();
    this.controller.instances.forEach((instance) {
      instance.services.forEach((name, service) => l.add(service));
    });

    var m = new Collection<Service>(l);
    return m
        .orderBy((service) => int.parse(service.getData('state')) * -1)
        .thenBy((service) => service.getData('last_state_change'))
        .toCollection();
  }

  Future<Collection<Service>> getAllWithProblems() async {
    await this.checkUpdate();

    List<Service> l = new List();
    this.controller.instances.forEach((instance) {
      instance.services.forEach((name, service) => l.add(service));
    });

    var m = new Collection<Service>(l);
    return m
        .where((service) => service.getData('state') != "0")
        .orderBy((service) => int.parse(service.getData('state')) * -1)
        .thenBy((service) => service.getData('last_state_change'))
        .toCollection();
  }

  Collection<Service> getAllForHost(Host host) {
    List<Service> l = new List();
    this.controller.instances.forEach((instance) {
      instance.services.forEach(
          (name, service) => service.host == host ? l.add(service) : false);
    });

    var m = new Collection<Service>(l);
    return m
        .orderBy((service) => int.parse(service.getData('state')) * -1)
        .thenBy((service) => service.getName().toLowerCase())
        .thenBy((service) => service.getData('last_state_change'))
        .toCollection();
  }

  Collection<Service> getWithStatus(Host host, String state) {
    var m = this.getAllForHost(host);

    return m
        .where((service) => service.getData('state') == state)
        .toCollection();
  }
}
