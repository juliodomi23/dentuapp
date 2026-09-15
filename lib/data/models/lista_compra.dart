class CategoriaCompra {
  const CategoriaCompra({required this.nombre, required this.items});

  final String nombre;
  final List<String> items;

  factory CategoriaCompra.fromJson(Map<String, dynamic> json) => CategoriaCompra(
    nombre: json['nombre'] as String? ?? 'Otros',
    items: (json['items'] as List<dynamic>? ?? []).map((i) => i.toString()).toList(),
  );
}

class ListaCompra {
  const ListaCompra({required this.categorias});

  final List<CategoriaCompra> categorias;

  factory ListaCompra.fromJson(Map<String, dynamic> json) => ListaCompra(
    categorias: (json['categorias'] as List<dynamic>? ?? [])
        .map((c) => CategoriaCompra.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
