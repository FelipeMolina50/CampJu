import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeccionModel {
  final String id;
  final String cursoId;
  final String titulo;
  final String contenido;
  final bool completada;
  final int numero;

  LeccionModel({
    required this.id,
    required this.cursoId,
    required this.titulo,
    required this.contenido,
    this.completada = false,
    required this.numero,
  });

  factory LeccionModel.fromJson(Map<String, dynamic> json) {
    return LeccionModel(
      id: json['id'] as String,
      cursoId: json['cursoId'] as String,
      titulo: json['titulo'] as String,
      contenido: json['contenido'] as String,
      completada: json['completada'] as bool? ?? false,
      numero: json['numero'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cursoId': cursoId,
      'titulo': titulo,
      'contenido': contenido,
      'completada': completada,
      'numero': numero,
    };
  }
}
