import 'dart:convert';

import 'package:mobilemon/models/icingainstance.dart';
import 'package:mobilemon/models/instancesettings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AppSettings {
  String icingaUrl;
  String username;
  String password;

  InstanceSettings instances;

  static const String field_url = 'url';
  static const String field_username = 'username';
  static const String field_password = 'password';

  static const String field_instances = 'instances';

  Future loadData() async {
    if (this.icingaUrl == null && this.username == null && this.password == null) {
      await this.loadDataFromProvider();
    }
  }

  Future loadDataFromProvider() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.icingaUrl = prefs.getString(AppSettings.field_url);
    this.username= prefs.getString(AppSettings.field_username);
    this.password = prefs.getString(AppSettings.field_password);

    String jsonString = prefs.getString(AppSettings.field_instances);
    if (jsonString == null) {
      jsonString = "[]";
    }
    List<dynamic> json = jsonDecode(jsonString);
    this.instances = InstanceSettings.fromJson(json);
  }

  Future<String> getAuthData() async {
    this.loadData();

    return base64Encode(utf8.encode("${this.username}:${this.password}"));
  }

  Future<String> getIcingaUrl() async {
    this.loadData();

    String url = Uri.parse(this.icingaUrl).toString();
    if (!url.endsWith('/')) {
      url += '/';
    }

    return url;
  }

  Future saveData(String name, String url, String username, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(AppSettings.field_url, url);
    prefs.setString(AppSettings.field_username, username);
    prefs.setString(AppSettings.field_password, password);

    this.icingaUrl = url;
    this.username = username;
    this.password = password;


    InstanceSetting i = InstanceSetting(name, url, username, password);
    InstanceSetting alreadyInList = this.getByName(name);
    if (alreadyInList != null) {
      this.instances.instances.remove(alreadyInList);
    }
    this.instances.instances.add(i);

    this.save();
  }

  InstanceSetting getByName(String name) {
    InstanceSetting i;
    this.instances.instances.forEach((instance) {
      if (instance.name == name) {
        i = instance;
      }
    });

    return i;
  }

  Future save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(this.instances);
    prefs.setString(AppSettings.field_instances, jsonString);
    await this.loadDataFromProvider();
  }

  Future delete(InstanceSetting instance) async {
    this.instances.instances.remove(instance);
    await this.save();
  }

  Future checkData(String url, String username, String password) async {
    final headers = Map<String, String>();
    final auth = base64Encode(utf8.encode("$username:$password"));
    String icingaUrl = Uri.parse(url).toString();
    if (!icingaUrl.endsWith('/')) {
      icingaUrl += '/';
    }

    headers['Authorization'] = "Basic $auth";
    headers['Accept'] = "application/json";

    final response = await http.get('${icingaUrl}monitoring/list/hosts?limit=1&format=json', headers: headers);
    if (response.statusCode == 401) {
      throw Exception('Status Code 401 Unauthorized!');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to load, ${response.statusCode} ${response.request.method} ${response.request.url}');
    }
  }
}
