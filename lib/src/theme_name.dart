/// テーマ id → 表示名(英語・エディトリアル)。
String themeName(String id) => switch (id) {
      'editorial_dark' => 'Editorial Dark',
      'editorial_light' => 'Editorial Light',
      'warm_cream' => 'Warm Cream',
      'sepia' => 'Sepia',
      'cool' => 'Cool',
      'dark_ink' => 'Dark Ink',
      _ => id,
    };
