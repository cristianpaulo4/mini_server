import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:mini_server/mini_server.dart';

class MiniRepositoryGenerator extends GeneratorForAnnotation<MiniRepository> {
  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          'A anotação @MiniRepository só pode ser usada em classes.',
          element: element);
    }

    final className = element.name;
    final basePath = annotation.read('path').stringValue;
    final proxyName = '${className}Proxy';

    final buffer = StringBuffer();
    buffer.writeln('// ignore_for_file: prefer_function_declarations_over_variables');
    buffer.writeln('class $proxyName implements $className, MiniProxy {');
    buffer.writeln('  @override');
    buffer.writeln('  late MiniNode node;');
    buffer.writeln('  final $className? localImpl;');
    buffer.writeln('  ');
    buffer.writeln('  @override');
    buffer.writeln('  Type get interfaceType => $className;');
    buffer.writeln('  ');
    buffer.writeln('  $proxyName({this.localImpl});');
    buffer.writeln('  ');
    buffer.writeln('  @override');
    buffer.writeln('  void registerRoutes() {');
    buffer.writeln('    if (localImpl != null) {');

    // Parse methods to register server routes
    for (var method in element.methods) {
      var httpAnnotation = _getHttpMethodAnnotation(method);
      if (httpAnnotation != null) {
        final path = httpAnnotation.read('path').stringValue;
        final verb = httpAnnotation.objectValue.type!.element!.name!.toUpperCase();
        
        buffer.writeln('    node.server.registerRoute(');
        buffer.writeln('      "$verb", ');
        buffer.writeln('      "$basePath$path", ');
        buffer.writeln('      (dynamic requestData) async {');
        
        if (method.formalParameters.isNotEmpty) {
           final paramType = method.formalParameters.first.type.getDisplayString(withNullability: false);
           buffer.writeln('        var param = $paramType.fromJson(requestData as Map<String, dynamic>);');
           buffer.writeln('        var result = await localImpl!.${method.name}(param);');
        } else {
           buffer.writeln('        var result = await localImpl!.${method.name}();');
        }
        
        if (verb == 'POST' || verb == 'PUT' || verb == 'DELETE') {
           buffer.writeln('        node.broadcastEvent("$basePath");');
        }
        
        buffer.writeln('        // O Servidor enviará o toJson() do resultado de volta para o cliente');
        buffer.writeln('        return result;'); 
        buffer.writeln('      }');
        buffer.writeln('    );');
      }
    }
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('  ');

    // Parse methods to implement the interface
    for (var method in element.methods) {
      var httpAnnotation = _getHttpMethodAnnotation(method);
      if (httpAnnotation != null) {
        final path = httpAnnotation.read('path').stringValue;
        final verb = httpAnnotation.objectValue.type!.element!.name!.toLowerCase();
        final verbUpper = verb.toUpperCase();
        final isMutating = verbUpper == 'POST' || verbUpper == 'PUT' || verbUpper == 'DELETE';
        
        final returnTypeString = method.returnType.getDisplayString(withNullability: false);
        // Extracts the inner type from Future<T> and Future<List<T>>
        var innerType = returnTypeString.replaceAll('Future<', '').replaceAll('>', '');
        var isList = innerType.startsWith('List<');
        if (isList) {
           innerType = innerType.replaceAll('List<', '');
        }
        
        buffer.write('  @override\n  $returnTypeString ${method.name}(');
        if (method.formalParameters.isNotEmpty) {
          buffer.write('${method.formalParameters.first.type.getDisplayString(withNullability: false)} ${method.formalParameters.first.name}');
        }
        buffer.writeln(') async {');
        
        buffer.writeln('    if (node.mode == NetworkMode.server) {');
        if (isMutating) {
           if (method.formalParameters.isNotEmpty) {
              buffer.writeln('      var result = await localImpl!.${method.name}(${method.formalParameters.first.name});');
           } else {
              buffer.writeln('      var result = await localImpl!.${method.name}();');
           }
           buffer.writeln('      node.broadcastEvent("$basePath");');
           buffer.writeln('      return result;');
        } else {
           if (method.formalParameters.isNotEmpty) {
              buffer.writeln('      return await localImpl!.${method.name}(${method.formalParameters.first.name});');
           } else {
              buffer.writeln('      return await localImpl!.${method.name}();');
           }
        }
        buffer.writeln('    } else {');
        buffer.writeln('      // Modo Cliente: Dispara via Rede');
        
        if (method.formalParameters.isNotEmpty) {
           if (innerType == 'void') {
              buffer.writeln('      await node.client.$verb(');
              buffer.writeln('        "$basePath$path", ');
              buffer.writeln('        data: ${method.formalParameters.first.name}.toJson(),');
              buffer.writeln('      );');
           } else {
              buffer.writeln('      var response = await node.client.$verb(');
              buffer.writeln('        "$basePath$path", ');
              buffer.writeln('        data: ${method.formalParameters.first.name}.toJson(),');
              buffer.writeln('      );');
           }
        } else {
           if (innerType == 'void') {
              buffer.writeln('      await node.client.$verb("$basePath$path");');
           } else {
              buffer.writeln('      var response = await node.client.$verb("$basePath$path");');
           }
        }
        
        if (innerType == 'void') {
           buffer.writeln('      return;');
        } else {
           buffer.writeln('      // Retorna objeto convertido');
           if (isList) {
              buffer.writeln('      if (response.data is List) {');
              buffer.writeln('         return (response.data as List).map((i) => $innerType.fromJson(i as Map<String, dynamic>)).toList() as dynamic;');
              buffer.writeln('      }');
              buffer.writeln('      return [];');
           } else {
              buffer.writeln('      return $innerType.fromJson(response.data as Map<String, dynamic>);');
           }
        }
        buffer.writeln('    }');
        buffer.writeln('  }');
      }
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  ConstantReader? _getHttpMethodAnnotation(MethodElement method) {
    for (var meta in method.metadata.annotations) {
      var value = meta.computeConstantValue();
      if (value != null && value.type != null) {
        var typeName = value.type!.element?.name;
        if (typeName == 'Get' || typeName == 'Post' || typeName == 'Put' || typeName == 'Delete') {
           return ConstantReader(value);
        }
      }
    }
    return null;
  }
}
