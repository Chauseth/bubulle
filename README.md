# Bubulle, ton assistant de pêche

Bubulle est un addon pour **World of Warcraft: Forever (1.60.1)**, qui marche aussi sur **Retail (12.1.5)**. Le poisson rouge Bubulle t'accompagne au bord de l'eau : une seule touche pour lancer et ferrer, le bruit du bouchon mis en avant, et ton carnet de pêche tenu à jour.

## Installation (5 minutes)

1. **Ferme WoW** (ou reste sur l'écran de sélection des personnages).
2. Ouvre le dossier du jeu :
   `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns`
   (si le dossier `AddOns` n'existe pas, crée-le). Pour Retail, c'est le même chemin avec `_retail_`.
3. Copie-y le dossier **`Bubulle`** entier. Depuis GitHub (bouton **Code > Download ZIP**), le dossier s'appelle `bubulle-main` : renomme-le en **`Bubulle`**. Tu dois obtenir :
   `...\Interface\AddOns\Bubulle\Bubulle.toc`
   ⚠️ Erreur classique : un dossier en trop (`AddOns\Bubulle\Bubulle\Bubulle.toc`). Le fichier `.toc` doit être directement dans `AddOns\Bubulle\`.
4. Lance le jeu. Sur l'écran des personnages, clique sur **AddOns** (en bas à gauche) et vérifie que Bubulle est coché.
5. En jeu, Bubulle se présente au bout de quelques secondes et te demande de choisir ta **touche de pêche**. Ensuite, `/bubulle` ouvre sa fenêtre.

Si tu modifies un fichier pendant que le jeu tourne, tape `/reload` pour recharger l'interface.

Si Bubulle apparaît « périmé » après un patch, coche **Charger les AddOns périmés** dans la liste des AddOns (ou demande-moi la mise à jour du numéro de version dans le `.toc`).

## Utilisation

| Action | Comment |
|---|---|
| Lancer la ligne | Ta **touche de pêche**. Ou un **double-clic droit** rapide sur l'eau. |
| Ferrer le poisson | La **même touche** quand le bouchon fait plouf. Le clic droit sur le bouchon marche toujours. |
| Mode pêche | Il s'active tout seul à ton premier lancer (ou `/bubulle peche`) : son amélioré, panneau de Bubulle, statistiques. |
| Canne et appât (Forever) | Le panneau affiche ta compétence de pêche, la durée restante de ton appât, et Bubulle te prévient s'il manque la canne. |
| Ouvrir le carnet | `/bubulle`, le bouton rond de Bubulle sur la minicarte (clic droit : mode pêche), le bouton ≡ du panneau, ou le menu des addons sous la minicarte. |
| Arrêter | La croix du panneau ou `/bubulle peche`. Un arrêt automatique après un temps sans lancer peut être activé dans les Options. |

Pendant le mode pêche, Bubulle monte le volume des effets et coupe musique et ambiance pour que tu entendes bien le « plouf ». **Tes réglages de son sont remis exactement comme avant** dès que tu arrêtes (même après un plantage, ils sont rétablis à la connexion suivante).

Commandes : `/bubulle` (fenêtre), `/bubulle peche`, `/bubulle hud`, `/bubulle options`, `/bubulle session`, `/bubulle minimap` (affiche ou cache le bouton de la minicarte). Raccourci : `/bub`.

La touche de pêche s'appuie sur la touche « Interagir » du jeu : l'addon active tout seul l'option nécessaire pendant la pêche, puis la remet comme avant. Choisis une touche qui ne sert à rien d'autre : hors combat, elle lance la ligne même en dehors du mode pêche (désactivable dans les Options).

## Comment l'addon est construit (pour apprendre)

Un addon WoW, c'est un dossier avec :

- **`Bubulle.toc`** : la carte d'identité. Le jeu lit ce fichier en premier : nom, versions du jeu visées (`## Interface: 120105, 16001` = Retail 12.1.5 et Forever 1.60.1), variable sauvegardée (`BubulleDB`, où sont stockées tes prises entre deux sessions), puis la liste des fichiers Lua à charger, **dans l'ordre**.
- **Des fichiers `.lua`** : le code. Lua est un langage simple ; WoW lui fournit des fonctions (« l'API ») pour créer des fenêtres, réagir aux événements, etc.

Les fichiers, du plus simple au plus avancé :

| Fichier | Rôle |
|---|---|
| `Locales.lua` | Tous les textes, en français et en anglais. Idéal pour commencer à bidouiller : change une réplique de Bubulle, fais `/reload`, regarde. |
| `Core.lua` | Le cœur : réglages par défaut, chargement de la sauvegarde, commandes `/bubulle`. |
| `Journal.lua` | Le carnet : détecte une prise (événement `LOOT_READY` + `IsFishingLoot()`), l'enregistre par zone. |
| `Fishing.lua` | Le mode pêche, le double-clic, la touche unique et le son. Le passage le plus « technique » est expliqué en commentaire. |
| `Assistant.lua` | La personnalité de Bubulle : quelle réplique dire, et quand. |
| `UI/Theme.lua` | Couleurs et polices. Change l'orange d'accent ici et tout l'addon suit. |
| `UI/Widgets.lua` | La boîte à outils d'interface (boutons, cases, curseurs, listes...). |
| `UI/Mascot.lua` | Affiche Bubulle et le fait nager. Son image est `Media/Bubulle.tga` : tu peux la remplacer par la tienne (256 x 256, même nom), puis relancer le jeu. |
| `UI/HUD.lua`, `UI/Window.lua`, `UI/Toast.lua`, `UI/Settings.lua` | Le panneau, la grande fenêtre, les notifications, la page dans Options > AddOns. |

**Le point clé à retenir** : Blizzard interdit à un addon de lancer un sort tout seul (pour éviter les bots). Le double-clic fonctionne grâce à une astuce autorisée : au 2e clic, l'addon redirige un court instant ton bouton droit vers un bouton « sécurisé » qui lance Pêche. C'est donc toujours **ton** clic qui lance le sort.

## Développement

| Dossier | Contenu |
|---|---|
| `tests/harness.lua` | Une simulation du jeu pour tester l'addon sans lancer WoW : `lua5.1 tests/harness.lua . frFR 16001` (Forever) ou `... 120105` (Retail). |
| `tools/draw_bubulle.py` | Le script qui dessine Bubulle : `python3 tools/draw_bubulle.py` régénère `Media/Bubulle.tga` (Python 3 + Pillow). |

Ces deux dossiers ne sont pas chargés par le jeu (ils ne sont pas listés dans le `.toc`) : tu peux laisser le dépôt tel quel dans ton dossier AddOns.

## Outils conseillés pour la suite

- Commande `/fstack` en jeu : survole un élément de l'interface pour voir son nom.
- L'addon **BugSack** (+ BugGrabber) : affiche proprement les erreurs Lua.
- **Visual Studio Code** avec l'extension « WoW API » : autocomplétion des fonctions du jeu.
