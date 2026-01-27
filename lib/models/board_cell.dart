import 'package:flutter/material.dart';

/// Representa uma célula do tabuleiro com sua geometria e propriedades
class BoardCell {
  const BoardCell({
    required this.id,
    required this.rect,
    required this.isVertical,
    required this.isRed,
    this.text,
  });

  /// Identificador único da célula (ex: 'A1L', 'CENTER')
  final String id;
  
  /// Retângulo que define a posição e tamanho da célula
  final Rect rect;
  
  /// Indica se a célula está orientada verticalmente
  final bool isVertical;
  
  /// Indica se a célula é vermelha (posição especial)
  final bool isRed;
  
  /// Texto customizado opcional para exibir na célula
  final String? text;
  
  /// Cria uma cópia da célula com opcionalmente novos valores
  BoardCell copyWith({
    String? id,
    Rect? rect,
    bool? isVertical,
    bool? isRed,
    String? text,
  }) {
    return BoardCell(
      id: id ?? this.id,
      rect: rect ?? this.rect,
      isVertical: isVertical ?? this.isVertical,
      isRed: isRed ?? this.isRed,
      text: text ?? this.text,
    );
  }
  
  /// Retorna se esta célula está no centro do tabuleiro
  bool get isCenter => id == 'CENTER';
  
  /// Retorna o braço do tabuleiro (A, B, C, D ou CENTER)
  String get arm {
    if (isCenter) return 'CENTER';
    return id.substring(0, 1);
  }
  
  /// Retorna o número da célula no braço
  int? get number {
    if (isCenter) return null;
    final match = RegExp(r'\d+').firstMatch(id);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
  
  /// Retorna a posição lateral (L, C, R)
  String? get side {
    if (isCenter) return null;
    final match = RegExp(r'[LCR]$').firstMatch(id);
    return match?.group(0);
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardCell &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() => 'BoardCell(id: $id, isRed: $isRed, text: $text)';
}
