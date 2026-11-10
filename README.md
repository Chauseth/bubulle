<p align="center">
  <img src="docs/bubulle.png" width="160" alt="Bubulle">
</p>

<h1 align="center">Bubulle</h1>

<p align="center"><a href="README.fr.md">Lire en français</a></p>

**Your fishing buddy for World of Warcraft.** One key to cast and hook, a splash you can actually hear, and a journal that remembers every catch.

Nothing is automated: Bubulle simply makes fishing comfortable. Built for **WoW Forever (client 1.60.1)**, also works on **Retail (12.1)**. Available in English and French.

---

## 🎣 Features

### ⌨️ One key to fish
- Press your **fishing key** to cast, press it again when the bobber splashes to **hook**. No more hunting for the bobber with the mouse.
- Prefer the mouse? **Double right-click** the water to cast. The double-click speed is adjustable.
- Your key can work everywhere, or only while fishing mode is on. Your choice.

### 🔊 Hear every bite
- While you fish, Bubulle **brings the splash forward**: louder effects, music and ambience turned down.
- Optional: keep the sound playing when the game is in the background.
- When you stop, **your sound settings come back exactly as they were**. Even after a crash, they are restored at your next login.

### 🐠 A little friend by the water
- A compact panel shows the **bobber timer**, your session stats and your last catches.
- On WoW Forever, it also shows your **real fishing skill** (bonuses in brackets), your **lure time left**, and warns you when no fishing pole is equipped.
- Bubulle comments on your fishing now and then, and **hops with joy** when you land something new.

### 📖 A journal that remembers
- Every catch is logged **by zone**: what lives where, and how many you caught.
- **Session stats**: catches, casts, catches per hour, success rate.
- **Notifications** for new species and rare catches, with an optional sound.

### 🧭 Never in your way
- **Fishing mode starts by itself** on your first cast and stops when you say so (an idle timer is optional).
- **Auto loot** while fishing, turned back to your setting afterwards.
- Movable and resizable panel, **minimap button**, addon compartment entry, and a page in the game's AddOns options.

---

## 🚀 Getting started

1. Download `Bubulle.zip` from the [latest release](https://github.com/Chauseth/bubulle/releases/latest) and put the `Bubulle` folder in `World of Warcraft\_forever_\Interface\AddOns` (or `_retail_`).
2. Log in and type `/bubulle`, or click the minimap button.
3. Pick your **fishing key** on the welcome screen.
4. Walk to the water and press your key. Bubulle takes care of the rest.

---

## ⚙️ Commands

| Command | What it does |
|---|---|
| `/bubulle` | Open or close Bubulle's window |
| `/bubulle peche` | Start or stop fishing mode |
| `/bubulle hud` | Always show or hide Bubulle's panel |
| `/bubulle options` | Open the options |
| `/bubulle session` | Start a new session |
| `/bubulle minimap` | Show or hide the minimap button |

`/bub` works too. **Minimap button:** left-click opens the window, right-click starts or stops fishing mode, drag to move it.

---

## 🛠️ Settings

- Fishing key, and whether it works outside fishing mode
- Double right-click, its speed, and whether it works outside fishing mode
- Splash boost, effects volume, mute music, mute ambience, sound in background
- Auto loot, idle timer
- Bubulle's comments, notifications for new species and rare catches, notification sound
- Panel visibility, lock, size, minimap button

---

## ❓ FAQ

**Is this a bot?**
No. Blizzard does not let addons cast spells on their own. Every cast and every hook comes from your key press or your click, like an action bar button.

**My key casts, but doesn't hook the fish.**
The key hooks through the game's "interact" feature, which Bubulle turns on while you fish. Stay close to your bobber, and make sure no other addon rebinds the same key.

**Will my sound settings stay changed?**
No. Bubulle remembers them before changing anything, and puts them back when fishing mode ends, or at your next login if the game closed unexpectedly.

**Can I use it with another fishing addon?**
Better not: two addons handling the double-click and the sound at the same time get in each other's way. Disable the other one.

**Does it work on Retail?**
Yes. Skill, lure and fishing pole tracking only appear on WoW Forever, where they matter.

---

## ⚠️ Known limitations

- Like every addon, Bubulle cannot cast in combat: the fishing key and double-click pause during combat.
- English and French only for now. Translations are welcome.

---

## 🐞 Bug reports & suggestions

Open an issue on [GitHub](https://github.com/Chauseth/bubulle/issues) with:
- your game version (Forever or Retail),
- what you did and what happened,
- the error text if one appeared (BugSack makes this easy).
