# Démo « App d'équipe terrain »

Démo de vente Flutter (iOS + Android) pour entreprises de nettoyage et d'espaces verts.
100 % hors connexion, données fictives, interface en français.

## Lancer

```bash
flutter pub get
flutter run --release   # en rendez-vous, toujours en release
```

## Script de rendez-vous (90 s)

1. **Agent** : « Bonjour Karim » → toucher l'intervention dans 30 min.
2. **J'arrive** → *Utiliser une photo d'exemple* → cocher les tâches → photo après → **Terminer**.
3. « Rapport envoyé au client » → **Voir le rapport** → **Partager**.
4. Basculer sur **Gérant** : Karim apparaît, les compteurs ont bougé, le retard est en rouge en tête de liste.

## Personnaliser pour un prospect (caché)

**Appui long sur le logo** en haut à gauche : secteur, nom, logo (galerie), couleur,
et **Réinitialiser la démo** avant chaque rendez-vous. Les réglages restent enregistrés
jusqu'à la désinstallation.

## Remplacer les visuels

- `assets/photos/` : photos d'exemple avant/après (actuellement des images générées).
  Gardez les mêmes noms de fichiers, ou modifiez `examplePhotos` dans `tool/gen_seeds.py`.
  Visez ~800 px de large en JPEG pour que le PDF s'ouvre vite.
- `assets/logo_default.png` : logo affiché par défaut.
- Données : modifier `tool/gen_seeds.py` puis `python3 tool/gen_seeds.py`
  (les horaires sont en minutes relatives à l'heure de lancement).

## Choix techniques

- Un seul `ChangeNotifier` (`DemoStore`) via `provider`.
- Bouton « Itinéraire » : copie l'adresse dans le presse-papiers (ouvrir l'app de cartes
  demanderait le paquet `url_launcher`, hors de la liste autorisée).
- `package:flutter/material.dart` est conservé (déprécié depuis Flutter 3.47 au profit de
  `material_ui`) car `printing` et `flutter_localizations` l'utilisent encore.

## Test

`flutter test` : parcours complet de Karim, mise à jour du tableau de bord, génération du PDF
(< 3 s), réinitialisation et changement de secteur.
