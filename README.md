# 🎲 Farkle Frenzy

A companion **score-tracking app** for the dice game *Farkle*. Farkle Frenzy doesn't roll the dice for you — you and your friends roll physical dice around the table, and the app handles every piece of bookkeeping the game demands: turn order, dice hand-offs, opening-score requirements, the last-round countdown, and final standings.

Built in Flutter. Runs on **Android** and **Windows** (see [Releases](https://github.com/Jeppedy/FarkleFrenzy/releases)).

---

## What the app does for you

- Tracks **3–9 players**, each with a color, a running total, and an "opened" flag
- Records every scoring combo you tap so your **turn score** and **projected banked total** are always visible
- Enforces the **500-point opening requirement** (chip stays orange until you clear the bar, turns green once you do)
- Shows you where you stand relative to the leader — both **right now** and **if you banked this turn**
- Manages the **last round** automatically — when someone crosses the winning score, everyone else gets one more turn, then the game ends
- Lets you **pass the dice** to another player mid-turn (see [House Rules](#house-rules) below)
- **Undo** any action — including scoring, banking, busting, or passing
- Announces the winner with a full final standings screen

---

## Getting Started

1. **Set a target score.** Default is 10,000. Any value ≥ 1,000 works.
2. **Choose how many players** (3–9), then enter their names.
3. **Tap "Start Game"** and the first player is up.

---

## During a Turn

Roll the dice physically. When you set aside scoring dice, tap the matching combo(s) in the app to build your turn score.

### Scoring Combinations

| Combo | Points |
|---|---:|
| **Singles** | |
| Single `1` | **100** |
| Single `5` | **50** |
| **Three of a Kind** | |
| Three `1`s | **300** |
| Three `2`s | **200** |
| Three `3`s | **300** |
| Three `4`s | **400** |
| Three `5`s | **500** |
| Three `6`s | **600** |
| **Multiples** *(flat value, any face)* | |
| Four of a Kind | **1,000** |
| Five of a Kind | **2,000** |
| Six of a Kind | **3,000** |
| **Special Combos** | |
| Small Straight (`1-2-3-4-5`) | **500** |
| Large Straight (`1-2-3-4-5-6`) | **1,500** |
| Three Pairs | **1,500** |
| Farkle Full House *(three-of-a-kind + a pair)* | **1,500** |
| Two Triplets | **2,500** |

### Three Actions Every Turn

- **➕ Tap a combo** — adds it to your current turn score. The header updates in real time to show `Total → If Banked: X`.
- **💰 BANK** — credit the turn score to your total. Play advances to the next player. Blocked until you meet the opening requirement (see below).
- **💥 BUST** — you rolled and nothing scored. Turn score is lost, play advances. *(Tap is instant — no confirmation prompt.)*

If you fat-finger anything, hit **↶ Undo** in the top-right. It steps back through the entire turn history, including passes.

---

## House Rules

These are the specific rules Farkle Frenzy enforces. Some are standard Farkle; others are house variants baked into this app.

### 🎯 Opening Score Requirement — 500 pts

You must score at least **500 points in a single turn** before any points can be added to your total. Until you do, banking is blocked.

- The chip next to your name shows your status: **orange** = haven't opened yet, **green** = threshold met, ready to bank.
- Once you've opened (banked ≥ 500 in one turn once), the requirement is permanently satisfied for the rest of the game.

### 🎲 Passing the Dice

This is the signature house rule. **You can pass the dice mid-turn to any other player**, and they continue building on the current turn score.

**How to pass:**
1. Switch to the **Leaderboard** tab
2. Tap any other player's name
3. Dice are passed instantly — no confirmation

**How passes affect scoring:**
- Whoever is **holding the dice when BANK is tapped gets the points.** Not the person whose "turn" it is in rotation — the person actively scoring.
- The **rotation owner** (whose "slot" it is) does not change during a pass chain. After the bank or bust resolves, play advances from the rotation owner's position in the seating order.
- You **cannot pass to yourself** (the app blocks it).
- Passes can be chained — Alice → Bob → Carol → Dave, all within the same turn.

**Why this rule exists:** it introduces high-stakes cooperation and betrayal. Do you pass the dice to your buddy to help them open? Do you take the hot streak yourself? A generous pass can also be a strategic gift when the recipient is one Farkle away from disaster.

### 🔔 Last Round

When any player's total reaches or exceeds the **target score** (default 10,000), a **LAST ROUND** banner appears at the top of the scoring screen.

- Every remaining player gets **one final turn** to try to overtake.
- After the player who *triggered* the last round has their next slot come back around, the game ends.
- Highest total wins — even if the trigger wasn't the first to cross the target.

### 👑 Winning

Whoever has the **highest total when the last round completes** wins. Multiple players can go over the target — the winner is simply whoever's on top when the music stops.

### ↶ Undo

Any action can be undone:
- Adding a scoring combo
- Banking
- Busting
- Passing the dice

Undo also rolls back the last-round trigger if you undo a bank that caused it. Undo history persists for the entire game — no depth limit.

---

## UI Notes

- **Scoring tab** — your combo pad and Bank/Bust/Undo controls
- **Leaderboard tab** — running standings, tap any name to pass the dice
- **Player Header** shows:
  - Current total & projected total *if banked now*
  - Opening-requirement chip (orange/green)
  - Leader status: `Current: leader by X pts   →   If Banked: leader by Y pts` — the "if banked" phrase is **green** when banking would improve your position (extending a lead, closing a gap, or flipping to first place)
- **Player colors** — up to 9 distinct colors so everyone stands out on the leaderboard

---

## Building from Source

Standard Flutter project.

```bash
flutter pub get
flutter run                          # dev
flutter build apk --release          # Android
flutter build windows --release      # Windows
```

Automated builds run on every `v*` tag push via `.github/workflows/build.yml` — the resulting APK and Windows ZIP are attached to the corresponding GitHub Release.

---

## Author

Built by **Jeffrey Herr** — score tracker designed around the way *we* actually play Farkle. Passes, hostile hand-offs, and all.

Enjoy. 🎲
