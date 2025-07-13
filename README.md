# 🔫 FiveM Russian Roulette Minigame

A fun, dramatic, and deadly game of chance — **Russian Roulette**, now in GTA V via FiveM. Face off against another player, spin the chamber, and pull the trigger. One bullet. Six chambers. Will you survive?

---

## 🎮 Features

- Invite nearby players to a duel
- Turn-based Russian Roulette mechanics
- One-in-six bullet chance logic
- Realistic gun handling with animations and sound
- Prop gun and head positioning
- Disables player controls during the game for fairness
- Win, die, or forfeit — your fate is in your hands

---

## 📦 Installation

1. **Download the latest release** from the [Releases](https://github.com/TickerDev/TC-RussianRoulette/releases) tab. Extract it to your server's `resources` folder.
2. Add the resource to your `server.cfg`:
   ```cfg
   ensure TC-RussianRoulette
   ```

---

## 🔊 Sound Setup (Required)

This script uses **Interact Sound** to play the revolver SFX.

You **must install** [interact-sound](https://github.com/plunkettscott/interact-sound) and add the following entries to its `fxmanifest.lua`:

```lua
files {
    'html/sounds/revolver_click.ogg',
    'html/sounds/revolver_bang.ogg'
}
```

Make sure you put the `.ogg` files from the release in `interact-sound/html/sounds/`.

---

## 🧠 Usage

Use the `/rroulette` command near another player (within \~3 meters) to challenge them.

- If accepted, you'll both be teleported into position and frozen.
- Use:

  - **F5** to pull the trigger
  - **F6** to forfeit

The game ends when:

- Someone dies
- A player forfeits
- One player disconnects

---

## ⚠ Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [interact-sound](https://github.com/plunkettscott/interact-sound)

---

## 💀 Game Logic

- Each round, the revolver chamber is randomly spun.
- A random bullet slot is chosen.
- If the slot matches the active chamber: **boom**.
- If not: **click**, and the turn passes.

---

## Made by Ticker, under MIT license

Enjoy your game of chance. Stay lucky. 💀🔫
