import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mobilemon/controller/hostcontroller.dart';
import 'package:mobilemon/controller/instancecontroller.dart';
import 'package:mobilemon/controller/service_locator.dart';
import 'package:mobilemon/controller/servicecontroller.dart';
import 'package:mobilemon/models/host.dart';
import 'package:mobilemon/models/icingaobject.dart';
import 'package:mobilemon/models/service.dart';
import 'package:mobilemon/views/parts/list.dart';
import 'package:queries/collections.dart';

class IcingaDetailView extends StatefulWidget {
  const IcingaDetailView({
    Key key,
    @required this.iobject,
  }): super(key: key);

  final IcingaObject iobject;

  @override
  createState() => new IcingaDetailViewState();
}

class IcingaDetailViewState extends State<IcingaDetailView> {
  InstanceController controller;
  ServiceController serviceController = getIt.get<ServiceController>();
  HostController hostController = getIt.get<HostController>();

  Future<void> _refresh() async {
    print('refreshing...');
    List<Future> futures = [];
    futures.add(this.serviceController.fetch());
    futures.add(this.hostController.fetch());
    await Future.wait(futures);
    setState(() {});
  }

  List<Widget> getDetails(BuildContext context, IcingaObject iobject) {
    return [
      Card(
        child: Column(
          children: <Widget>[
            if (iobject is Service)
              icingaObjectHeaderListTile(iobject.host),
            icingaObjectHeaderListTile(iobject),
            Divider(
              height: 0.0,
            ),
            IcingaCheckListTile(iobject: iobject),
          ],
        ),
      )
    ];
  }

  Widget showInstance(IcingaObject iobject) {
    if (iobject is Service) {
      return null;
    }
    return SizedBox(
      width: 50,
      child: AutoSizeText(
        iobject.getInstanceName(),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(color: Colors.black.withOpacity(0.4)),
        maxFontSize: 12,
        textAlign: TextAlign.right,
      ),
    );
  }

  Container icingaObjectHeaderListTile(IcingaObject iobject) {
    return Container(
      decoration: new BoxDecoration(
        color: iobject.getBackgroundColor(),
        border: Border(
          left: BorderSide(width: 5, color: iobject.getBorderColor()),
        ),
      ),
      child: ListTile(
          onTap: () {
            this._handleClick(iobject);
          },
          title: Text(iobject.getDisplayName(),
              style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(iobject.getName()),
          trailing: this.showInstance(iobject),
          leading: Container(
            width: 50.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                AutoSizeText(
                  iobject.getStateText(),
                  maxLines: 1,
                ),
                Text(
                  "${iobject.getStateSince()}",
                  style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 10
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
      ),
    );
  }

  List<Widget> getServices(BuildContext context, Host host) {
    List<Widget> desc = List();
    List<Widget> l = List();
    Collection<Service> services = this.serviceController.getAllForHost(host);
    Collection<Service> servicesOk = this.serviceController.getWithStatus(host, "0");
    Collection<Service> servicesWarning = this.serviceController.getWithStatus(host, "1");
    Collection<Service> servicesCritical = this.serviceController.getWithStatus(host, "2");
    Collection<Service> servicesUnknown = this.serviceController.getWithStatus(host, "3");

    desc.add(
        ListTile(
          title: Text("${services.length} Services (${servicesOk.length} Ok, ${servicesWarning.length} Warning, ${servicesCritical.length} Critical, ${servicesUnknown.length} Unkown)"),
        )
    );
    desc.add(Divider(
      height: 0.0,
    ));

    for (var i = 0; i < services.length; i++) {
      l.add(ListRowNoHostname(iobject: services[i], clicked: _handleClick));
    }

    return [
      Card(
          child: Column(
            children: desc + l,
          )
      )
    ];
  }

  void _handleClick(IcingaObject iobject) {
    if (iobject != widget.iobject) {
      Navigator.pushNamed(context, '/detail', arguments: iobject);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: Scaffold(
          body: Container(
            child: ListView(
              children: <Widget>[
                ...getDetails(context, widget.iobject),
                if (widget.iobject is Host)
                  ...getServices(context, widget.iobject),
              ],
            ),
          )
      ),
    );
  }
}

class IcingaCheckListTile extends StatefulWidget {
  const IcingaCheckListTile({
    Key key,
    @required this.iobject,
  }): super(key: key);

  final IcingaObject iobject;

  @override
  createState() => new IcingaCheckListTileState();
}

class IcingaCheckListTileState extends State<IcingaCheckListTile> {
  Timer timer;

  String getNextCheck() {
    return "Next check ${widget.iobject.getDateFieldSince('next_update')}";
  }

  @override
  void deactivate() {
    timer.cancel();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (this.timer == null || !this.timer.isActive) {
      this.timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
        if (timer.isActive && this.mounted) {
          setState(() {

          });
        } else {
          this.timer.cancel();
        }
      });
    }

    return ListTile(
      title: Text(widget.iobject.getData(widget.iobject.outputField)),
      subtitle: (widget.iobject.getData('next_update') == "") ? Text(widget.iobject.getData('check_command')) : Text(this.getNextCheck()),
    );
  }
}
