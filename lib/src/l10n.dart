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
    (code: 'uk', name: 'Українська'),
    (code: 'fa', name: 'فارسی'),
    (code: 'sv', name: 'Svenska'),
    (code: 'da', name: 'Dansk'),
    (code: 'nb', name: 'Norsk bokmål'),
    (code: 'fi', name: 'Suomi'),
    (code: 'cs', name: 'Čeština'),
    (code: 'el', name: 'Ελληνικά'),
    (code: 'hu', name: 'Magyar'),
    (code: 'ro', name: 'Română'),
    (code: 'ms', name: 'Bahasa Melayu'),
    (code: 'fil', name: 'Filipino'),
    (code: 'bn', name: 'বাংলা'),
    (code: 'he', name: 'עברית'),
    (code: 'ur', name: 'اردو'),
    (code: 'ta', name: 'தமிழ்'),
    (code: 'te', name: 'తెలుగు'),
  ];

  /// RTL 言語(レイアウト方向の判定に使う)。
  static const rtl = {'ar', 'fa', 'he', 'ur'};

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
  String get achievements => _get('achievements');
  String get dailyChallenge => _get('dailyChallenge');

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
      'achievements': 'Achievements', 'dailyChallenge': 'Daily Challenge',
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
      'achievements': '実績', 'dailyChallenge': 'デイリーチャレンジ',
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
      'achievements': '成就', 'dailyChallenge': '每日挑战',
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
      'achievements': '成就', 'dailyChallenge': '每日挑戰',
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
      'achievements': '업적', 'dailyChallenge': '일일 챌린지',
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
      'achievements': 'Erfolge', 'dailyChallenge': 'Tagesrätsel',
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
      'achievements': 'Succès', 'dailyChallenge': 'Défi du jour',
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
      'achievements': 'Logros', 'dailyChallenge': 'Reto diario',
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
      'achievements': 'Obiettivi', 'dailyChallenge': 'Sfida giornaliera',
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
      'achievements': 'Conquistas', 'dailyChallenge': 'Desafio Diário',
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
      'achievements': 'Conquistas', 'dailyChallenge': 'Desafio diário',
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
      'achievements': 'Достижения', 'dailyChallenge': 'Задача дня',
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
      'achievements': 'الإنجازات', 'dailyChallenge': 'التحدي اليومي',
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
      'achievements': 'उपलब्धियाँ', 'dailyChallenge': 'दैनिक चुनौती',
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
      'achievements': 'Pencapaian', 'dailyChallenge': 'Tantangan Harian',
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
      'achievements': 'Prestaties', 'dailyChallenge': 'Dagelijkse uitdaging',
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
      'achievements': 'Osiągnięcia', 'dailyChallenge': 'Wyzwanie dnia',
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
      'achievements': 'ความสำเร็จ', 'dailyChallenge': 'ปริศนาประจำวัน',
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
      'achievements': 'Başarımlar', 'dailyChallenge': 'Günlük Görev',
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
      'achievements': 'Thành tích', 'dailyChallenge': 'Thử thách hằng ngày',
    },
    'uk': {
      'settings': 'Налаштування', 'game': 'Гра', 'theme': 'Тема', 'sound': 'Звук',
      'animations': 'Анімація', 'language': 'Мова', 'languageSystem': 'Системна',
      'newGame': 'Нова гра', 'howToPlay': 'Як грати', 'statistics': 'Статистика',
      'continueLabel': 'Продовжити', 'start': 'Почати', 'home': 'Головна',
      'difficulty': 'Складність', 'easy': 'Легко', 'medium': 'Середньо', 'hard': 'Важко', 'master': 'Майстер',
      'opponent': 'Суперник', 'computer': "Комп'ютер", 'passAndPlay': 'На двох',
      'firstMove': 'Перший хід', 'yourTurn': 'Ваш хід', 'victory': 'Перемога',
      'defeat': 'Поразка', 'draw': 'Нічия',
      'achievements': 'Досягнення', 'dailyChallenge': 'Щоденне завдання',
    },
    'fa': {
      'settings': 'تنظیمات', 'game': 'بازی', 'theme': 'پوسته', 'sound': 'صدا',
      'animations': 'انیمیشن', 'language': 'زبان', 'languageSystem': 'سیستم',
      'newGame': 'بازی جدید', 'howToPlay': 'نحوه بازی', 'statistics': 'آمار',
      'continueLabel': 'ادامه', 'start': 'شروع', 'home': 'خانه',
      'difficulty': 'سختی', 'easy': 'آسان', 'medium': 'متوسط', 'hard': 'سخت', 'master': 'استاد',
      'opponent': 'حریف', 'computer': 'رایانه', 'passAndPlay': 'دو نفره',
      'firstMove': 'حرکت اول', 'yourTurn': 'نوبت شما', 'victory': 'پیروزی',
      'defeat': 'شکست', 'draw': 'مساوی',
      'achievements': 'دستاوردها', 'dailyChallenge': 'چالش روزانه',
    },
    'sv': {
      'settings': 'Inställningar', 'game': 'Spel', 'theme': 'Tema', 'sound': 'Ljud',
      'animations': 'Animationer', 'language': 'Språk', 'languageSystem': 'System',
      'newGame': 'Nytt spel', 'howToPlay': 'Så spelar du', 'statistics': 'Statistik',
      'continueLabel': 'Fortsätt', 'start': 'Starta', 'home': 'Hem',
      'difficulty': 'Svårighet', 'easy': 'Lätt', 'medium': 'Medel', 'hard': 'Svår', 'master': 'Mästare',
      'opponent': 'Motståndare', 'computer': 'Dator', 'passAndPlay': 'Två spelare',
      'firstMove': 'Första draget', 'yourTurn': 'Din tur', 'victory': 'Seger',
      'defeat': 'Förlust', 'draw': 'Oavgjort',
      'achievements': 'Prestationer', 'dailyChallenge': 'Dagens utmaning',
    },
    'da': {
      'settings': 'Indstillinger', 'game': 'Spil', 'theme': 'Tema', 'sound': 'Lyd',
      'animations': 'Animationer', 'language': 'Sprog', 'languageSystem': 'System',
      'newGame': 'Nyt spil', 'howToPlay': 'Sådan spiller du', 'statistics': 'Statistik',
      'continueLabel': 'Fortsæt', 'start': 'Start', 'home': 'Hjem',
      'difficulty': 'Sværhed', 'easy': 'Let', 'medium': 'Mellem', 'hard': 'Svær', 'master': 'Mester',
      'opponent': 'Modstander', 'computer': 'Computer', 'passAndPlay': 'To spillere',
      'firstMove': 'Første træk', 'yourTurn': 'Din tur', 'victory': 'Sejr',
      'defeat': 'Nederlag', 'draw': 'Uafgjort',
      'achievements': 'Præstationer', 'dailyChallenge': 'Dagens udfordring',
    },
    'nb': {
      'settings': 'Innstillinger', 'game': 'Spill', 'theme': 'Tema', 'sound': 'Lyd',
      'animations': 'Animasjoner', 'language': 'Språk', 'languageSystem': 'System',
      'newGame': 'Nytt spill', 'howToPlay': 'Slik spiller du', 'statistics': 'Statistikk',
      'continueLabel': 'Fortsett', 'start': 'Start', 'home': 'Hjem',
      'difficulty': 'Vanskelighet', 'easy': 'Lett', 'medium': 'Middels', 'hard': 'Vanskelig', 'master': 'Mester',
      'opponent': 'Motstander', 'computer': 'Datamaskin', 'passAndPlay': 'To spillere',
      'firstMove': 'Første trekk', 'yourTurn': 'Din tur', 'victory': 'Seier',
      'defeat': 'Tap', 'draw': 'Uavgjort',
      'achievements': 'Prestasjoner', 'dailyChallenge': 'Dagens utfordring',
    },
    'fi': {
      'settings': 'Asetukset', 'game': 'Peli', 'theme': 'Teema', 'sound': 'Ääni',
      'animations': 'Animaatiot', 'language': 'Kieli', 'languageSystem': 'Järjestelmä',
      'newGame': 'Uusi peli', 'howToPlay': 'Peliohjeet', 'statistics': 'Tilastot',
      'continueLabel': 'Jatka', 'start': 'Aloita', 'home': 'Etusivu',
      'difficulty': 'Vaikeus', 'easy': 'Helppo', 'medium': 'Keskitaso', 'hard': 'Vaikea', 'master': 'Mestari',
      'opponent': 'Vastustaja', 'computer': 'Tietokone', 'passAndPlay': 'Kaksinpeli',
      'firstMove': 'Ensimmäinen siirto', 'yourTurn': 'Sinun vuorosi', 'victory': 'Voitto',
      'defeat': 'Tappio', 'draw': 'Tasapeli',
      'achievements': 'Saavutukset', 'dailyChallenge': 'Päivän haaste',
    },
    'cs': {
      'settings': 'Nastavení', 'game': 'Hra', 'theme': 'Motiv', 'sound': 'Zvuk',
      'animations': 'Animace', 'language': 'Jazyk', 'languageSystem': 'Systém',
      'newGame': 'Nová hra', 'howToPlay': 'Jak hrát', 'statistics': 'Statistiky',
      'continueLabel': 'Pokračovat', 'start': 'Start', 'home': 'Domů',
      'difficulty': 'Obtížnost', 'easy': 'Lehká', 'medium': 'Střední', 'hard': 'Těžká', 'master': 'Mistr',
      'opponent': 'Soupeř', 'computer': 'Počítač', 'passAndPlay': 'Dva hráči',
      'firstMove': 'První tah', 'yourTurn': 'Jste na tahu', 'victory': 'Výhra',
      'defeat': 'Prohra', 'draw': 'Remíza',
      'achievements': 'Úspěchy', 'dailyChallenge': 'Denní výzva',
    },
    'el': {
      'settings': 'Ρυθμίσεις', 'game': 'Παιχνίδι', 'theme': 'Θέμα', 'sound': 'Ήχος',
      'animations': 'Κινούμενα σχέδια', 'language': 'Γλώσσα', 'languageSystem': 'Σύστημα',
      'newGame': 'Νέο παιχνίδι', 'howToPlay': 'Πώς να παίξετε', 'statistics': 'Στατιστικά',
      'continueLabel': 'Συνέχεια', 'start': 'Έναρξη', 'home': 'Αρχική',
      'difficulty': 'Δυσκολία', 'easy': 'Εύκολο', 'medium': 'Μέτριο', 'hard': 'Δύσκολο', 'master': 'Δεξιοτέχνης',
      'opponent': 'Αντίπαλος', 'computer': 'Υπολογιστής', 'passAndPlay': 'Δύο παίκτες',
      'firstMove': 'Πρώτη κίνηση', 'yourTurn': 'Η σειρά σου', 'victory': 'Νίκη',
      'defeat': 'Ήττα', 'draw': 'Ισοπαλία',
      'achievements': 'Επιτεύγματα', 'dailyChallenge': 'Καθημερινή πρόκληση',
    },
    'hu': {
      'settings': 'Beállítások', 'game': 'Játék', 'theme': 'Téma', 'sound': 'Hang',
      'animations': 'Animációk', 'language': 'Nyelv', 'languageSystem': 'Rendszer',
      'newGame': 'Új játék', 'howToPlay': 'Hogyan játssz', 'statistics': 'Statisztika',
      'continueLabel': 'Folytatás', 'start': 'Indítás', 'home': 'Kezdőlap',
      'difficulty': 'Nehézség', 'easy': 'Könnyű', 'medium': 'Közepes', 'hard': 'Nehéz', 'master': 'Mester',
      'opponent': 'Ellenfél', 'computer': 'Számítógép', 'passAndPlay': 'Két játékos',
      'firstMove': 'Első lépés', 'yourTurn': 'Te jössz', 'victory': 'Győzelem',
      'defeat': 'Vereség', 'draw': 'Döntetlen',
      'achievements': 'Eredmények', 'dailyChallenge': 'Napi kihívás',
    },
    'ro': {
      'settings': 'Setări', 'game': 'Joc', 'theme': 'Temă', 'sound': 'Sunet',
      'animations': 'Animații', 'language': 'Limbă', 'languageSystem': 'Sistem',
      'newGame': 'Joc nou', 'howToPlay': 'Cum se joacă', 'statistics': 'Statistici',
      'continueLabel': 'Continuă', 'start': 'Start', 'home': 'Acasă',
      'difficulty': 'Dificultate', 'easy': 'Ușor', 'medium': 'Mediu', 'hard': 'Greu', 'master': 'Maestru',
      'opponent': 'Adversar', 'computer': 'Calculator', 'passAndPlay': 'Doi jucători',
      'firstMove': 'Prima mutare', 'yourTurn': 'Rândul tău', 'victory': 'Victorie',
      'defeat': 'Înfrângere', 'draw': 'Remiză',
      'achievements': 'Realizări', 'dailyChallenge': 'Provocarea zilei',
    },
    'ms': {
      'settings': 'Tetapan', 'game': 'Permainan', 'theme': 'Tema', 'sound': 'Bunyi',
      'animations': 'Animasi', 'language': 'Bahasa', 'languageSystem': 'Sistem',
      'newGame': 'Permainan Baharu', 'howToPlay': 'Cara Bermain', 'statistics': 'Statistik',
      'continueLabel': 'Teruskan', 'start': 'Mula', 'home': 'Laman Utama',
      'difficulty': 'Kesukaran', 'easy': 'Mudah', 'medium': 'Sederhana', 'hard': 'Sukar', 'master': 'Mahir',
      'opponent': 'Lawan', 'computer': 'Komputer', 'passAndPlay': 'Dua Pemain',
      'firstMove': 'Gerakan pertama', 'yourTurn': 'Giliran anda', 'victory': 'Menang',
      'defeat': 'Kalah', 'draw': 'Seri',
      'achievements': 'Pencapaian', 'dailyChallenge': 'Cabaran Harian',
    },
    'fil': {
      'settings': 'Mga Setting', 'game': 'Laro', 'theme': 'Tema', 'sound': 'Tunog',
      'animations': 'Mga Animation', 'language': 'Wika', 'languageSystem': 'Sistema',
      'newGame': 'Bagong Laro', 'howToPlay': 'Paano Maglaro', 'statistics': 'Estadistika',
      'continueLabel': 'Magpatuloy', 'start': 'Simulan', 'home': 'Home',
      'difficulty': 'Hirap', 'easy': 'Madali', 'medium': 'Katamtaman', 'hard': 'Mahirap', 'master': 'Dalubhasa',
      'opponent': 'Kalaban', 'computer': 'Kompyuter', 'passAndPlay': 'Dalawang Manlalaro',
      'firstMove': 'Unang galaw', 'yourTurn': 'Iyong galaw', 'victory': 'Panalo',
      'defeat': 'Talo', 'draw': 'Tabla',
      'achievements': 'Mga Tagumpay', 'dailyChallenge': 'Hamon ng Araw',
    },
    'bn': {
      'settings': 'সেটিংস', 'game': 'খেলা', 'theme': 'থিম', 'sound': 'শব্দ',
      'animations': 'অ্যানিমেশন', 'language': 'ভাষা', 'languageSystem': 'সিস্টেম',
      'newGame': 'নতুন খেলা', 'howToPlay': 'কীভাবে খেলবেন', 'statistics': 'পরিসংখ্যান',
      'continueLabel': 'চালিয়ে যান', 'start': 'শুরু', 'home': 'হোম',
      'difficulty': 'কঠিনতা', 'easy': 'সহজ', 'medium': 'মাঝারি', 'hard': 'কঠিন', 'master': 'মাস্টার',
      'opponent': 'প্রতিপক্ষ', 'computer': 'কম্পিউটার', 'passAndPlay': 'দুজনে খেলুন',
      'firstMove': 'প্রথম চাল', 'yourTurn': 'আপনার পালা', 'victory': 'জয়',
      'defeat': 'পরাজয়', 'draw': 'ড্র',
      'achievements': 'অর্জন', 'dailyChallenge': 'দৈনিক চ্যালেঞ্জ',
    },
    'he': {
      'settings': 'הגדרות', 'game': 'משחק', 'theme': 'ערכת נושא', 'sound': 'צליל',
      'animations': 'אנימציות', 'language': 'שפה', 'languageSystem': 'מערכת',
      'newGame': 'משחק חדש', 'howToPlay': 'איך משחקים', 'statistics': 'סטטיסטיקה',
      'continueLabel': 'המשך', 'start': 'התחל', 'home': 'בית',
      'difficulty': 'רמת קושי', 'easy': 'קל', 'medium': 'בינוני', 'hard': 'קשה', 'master': 'מומחה',
      'opponent': 'יריב', 'computer': 'מחשב', 'passAndPlay': 'שני שחקנים',
      'firstMove': 'מהלך ראשון', 'yourTurn': 'תורך', 'victory': 'ניצחון',
      'defeat': 'הפסד', 'draw': 'תיקו',
      'achievements': 'הישגים', 'dailyChallenge': 'אתגר יומי',
    },
    'ur': {
      'settings': 'ترتیبات', 'game': 'کھیل', 'theme': 'تھیم', 'sound': 'آواز',
      'animations': 'اینیمیشن', 'language': 'زبان', 'languageSystem': 'سسٹم',
      'newGame': 'نیا کھیل', 'howToPlay': 'کھیلنے کا طریقہ', 'statistics': 'اعداد و شمار',
      'continueLabel': 'جاری رکھیں', 'start': 'شروع', 'home': 'ہوم',
      'difficulty': 'دشواری', 'easy': 'آسان', 'medium': 'درمیانہ', 'hard': 'مشکل', 'master': 'ماہر',
      'opponent': 'حریف', 'computer': 'کمپیوٹر', 'passAndPlay': 'دو کھلاڑی',
      'firstMove': 'پہلی چال', 'yourTurn': 'آپ کی باری', 'victory': 'فتح',
      'defeat': 'شکست', 'draw': 'برابر',
      'achievements': 'کارنامے', 'dailyChallenge': 'روزانہ چیلنج',
    },
    'ta': {
      'settings': 'அமைப்புகள்', 'game': 'விளையாட்டு', 'theme': 'தீம்', 'sound': 'ஒலி',
      'animations': 'அனிமேஷன்கள்', 'language': 'மொழி', 'languageSystem': 'அமைப்பு',
      'newGame': 'புதிய விளையாட்டு', 'howToPlay': 'எப்படி விளையாடுவது', 'statistics': 'புள்ளிவிவரம்',
      'continueLabel': 'தொடரவும்', 'start': 'தொடங்கு', 'home': 'முகப்பு',
      'difficulty': 'கடினம்', 'easy': 'எளிது', 'medium': 'நடுத்தரம்', 'hard': 'கடினம்', 'master': 'நிபுணர்',
      'opponent': 'எதிராளி', 'computer': 'கணினி', 'passAndPlay': 'இருவர் விளையாட்டு',
      'firstMove': 'முதல் நகர்வு', 'yourTurn': 'உங்கள் முறை', 'victory': 'வெற்றி',
      'defeat': 'தோல்வி', 'draw': 'சமநிலை',
      'achievements': 'சாதனைகள்', 'dailyChallenge': 'தினசரி சவால்',
    },
    'te': {
      'settings': 'సెట్టింగ్‌లు', 'game': 'ఆట', 'theme': 'థీమ్', 'sound': 'ధ్వని',
      'animations': 'యానిమేషన్‌లు', 'language': 'భాష', 'languageSystem': 'సిస్టమ్',
      'newGame': 'కొత్త ఆట', 'howToPlay': 'ఎలా ఆడాలి', 'statistics': 'గణాంకాలు',
      'continueLabel': 'కొనసాగించు', 'start': 'ప్రారంభించు', 'home': 'హోమ్',
      'difficulty': 'కష్టం', 'easy': 'సులభం', 'medium': 'మధ్యస్థం', 'hard': 'కష్టం', 'master': 'నిపుణుడు',
      'opponent': 'ప్రత్యర్థి', 'computer': 'కంప్యూటర్', 'passAndPlay': 'ఇద్దరు ఆటగాళ్లు',
      'firstMove': 'మొదటి ఎత్తు', 'yourTurn': 'మీ వంతు', 'victory': 'విజయం',
      'defeat': 'ఓటమి', 'draw': 'డ్రా',
      'achievements': 'విజయాలు', 'dailyChallenge': 'రోజువారీ సవాలు',
    },
  };
}

/// 現在の言語に対応する L10n(設定の localeCode から解決)。
final l10nProvider = Provider<L10n>(
  (ref) => L10n.resolve(ref.watch(settingsProvider).localeCode),
);
