import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class CursoModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String imagenUrl;
  final int leccionesTotal;
  final double progreso;
  final DateTime createdAt;

  CursoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagenUrl,
    this.leccionesTotal = 0,
    this.progreso = 0.0,
    required this.createdAt,
  });

  factory CursoModel.fromJson(Map<String, dynamic> json) {
    return CursoModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      imagenUrl: json['imagenUrl'] as String,
      leccionesTotal: json['leccionesTotal'] as int? ?? 0,
      progreso: (json['progreso'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'imagenUrl': imagenUrl,
      'leccionesTotal': leccionesTotal,
      'progreso': progreso,
      'createdAt': createdAt,
    };
  }
}
