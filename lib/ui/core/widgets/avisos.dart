import 'package:flutter/material.dart';

void mostrarAviso(BuildContext context, String? aviso) {
  if (aviso == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(aviso)));
}
