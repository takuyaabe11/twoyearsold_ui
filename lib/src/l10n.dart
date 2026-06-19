import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_controller.dart';

/// 軽量 i18n。全ゲーム共通の文言を `{言語: {キー: 文言}}` で持つ。
/// 言語追加 = [_data] と [supported] に1言語足すだけ(コード生成なし)。— DESIGN.md §10.2。
///
/// JA/EN 以外は機械生成の初版(後で人手レビュー)。ゲーム固有の文言は各ゲーム側で
/// 同じ要領の辞書を持つ(共通文言はここから取得)。
class L10n {
  final String code;
  const L10n(this.code);

  /// 対応言語(コード, 母語表記)。ここに足すと言語ピッカーに自動で並ぶ。
  static const supported = <({String code, String name})>[
    (code: 'en', name: 'English'),
    (code: 'ja', name: '日本語'),
    (code: 'zh', name: '简体中文'),
    (code: 'zh_Hant', name: '繁體中文'),
    (code: 'ko', name: '한국어'),
    (code: 'de', name: 'Deutsch'),
    (code: 'fr', name: 'Français'),
    (code: 'es', name: 'Español'),
    (code: 'it', name: 'Italiano'),
    (code: 'pt', name: 'Português'),
    (code: 'pt_BR', name: 'Português (BR)'),
    (code: 'ru', name: 'Русский'),
    (code: 'ar', name: 'العربية'),
    (code: 'hi', name: 'हिन्दी'),
    (code: 'id', name: 'Bahasa Indonesia'),
    (code: 'nl', name: 'Nederlands'),
    (code: 'pl', name: 'Polski'),
    (code: 'th', name: 'ไทย'),
    (code: 'tr', name: 'Türkçe'),
    (code: 'vi', name: 'Tiếng Việt'),
  ];

  /// RTL 言語(レイアウト方向の判定に使う)。
  static const rtl = {'ar'};

  static List<Locale> get locales => [
        for (final l in supported)
          if (l.code.contains('_'))
            Locale(l.code.split('_')[0], l.code.split('_')[1])
          else
            Locale(l.code),
      ];

  static bool isSupported(String code) => supported.any((l) => l.code == code);

  bool get isRtl => rtl.contains(code);

  /// 明示コード(null=端末言語)から L10n を解決。未対応は en にフォールバック。
  static L10n resolve(String? code) {
    if (code != null && isSupported(code)) return L10n(code);
    try {
      final dev = ui.PlatformDispatcher.instance.locale.languageCode;
      if (isSupported(dev)) return L10n(dev);
    } catch (_) {}
    return const L10n('en');
  }

  String _get(String key) => _data[code]?[key] ?? _data['en']![key] ?? key;

  String get settings => _get('settings');
  String get game => _get('game');
  String get theme => _get('theme');
  String get sound => _get('sound');
  String get animations => _get('animations');
  String get language => _get('language');
  String get languageSystem => _get('languageSystem');
  String get newGame => _get('newGame');
  String get howToPlay => _get('howToPlay');
  String get statistics => _get('statistics');
  String get continueLabel => _get('continueLabel');
  String get start => _get('start');
  String get home => _get('home');
  String get difficulty => _get('difficulty');
  String get easy => _get('easy');
  String get medium => _get('medium');
  String get hard => _get('hard');
  String get master => _get('master');
  String get opponent => _get('opponent');
  String get computer => _get('computer');
  String get passAndPlay => _get('passAndPlay');
  String get firstMove => _get('firstMove');
  String get yourTurn => _get('yourTurn');
  String get victory => _get('victory');
  String get defeat => _get('defeat');
  String get draw => _get('draw');

  static const Map<String, Map<String, String>> _data = {
    'en': {
      'settings': 'Settings', 'game': 'Game', 'theme': 'Theme', 'sound': 'Sound',
      'animations': 'Animations', 'language': 'Language', 'languageSystem': 'System',
      'newGame': 'New Game', 'howToPlay': 'How to Play', 'statistics': 'Statistics',
      'continueLabel': 'Continue', 'start': 'Start', 'home': 'Home',
      'difficulty': 'Difficulty', 'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard', 'master': 'Master',
      'opponent': 'Opponent', 'computer': 'Computer', 'passAndPlay': 'Pass & Play',
      'firstMove': 'First move', 'yourTurn': 'Your turn', 'victory': 'Victory',
      'defeat': 'Defeat', 'draw': 'Draw',
    },
    'ja': {
      'settings': '設定', 'game': 'ゲーム', 'theme': 'テーマ', 'sound': '効果音',
      'animations': 'アニメーション', 'language': '言語', 'languageSystem': '端末に従う',
      'newGame': '新しいゲーム', 'howToPlay': '遊び方', 'statistics': '統計',
      'continueLabel': 'つづきから', 'start': '開始', 'home': 'ホーム',
      'difficulty': '難易度', 'easy': 'やさしい', 'medium': 'ふつう', 'hard': 'むずかしい', 'master': '達人',
      'opponent': '対戦相手', 'computer': 'コンピュータ', 'passAndPlay': '交互プレイ',
      'firstMove': '先手', 'yourTurn': 'あなたの番', 'victory': '勝ち',
      'defeat': '負け', 'draw': '引き分け',
    },
    'zh': {
      'settings': '设置', 'game': '游戏', 'theme': '主题', 'sound': '音效',
      'animations': '动画', 'language': '语言', 'languageSystem': '系统',
      'newGame': '新游戏', 'howToPlay': '玩法', 'statistics': '统计',
      'continueLabel': '继续', 'start': '开始', 'home': '主页',
      'difficulty': '难度', 'easy': '简单', 'medium': '中等', 'hard': '困难', 'master': '大师',
      'opponent': '对手', 'computer': '电脑', 'passAndPlay': '双人对战',
      'firstMove': '先手', 'yourTurn': '轮到你', 'victory': '胜利',
      'defeat': '失败', 'draw': '平局',
    },
    'zh_Hant': {
      'settings': '設定', 'game': '遊戲', 'theme': '主題', 'sound': '音效',
      'animations': '動畫', 'language': '語言', 'languageSystem': '系統',
      'newGame': '新遊戲', 'howToPlay': '玩法', 'statistics': '統計',
      'continueLabel': '繼續', 'start': '開始', 'home': '主頁',
      'difficulty': '難度', 'easy': '簡單', 'medium': '中等', 'hard': '困難', 'master': '大師',
      'opponent': '對手', 'computer': '電腦', 'passAndPlay': '雙人對戰',
      'firstMove': '先手', 'yourTurn': '輪到你', 'victory': '勝利',
      'defeat': '失敗', 'draw': '平手',
    },
    'ko': {
      'settings': '설정', 'game': '게임', 'theme': '테마', 'sound': '소리',
      'animations': '애니메이션', 'language': '언어', 'languageSystem': '시스템',
      'newGame': '새 게임', 'howToPlay': '게임 방법', 'statistics': '통계',
      'continueLabel': '계속하기', 'start': '시작', 'home': '홈',
      'difficulty': '난이도', 'easy': '쉬움', 'medium': '보통', 'hard': '어려움', 'master': '마스터',
      'opponent': '상대', 'computer': '컴퓨터', 'passAndPlay': '둘이서',
      'firstMove': '선공', 'yourTurn': '당신 차례', 'victory': '승리',
      'defeat': '패배', 'draw': '무승부',
    },
    'de': {
      'settings': 'Einstellungen', 'game': 'Spiel', 'theme': 'Thema', 'sound': 'Ton',
      'animations': 'Animationen', 'language': 'Sprache', 'languageSystem': 'System',
      'newGame': 'Neues Spiel', 'howToPlay': 'Anleitung', 'statistics': 'Statistik',
      'continueLabel': 'Fortsetzen', 'start': 'Start', 'home': 'Startseite',
      'difficulty': 'Schwierigkeit', 'easy': 'Leicht', 'medium': 'Mittel', 'hard': 'Schwer', 'master': 'Meister',
      'opponent': 'Gegner', 'computer': 'Computer', 'passAndPlay': 'Zu zweit',
      'firstMove': 'Erster Zug', 'yourTurn': 'Du bist dran', 'victory': 'Sieg',
      'defeat': 'Niederlage', 'draw': 'Unentschieden',
    },
    'fr': {
      'settings': 'Paramètres', 'game': 'Jeu', 'theme': 'Thème', 'sound': 'Son',
      'animations': 'Animations', 'language': 'Langue', 'languageSystem': 'Système',
      'newGame': 'Nouvelle partie', 'howToPlay': 'Comment jouer', 'statistics': 'Statistiques',
      'continueLabel': 'Continuer', 'start': 'Commencer', 'home': 'Accueil',
      'difficulty': 'Difficulté', 'easy': 'Facile', 'medium': 'Moyen', 'hard': 'Difficile', 'master': 'Maître',
      'opponent': 'Adversaire', 'computer': 'Ordinateur', 'passAndPlay': 'À deux',
      'firstMove': 'Premier coup', 'yourTurn': 'À vous', 'victory': 'Victoire',
      'defeat': 'Défaite', 'draw': 'Match nul',
    },
    'es': {
      'settings': 'Ajustes', 'game': 'Juego', 'theme': 'Tema', 'sound': 'Sonido',
      'animations': 'Animaciones', 'language': 'Idioma', 'languageSystem': 'Sistema',
      'newGame': 'Nueva partida', 'howToPlay': 'Cómo jugar', 'statistics': 'Estadísticas',
      'continueLabel': 'Continuar', 'start': 'Empezar', 'home': 'Inicio',
      'difficulty': 'Dificultad', 'easy': 'Fácil', 'medium': 'Medio', 'hard': 'Difícil', 'master': 'Maestro',
      'opponent': 'Rival', 'computer': 'Ordenador', 'passAndPlay': 'Dos jugadores',
      'firstMove': 'Primer movimiento', 'yourTurn': 'Tu turno', 'victory': 'Victoria',
      'defeat': 'Derrota', 'draw': 'Empate',
    },
    'it': {
      'settings': 'Impostazioni', 'game': 'Gioco', 'theme': 'Tema', 'sound': 'Suono',
      'animations': 'Animazioni', 'language': 'Lingua', 'languageSystem': 'Sistema',
      'newGame': 'Nuova partita', 'howToPlay': 'Come si gioca', 'statistics': 'Statistiche',
      'continueLabel': 'Continua', 'start': 'Inizia', 'home': 'Home',
      'difficulty': 'Difficoltà', 'easy': 'Facile', 'medium': 'Medio', 'hard': 'Difficile', 'master': 'Maestro',
      'opponent': 'Avversario', 'computer': 'Computer', 'passAndPlay': 'In due',
      'firstMove': 'Prima mossa', 'yourTurn': 'Tocca a te', 'victory': 'Vittoria',
      'defeat': 'Sconfitta', 'draw': 'Pareggio',
    },
    'pt': {
      'settings': 'Definições', 'game': 'Jogo', 'theme': 'Tema', 'sound': 'Som',
      'animations': 'Animações', 'language': 'Idioma', 'languageSystem': 'Sistema',
      'newGame': 'Novo jogo', 'howToPlay': 'Como jogar', 'statistics': 'Estatísticas',
      'continueLabel': 'Continuar', 'start': 'Começar', 'home': 'Início',
      'difficulty': 'Dificuldade', 'easy': 'Fácil', 'medium': 'Médio', 'hard': 'Difícil', 'master': 'Mestre',
      'opponent': 'Adversário', 'computer': 'Computador', 'passAndPlay': 'A dois',
      'firstMove': 'Primeira jogada', 'yourTurn': 'Sua vez', 'victory': 'Vitória',
      'defeat': 'Derrota', 'draw': 'Empate',
    },
    'pt_BR': {
      'settings': 'Configurações', 'game': 'Jogo', 'theme': 'Tema', 'sound': 'Som',
      'animations': 'Animações', 'language': 'Idioma', 'languageSystem': 'Sistema',
      'newGame': 'Novo jogo', 'howToPlay': 'Como jogar', 'statistics': 'Estatísticas',
      'continueLabel': 'Continuar', 'start': 'Começar', 'home': 'Início',
      'difficulty': 'Dificuldade', 'easy': 'Fácil', 'medium': 'Médio', 'hard': 'Difícil', 'master': 'Mestre',
      'opponent': 'Adversário', 'computer': 'Computador', 'passAndPlay': 'Dois jogadores',
      'firstMove': 'Primeira jogada', 'yourTurn': 'Sua vez', 'victory': 'Vitória',
      'defeat': 'Derrota', 'draw': 'Empate',
    },
    'ru': {
      'settings': 'Настройки', 'game': 'Игра', 'theme': 'Тема', 'sound': 'Звук',
      'animations': 'Анимация', 'language': 'Язык', 'languageSystem': 'Система',
      'newGame': 'Новая игра', 'howToPlay': 'Как играть', 'statistics': 'Статистика',
      'continueLabel': 'Продолжить', 'start': 'Начать', 'home': 'Домой',
      'difficulty': 'Сложность', 'easy': 'Легко', 'medium': 'Средне', 'hard': 'Сложно', 'master': 'Мастер',
      'opponent': 'Соперник', 'computer': 'Компьютер', 'passAndPlay': 'На двоих',
      'firstMove': 'Первый ход', 'yourTurn': 'Ваш ход', 'victory': 'Победа',
      'defeat': 'Поражение', 'draw': 'Ничья',
    },
    'ar': {
      'settings': 'الإعدادات', 'game': 'اللعبة', 'theme': 'المظهر', 'sound': 'الصوت',
      'animations': 'الحركة', 'language': 'اللغة', 'languageSystem': 'النظام',
      'newGame': 'لعبة جديدة', 'howToPlay': 'كيفية اللعب', 'statistics': 'الإحصائيات',
      'continueLabel': 'متابعة', 'start': 'ابدأ', 'home': 'الرئيسية',
      'difficulty': 'الصعوبة', 'easy': 'سهل', 'medium': 'متوسط', 'hard': 'صعب', 'master': 'محترف',
      'opponent': 'الخصم', 'computer': 'الكمبيوتر', 'passAndPlay': 'لاعبان',
      'firstMove': 'النقلة الأولى', 'yourTurn': 'دورك', 'victory': 'فوز',
      'defeat': 'خسارة', 'draw': 'تعادل',
    },
    'hi': {
      'settings': 'सेटिंग्स', 'game': 'खेल', 'theme': 'थीम', 'sound': 'ध्वनि',
      'animations': 'एनिमेशन', 'language': 'भाषा', 'languageSystem': 'सिस्टम',
      'newGame': 'नया खेल', 'howToPlay': 'कैसे खेलें', 'statistics': 'आँकड़े',
      'continueLabel': 'जारी रखें', 'start': 'शुरू करें', 'home': 'होम',
      'difficulty': 'कठिनाई', 'easy': 'आसान', 'medium': 'मध्यम', 'hard': 'कठिन', 'master': 'मास्टर',
      'opponent': 'प्रतिद्वंद्वी', 'computer': 'कंप्यूटर', 'passAndPlay': 'दो खिलाड़ी',
      'firstMove': 'पहली चाल', 'yourTurn': 'आपकी बारी', 'victory': 'जीत',
      'defeat': 'हार', 'draw': 'बराबरी',
    },
    'id': {
      'settings': 'Pengaturan', 'game': 'Permainan', 'theme': 'Tema', 'sound': 'Suara',
      'animations': 'Animasi', 'language': 'Bahasa', 'languageSystem': 'Sistem',
      'newGame': 'Permainan Baru', 'howToPlay': 'Cara Bermain', 'statistics': 'Statistik',
      'continueLabel': 'Lanjutkan', 'start': 'Mulai', 'home': 'Beranda',
      'difficulty': 'Kesulitan', 'easy': 'Mudah', 'medium': 'Sedang', 'hard': 'Sulit', 'master': 'Master',
      'opponent': 'Lawan', 'computer': 'Komputer', 'passAndPlay': 'Dua Pemain',
      'firstMove': 'Langkah pertama', 'yourTurn': 'Giliranmu', 'victory': 'Menang',
      'defeat': 'Kalah', 'draw': 'Seri',
    },
    'nl': {
      'settings': 'Instellingen', 'game': 'Spel', 'theme': 'Thema', 'sound': 'Geluid',
      'animations': 'Animaties', 'language': 'Taal', 'languageSystem': 'Systeem',
      'newGame': 'Nieuw spel', 'howToPlay': 'Hoe te spelen', 'statistics': 'Statistieken',
      'continueLabel': 'Doorgaan', 'start': 'Start', 'home': 'Home',
      'difficulty': 'Moeilijkheid', 'easy': 'Makkelijk', 'medium': 'Gemiddeld', 'hard': 'Moeilijk', 'master': 'Meester',
      'opponent': 'Tegenstander', 'computer': 'Computer', 'passAndPlay': "Met z'n tweeën",
      'firstMove': 'Eerste zet', 'yourTurn': 'Jouw beurt', 'victory': 'Overwinning',
      'defeat': 'Verlies', 'draw': 'Gelijkspel',
    },
    'pl': {
      'settings': 'Ustawienia', 'game': 'Gra', 'theme': 'Motyw', 'sound': 'Dźwięk',
      'animations': 'Animacje', 'language': 'Język', 'languageSystem': 'System',
      'newGame': 'Nowa gra', 'howToPlay': 'Jak grać', 'statistics': 'Statystyki',
      'continueLabel': 'Kontynuuj', 'start': 'Start', 'home': 'Ekran główny',
      'difficulty': 'Trudność', 'easy': 'Łatwy', 'medium': 'Średni', 'hard': 'Trudny', 'master': 'Mistrz',
      'opponent': 'Przeciwnik', 'computer': 'Komputer', 'passAndPlay': 'Dwóch graczy',
      'firstMove': 'Pierwszy ruch', 'yourTurn': 'Twój ruch', 'victory': 'Zwycięstwo',
      'defeat': 'Porażka', 'draw': 'Remis',
    },
    'th': {
      'settings': 'การตั้งค่า', 'game': 'เกม', 'theme': 'ธีม', 'sound': 'เสียง',
      'animations': 'แอนิเมชัน', 'language': 'ภาษา', 'languageSystem': 'ระบบ',
      'newGame': 'เกมใหม่', 'howToPlay': 'วิธีเล่น', 'statistics': 'สถิติ',
      'continueLabel': 'เล่นต่อ', 'start': 'เริ่ม', 'home': 'หน้าหลัก',
      'difficulty': 'ความยาก', 'easy': 'ง่าย', 'medium': 'ปานกลาง', 'hard': 'ยาก', 'master': 'ผู้เชี่ยวชาญ',
      'opponent': 'คู่ต่อสู้', 'computer': 'คอมพิวเตอร์', 'passAndPlay': 'สองผู้เล่น',
      'firstMove': 'เดินก่อน', 'yourTurn': 'ตาของคุณ', 'victory': 'ชนะ',
      'defeat': 'แพ้', 'draw': 'เสมอ',
    },
    'tr': {
      'settings': 'Ayarlar', 'game': 'Oyun', 'theme': 'Tema', 'sound': 'Ses',
      'animations': 'Animasyonlar', 'language': 'Dil', 'languageSystem': 'Sistem',
      'newGame': 'Yeni Oyun', 'howToPlay': 'Nasıl Oynanır', 'statistics': 'İstatistikler',
      'continueLabel': 'Devam et', 'start': 'Başla', 'home': 'Ana sayfa',
      'difficulty': 'Zorluk', 'easy': 'Kolay', 'medium': 'Orta', 'hard': 'Zor', 'master': 'Usta',
      'opponent': 'Rakip', 'computer': 'Bilgisayar', 'passAndPlay': 'İki Kişilik',
      'firstMove': 'İlk hamle', 'yourTurn': 'Sıra sende', 'victory': 'Zafer',
      'defeat': 'Yenilgi', 'draw': 'Berabere',
    },
    'vi': {
      'settings': 'Cài đặt', 'game': 'Trò chơi', 'theme': 'Giao diện', 'sound': 'Âm thanh',
      'animations': 'Hiệu ứng', 'language': 'Ngôn ngữ', 'languageSystem': 'Hệ thống',
      'newGame': 'Trò chơi mới', 'howToPlay': 'Cách chơi', 'statistics': 'Thống kê',
      'continueLabel': 'Tiếp tục', 'start': 'Bắt đầu', 'home': 'Trang chủ',
      'difficulty': 'Độ khó', 'easy': 'Dễ', 'medium': 'Trung bình', 'hard': 'Khó', 'master': 'Bậc thầy',
      'opponent': 'Đối thủ', 'computer': 'Máy', 'passAndPlay': 'Hai người',
      'firstMove': 'Đi trước', 'yourTurn': 'Lượt của bạn', 'victory': 'Chiến thắng',
      'defeat': 'Thua', 'draw': 'Hòa',
    },
  };
}

/// 現在の言語に対応する L10n(設定の localeCode から解決)。
final l10nProvider = Provider<L10n>(
  (ref) => L10n.resolve(ref.watch(settingsProvider).localeCode),
);
