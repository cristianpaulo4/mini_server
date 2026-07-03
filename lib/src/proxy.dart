import 'node.dart';

abstract class MiniProxy {
  late MiniNode node;
  Type get interfaceType;
  void registerRoutes();
}
