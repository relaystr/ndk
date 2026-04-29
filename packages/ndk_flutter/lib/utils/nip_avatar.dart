import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

class AvatarColor {
  final Color background;
  final Color text;

  const AvatarColor(this.background, this.text);
}

class NipAvatar {
  static const List<AvatarColor> palette = [
    AvatarColor(Color(0xFF7C3AED), Color(0xFFFFFFFF)), // 0
    AvatarColor(Color(0xFF6366F1), Color(0xFFFFFFFF)), // 1
    AvatarColor(Color(0xFF3B82F6), Color(0xFFFFFFFF)), // 2
    AvatarColor(Color(0xFF0EA5E9), Color(0xFFFFFFFF)), // 3
    AvatarColor(Color(0xFF06B6D4), Color(0xDE000000)), // 4
    AvatarColor(Color(0xFF14B8A6), Color(0xDE000000)), // 5
    AvatarColor(Color(0xFF10B981), Color(0xDE000000)), // 6
    AvatarColor(Color(0xFF22C55E), Color(0xDE000000)), // 7
    AvatarColor(Color(0xFF84CC16), Color(0xDE000000)), // 8
    AvatarColor(Color(0xFFEAB308), Color(0xDE000000)), // 9
    AvatarColor(Color(0xFFF59E0B), Color(0xDE000000)), // 10
    AvatarColor(Color(0xFFF97316), Color(0xDE000000)), // 11
    AvatarColor(Color(0xFFEF4444), Color(0xDE000000)), // 12
    AvatarColor(Color(0xFFEC4899), Color(0xDE000000)), // 13
    AvatarColor(Color(0xFFD946EF), Color(0xDE000000)), // 14
    AvatarColor(Color(0xFFA855F7), Color(0xDE000000)), // 15
    AvatarColor(Color(0xFF8B5CF6), Color(0xFFFFFFFF)), // 16
    AvatarColor(Color(0xFF6366F1), Color(0xFFFFFFFF)), // 17
    AvatarColor(Color(0xFF06B6D4), Color(0xDE000000)), // 18
    AvatarColor(Color(0xFF14B8A6), Color(0xDE000000)), // 19
  ];

  static AvatarColor getColor(String pubkey) {
    if (pubkey.length < 64) {
      return palette[0];
    }
    final substring = pubkey.substring(29, 35);
    final parsedValue = int.tryParse(substring, radix: 16) ?? 0;
    final index = parsedValue % palette.length;
    return palette[index];
  }

  static String getInitial(String pubkey, Metadata? metadata) {
    final displayName = metadata?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim()[0].toUpperCase();
    }

    final name = metadata?.name;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim()[0].toUpperCase();
    }

    final nip05 = metadata?.nip05;
    if (nip05 != null && nip05.trim().isNotEmpty) {
      final cleanNip05 = nip05.trim();
      if (cleanNip05.startsWith('_@') && cleanNip05.length > 2) {
        return cleanNip05[2].toUpperCase();
      }
      if (cleanNip05.startsWith('@') && cleanNip05.length > 1) {
        return cleanNip05[1].toUpperCase();
      }
      return cleanNip05[0].toUpperCase();
    }

    if (pubkey.length >= 64) {
      final char = pubkey[28].toLowerCase();
      final hexValue = int.tryParse(char, radix: 16);
      if (hexValue != null && hexValue >= 0 && hexValue <= 15) {
        return String.fromCharCode('A'.codeUnitAt(0) + hexValue);
      }
    }

    return '';
  }
}
