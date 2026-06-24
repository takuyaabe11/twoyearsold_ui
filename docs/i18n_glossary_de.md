# Glossar DE — LOCK (Referenz für alle 37 Sprachen)

Redaktionsleitung: Lena Vogt
Stand: 2026-06-23 · Status: **VERBINDLICH (LOCK)**
Grundlage: DESIGN.md §10.2 — *ruhig, schlicht, in Aussagesätzen. Kein Hype, kein Befehlston.*

Dieses Glossar ist die Referenz. Die deutsche Fassung ist der „Satzspiegel" (das Maß),
an dem sich alle weiteren Sprachen ausrichten. Wer übersetzt, übersetzt **das Konzept**,
nicht das englische Wort — Japanisch (ja) ist die Quelle der Absicht, wenn en und ja
auseinandergehen.

---

## 1. Terminologie (Konzept | LOCK-de | Begründung)

| Konzept | LOCK-de | Begründung |
|---|---|---|
| Best (Höchstwert, Zahl) | **BESTE** | Versalien für Zahlenlabels, neben PUNKTE/ZEIT. Konsistent in 2048 & Minesweeper. |
| Best (Bestzeit) | **Bestzeit** | Wenn der Wert eine Zeit ist (NumberPlace). |
| New Game | **Neues Spiel** | shared-Wert, überall übernehmen. |
| Continue / Resume / Keep Going | **Fortsetzen** | Ein Begriff für „weiterspielen, wo man war". Ersetzt das frühere Schwanken Weiter/Fortsetzen. |
| Pass & Play (Label) | **Zu zweit** | Knappes UI-Label. |
| Pass & Play (im Fließtext) | **abwechselnd zu zweit** | „Freund" vermeidet Geschlecht/Anzahl. |
| Hint | **Tipp** | Bereits etabliert; auch Reversi/AirHockey folgen. |
| Review (Partieanalyse) | **Analyse** | Schachnah, präzise. Reversi-Nachbereitung der Partie. |
| Review (Rückblick/Bilanz) | **Rückblick** | AirHockey: Bilanz nach dem Match (Coach). |
| Solved / Cleared | **Gelöst** | Durchgängig. |
| Completed (abgeschlossen) | **Abgeschlossen** | Eigenes Konzept, ≠ Gelöst (NumberPlace-Statistik). |
| Streak | **Serie** | Etabliert, gut. |
| Difficulty | **Schwierigkeit** | Musterbeispiel, schon konsistent. |
| Master / Expert (höchste Stufe) | **Meister** | ja sagt beidemal „達人". Daher vereinheitlicht auf Meister. „Experte" → Meister. |
| Game Over | **Spielende** | Englisches Restwort getilgt (NumberPlace). |
| Undo | **Rückgängig** | NumberPlace-Wert; Reversi folgt. (Kurzform „Zurück" nur falls Platz knapp.) |
| Hint-ring „safe" | **sicher** | „beweisbar sicher" für Logikkontext (Minesweeper). |
| Puck / Disc | **Puck** (AirHockey) / **Stein** (Reversi) | Sportgerät vs. Brettspielstein. |
| Mallet | **Schläger** | Eishockey-/Air-Hockey-Standard im Deutschen. |
| Coach | **Coach** | Eingebürgert, kurz, neutral. Ton: ruhiger Ratgeber, kein Befehl. |
| Bank shot | **Bande** / über die Bande | Billard-/Hockey-Vokabular. |

### Marken-Entscheidungen (Owner-Bestätigung empfohlen — hier vorläufig fixiert)

| Konzept | gewählt | Alternative(n) | warum gewählt |
|---|---|---|---|
| 墨 / Ink | **Tinte / TINTE** | Schwarz, Tusche | Beibehalten. Paart sich mit „Rot" als Farbe vs. „Tinte" als Material — der Bruch ist gewollt poetisch (Tusche/Tinte ist das Schreibmaterial der editorial-minimal-Welt). Reiner Farbkontrast „Schwarz" wäre nüchterner, aber verschenkt die Markenpoesie. **Tusche** wäre die kultur­treueste Wahl (墨 = Tuschmalerei), klingt aber Laien fremd. → Tinte als Mittelweg. |
| boom (Misserfolg) | **Daneben** | Verloren, Bumm | „Bumm" ist Lautmalerei und bricht die Stille am stärksten. „Daneben" ist ein leises, erwachsenes Eingeständnis („vorbei", „verfehlt") und steht als abstraktes Pendant schön neben „Gelöst". |
| Master/Expert | **Meister** | Experte | Eine höchste Stufe, ein Wort. ja stützt die Vereinheitlichung. |

---

## 2. Anrede — du / T-V-Politik (für alle Sprachen)

- **Deutsch: durchgängig `du`.** Keine Sie-Form. Bestätigt durch das gesamte Korpus.
- **Direktive für alle T/V-Sprachen** (fr, es, it, pt, ru, pl, nl, cs, hu, …):
  **familiäre Anrede, Singular** (frz. *tu*, span. *tú*, ital. *tu*, russ. *ты*).
  Eine Person spricht zu einer Person — ruhig, auf Augenhöhe, nicht distanziert.
- **Sprachen ohne T/V** (en, ja, …): Höflichkeitsregister neutral-schlicht halten;
  ja bleibt in der ruhigen Aussageform (keine 〜してください-Befehlsketten).

---

## 3. Ton — Verbotsliste & Regeln

**Grundton:** ruhig, schlicht, Aussagesätze. Kein Hype, kein Befehlston, kein Anbiedern.

### Verbotene/zu meidende Wörter & Muster (de)
- **`zocken`** — Slang für (glücks-)spielen. Nie. → `raten` / `geraten`.
- **`Bumm` / Lautmalerei** (`Wusch`, `Peng`, `Boom`) — bricht die Stille. → abstraktes Nomen.
- **`Komm … wieder` / `Schau wieder vorbei`** — kindlich-anbiedernd. → `Bis morgen.`
- **Doppelter Befehl / Frage + Imperativ** als Köder (`Steckst du fest? Hol dir …`)
  → ruhige Bedingung: `Festgefahren? Ein Tipp hilft weiter.`
- **Ausrufe-Hype** (`Super!`, `Klasse!`, mehrere `!`) — höchstens ein nüchternes `Gelöst!`.
- **Anglizismen, wo es ein ruhiges deutsches Wort gibt** (`Highscore` → `Bestwert`,
  `Move` als Lehnwort → `Zug`). Ausnahmen nur bei Eingebürgertem (`Coach`, `Puck`).

### Coach-Register (AirHockey)
Der Coach ist **Ratgeber, nicht Kommandeur**. du-Form, **keine reinen Imperative**.
Statt „Halt die Mitte!" → „Die Mitte solltest du dichter halten." / als ruhige
Beobachtung + sanfte Empfehlung. Lob bleibt knapp und trocken (`Gut gespielt.`).

### Stil-Detail
- Gedankenstrich `—` (Geviert) für den editorial-minimalen Atem, nicht `-`.
- Komposita statt Genitiv-Ketten, wo es strafft (`Logik-Tiefe`, `Tipp-Ring`).
- Verben des leisen Bewegens bevorzugen: `gleiten` > `rutschen`.
