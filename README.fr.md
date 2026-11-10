<p align="center">
  <img src="docs/bubulle.png" width="160" alt="Bubulle">
</p>

<h1 align="center">Bubulle</h1>

<p align="center"><a href="README.md">Read in English</a></p>

**Ton compagnon de pêche pour World of Warcraft.** Une seule touche pour lancer et ferrer, le plouf du bouchon enfin audible, et un carnet qui se souvient de chaque prise.

Rien n'est automatisé : Bubulle rend simplement la pêche agréable. Conçu pour **WoW Forever (client 1.60.1)**, fonctionne aussi sur **Retail (12.1)**. Disponible en français et en anglais.

---

## 🎣 Fonctionnalités

### ⌨️ Une seule touche pour pêcher
- Appuie sur ta **touche de pêche** pour lancer, puis encore une fois quand le bouchon fait plouf pour **ferrer**. Fini de chercher le bouchon avec la souris.
- Tu préfères la souris ? **Double-clic droit** sur l'eau pour lancer. La vitesse du double-clic se règle.
- Ta touche peut marcher partout, ou seulement en mode pêche. À toi de choisir.

### 🔊 Entends chaque touche
- Pendant la pêche, Bubulle **met le bouchon en avant** : effets plus forts, musique et ambiance baissées.
- En option : garder le son quand le jeu est en arrière-plan.
- Quand tu arrêtes, **tes réglages de son reviennent exactement comme avant**. Même après un plantage, ils sont rétablis à ta connexion suivante.

### 🐠 Un petit compagnon au bord de l'eau
- Un panneau compact affiche le **temps du bouchon**, les statistiques de ta session et tes dernières prises.
- Sur WoW Forever, il montre aussi ta **vraie compétence de pêche** (bonus entre parenthèses), la **durée restante de ton appât**, et te prévient s'il te manque une canne.
- Bubulle commente ta pêche de temps en temps, et **saute de joie** quand tu attrapes quelque chose de nouveau.

### 📖 Un carnet qui se souvient
- Chaque prise est notée **par zone** : ce qui vit où, et combien tu en as pêché.
- **Statistiques de session** : prises, lancers, prises par heure, taux de réussite.
- **Notifications** pour les nouvelles espèces et les prises rares, avec un son en option.

### 🧭 Jamais dans tes pattes
- **Le mode pêche démarre tout seul** à ton premier lancer et s'arrête quand tu le décides (un arrêt après inactivité est possible).
- **Butin automatique** pendant la pêche, puis ton réglage revient.
- Panneau déplaçable et redimensionnable, **bouton sur la minicarte**, entrée dans le menu des addons, et une page dans les options AddOns du jeu.

---

## 🚀 Pour commencer

1. Télécharge le fichier `.zip` de la [dernière version](https://github.com/Chauseth/bubulle/releases/latest) et place le dossier `Bubulle` dans `World of Warcraft\_forever_\Interface\AddOns` (ou `_retail_`).
2. En jeu, tape `/bubulle` ou clique sur le bouton de la minicarte.
3. Choisis ta **touche de pêche** sur l'écran d'accueil.
4. Va au bord de l'eau et appuie sur ta touche. Bubulle s'occupe du reste.

Pour l'installation pas à pas et le détail de chaque option, lis le [guide complet](docs/GUIDE.md).

---

## ⚙️ Commandes

| Commande | Ce qu'elle fait |
|---|---|
| `/bubulle` | Ouvrir ou fermer la fenêtre de Bubulle |
| `/bubulle peche` | Commencer ou arrêter le mode pêche |
| `/bubulle hud` | Afficher ou masquer en permanence le panneau |
| `/bubulle options` | Ouvrir les options |
| `/bubulle session` | Commencer une nouvelle session |
| `/bubulle minimap` | Afficher ou cacher le bouton de la minicarte |

`/bub` marche aussi. **Bouton de la minicarte :** clic gauche pour la fenêtre, clic droit pour le mode pêche, glisser pour le déplacer.

---

## ❓ Questions fréquentes

**C'est un bot ?**
Non. Blizzard interdit aux addons de lancer un sort tout seuls. Chaque lancer et chaque ferrage viennent de ta touche ou de ton clic, comme un bouton de barre d'action.

**Ma touche lance la ligne mais ne ferre pas.**
La touche ferre grâce à la fonction « Interagir » du jeu, que Bubulle active pendant la pêche. Reste près de ton bouchon et vérifie qu'aucun autre addon n'utilise la même touche.

**Mes réglages de son vont-ils rester modifiés ?**
Non. Bubulle les note avant de toucher à quoi que ce soit, et les remet à la fin du mode pêche, ou à ta connexion suivante si le jeu s'est fermé brutalement.

**Je peux l'utiliser avec un autre addon de pêche ?**
Mieux vaut éviter : deux addons qui gèrent le double-clic et le son en même temps se gênent. Désactive l'autre.

---

## ⚠️ Limites connues

- Comme tout addon, Bubulle ne peut pas lancer en combat : la touche et le double-clic sont en pause pendant un combat.
- Français et anglais seulement pour l'instant.

---

## 🐞 Bugs et suggestions

Ouvre un ticket sur [GitHub](https://github.com/Chauseth/bubulle/issues) en précisant ta version du jeu, ce que tu faisais, et le texte de l'erreur s'il y en a un.
