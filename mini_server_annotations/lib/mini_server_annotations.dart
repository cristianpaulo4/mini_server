library mini_server_annotations;

/// Marca uma classe abstrata como um Repositório que deverá ter um Proxy gerado.
class MiniRepository {
  final String path;
  const MiniRepository(this.path);
}

/// Anotação base para os métodos HTTP
abstract class HttpMethod {
  final String path;
  const HttpMethod(this.path);
}

/// Marca um método para realizar uma chamada GET na rede
class Get extends HttpMethod {
  const Get(super.path);
}

/// Marca um método para realizar uma chamada POST na rede
class Post extends HttpMethod {
  const Post(super.path);
}

/// Marca um método para realizar uma chamada PUT na rede
class Put extends HttpMethod {
  const Put(super.path);
}

/// Marca um método para realizar uma chamada DELETE na rede
class Delete extends HttpMethod {
  const Delete(super.path);
}
