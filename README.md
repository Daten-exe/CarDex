# CarDex

Un Pokédex pour les voitures — scanne n'importe quel véhicule avec ton appareil photo et l'IA (Google Gemini) identifie la marque, le modèle, l'année et la puissance en temps réel.

## Fonctionnalités

- **Scanner IA** : prends une photo ou importe depuis la galerie pour identifier une voiture
- **Collection** : consulte toutes les voitures découvertes par la communauté ; les tiennes sont débloquées
- **Historique** : vois les voitures que tu as personnellement scannées avec la date et le lieu
- **Cloud** : tes captures sont synchronisées sur tous tes appareils via Supabase

## Stack technique

- Flutter (iOS, Android, Web, Desktop)
- Supabase (authentification + base de données cloud)
- Google Gemini (reconnaissance d'image IA)
- Provider (gestion d'état)

## Configuration

Les clés API sont injectées via `--dart-define` au moment du build. Ne jamais les écrire dans le code source.

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=GEMINI_API_KEY=AIza...
```

Pour VS Code, crée un fichier `.vscode/launch.json` :

```json
{
  "configurations": [
    {
      "name": "CarDex",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://xxx.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=eyJ...",
        "--dart-define=GEMINI_API_KEY=AIza..."
      ]
    }
  ]
}
```
