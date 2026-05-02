import 'package:flutter/foundation.dart';
import 'dart:convert';

enum UserRole { campista, coordinador, admin }

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final UserRole role;
  final String? bosqueId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = UserRole.campista,
    this.bosqueId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.values[json['role'] as int? ?? 0],
      bosqueId: json['bosqueId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role.index,
      'bosqueId': bosqueId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
