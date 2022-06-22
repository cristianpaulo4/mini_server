import 'dart:io';

class MiniServer {
  MiniServer._(){
    _init();
  }

  static late String _host;
  static late int _port;
  static final MiniServer _instance = MiniServer._();
  static MiniServer get instance => _instance;  

  factory MiniServer({required String host, required int port}) {
    _host = host;
    _port = port;   
    return _instance;
  }


  List<String>? _routerGet = [];
  List<Function> listFucoesGet = [];
  List<String>? _routerPost = [];
  List<Function> _listFucoesPost = [];
  List<String>? _routerPut = [];
  List<Function> _listFucoesPut = [];
  List<String>? _routerDelete = [];
  List<Function> _listFucoesDelete = [];

  get(String router, funcao(HttpRequest httpRequest)) {
    _routerGet!.add(router);
    listFucoesGet.add(funcao);
    _getRouter();
  }

  post(String router, funcao(HttpRequest httpRequest)) {
    _routerPost!.add(router);
    _listFucoesPost.add(funcao);
    _getRouter();
  }

  put(String router, funcao(HttpRequest httpRequest)) {
    _routerPut!.add(router);
    _listFucoesPut.add(funcao);
    _getRouter();
  }

  delete(String router, funcao(HttpRequest httpRequest)) {
    _routerDelete!.add(router);
    _listFucoesDelete.add(funcao);
    _getRouter();
  }

  Future<void> _init() async {
    var server = await HttpServer.bind(_host, _port);
    server.listen((req) async {
      switch (req.method) {
        case "GET":
          await _getRouter(router: req.uri.path, httpRequest: req);
          break;
        case "POST":
          await _postRouter(router: req.uri.path, httpRequest: req);
          break;
        case "DELETE":
          await _deleteRouter(router: req.uri.path, httpRequest: req);
          break;
        case "PUT":
          await _putRouter(router: req.uri.path, httpRequest: req);
          break;
      }

      await req.response.close();
    });
  }

  _getRouter({String? router, HttpRequest? httpRequest}) {
    if (_routerGet!.contains(router)) {
      int index = _routerGet!.indexOf(router!);
      return listFucoesGet.elementAt(index).call(httpRequest);
    }
  }

  _postRouter({String? router, HttpRequest? httpRequest}) {
    if (_routerPost!.contains(router)) {
      int index = _routerPost!.indexOf(router!);
      return _listFucoesPost.elementAt(index).call(httpRequest);
    }
  }

  _putRouter({String? router, HttpRequest? httpRequest}) {
    if (_routerPut!.contains(router)) {
      int index = _routerPut!.indexOf(router!);
      return _listFucoesPut.elementAt(index).call(httpRequest);
    }
  }

  _deleteRouter({String? router, HttpRequest? httpRequest}) {
    if (_routerDelete!.contains(router)) {
      int index = _routerDelete!.indexOf(router!);
      return _listFucoesDelete.elementAt(index).call(httpRequest);
    }
  }
}
