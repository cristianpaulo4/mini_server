library mini_server_generator;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/mini_repository_generator.dart';

Builder miniRepositoryBuilder(BuilderOptions options) =>
    SharedPartBuilder([MiniRepositoryGenerator()], 'mini_repository');
