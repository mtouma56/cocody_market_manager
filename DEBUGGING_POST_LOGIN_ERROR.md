# Débogage : Erreur "Something went wrong" après login

## 🔍 Analyse du Problème

### Symptômes
- L'app affiche "Something went wrong" après un login réussi avec les mock credentials
- Les données existent dans Supabase (baux, commercants, etages, locaux)
- Le login mock fonctionne mais le dashboard ne charge pas

### Cause Racine Identifiée

Le **mock login** (dans `lib/presentation/login_screen/login_screen.dart`) ne créait PAS de session Supabase. Quand le DashboardScreen essayait de charger les données via les requêtes Supabase, les requêtes échouaient.

### Fichiers Concernés

1. **Login** : `lib/presentation/login_screen/login_screen.dart:62-98`
   - Le mock login vérifie juste les credentials localement
   - Ne créait aucune session Supabase

2. **Dashboard** : `lib/presentation/dashboard_screen/dashboard_screen.dart:298-349`
   - La méthode `_loadData()` fait 5 requêtes Supabase simultanées
   - Si Supabase n'est pas accessible, toutes échouent

3. **Service** : `lib/services/dashboard_service.dart`
   - Fait des requêtes SELECT sur : locaux, paiements, etages, baux, types_locaux

4. **RLS Policies** : `supabase/migrations/20241018215142_cocody_market_rental_management.sql:112-126`
   - Les policies permettent la lecture publique : `FOR SELECT TO public USING (true)`
   - Mais requiert une connexion Supabase valide

5. **Widget d'erreur** : `lib/widgets/custom_error_widget.dart:37`
   - Affiche "Something went wrong" via le gestionnaire global dans `main.dart:71-83`

## ✅ Solution Implémentée

### 1. Vérification de Connexion Supabase au Login

**Fichier modifié** : `lib/presentation/login_screen/login_screen.dart`

```dart
// 🔧 FIX: Verify Supabase initialization for mock login
try {
  final supabase = Supabase.instance.client;

  // Test if Supabase is accessible by making a simple query
  final testQuery = await supabase.from('etages').select('id').limit(1);
  debugPrint('✅ Supabase is accessible - found ${testQuery.length} etage(s)');
} catch (supabaseError) {
  // Show error to user with helpful message
  setState(() {
    _errorMessage =
      'Erreur de configuration Supabase.\n'
      'Assurez-vous que l\'app est lancée avec:\n'
      'flutter run --dart-define-from-file=env.json';
    _isLoading = false;
  });
  return;
}
```

### 2. Migration pour Support Anonyme

**Nouveau fichier** : `supabase/migrations/20251103000000_enable_anonymous_auth.sql`

Cette migration documente que l'authentification anonyme doit être activée dans Supabase Dashboard.

## 🚀 Comment Tester la Solution

### Prérequis

1. **Vérifier les variables d'environnement**
   ```bash
   cat env.json
   ```

   Doit contenir :
   ```json
   {
     "SUPABASE_URL": "https://sovrvgitiljzlqoqcdxx.supabase.co",
     "SUPABASE_ANON_KEY": "eyJhbGc..."
   }
   ```

2. **Lancer l'app avec les variables d'environnement**
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

3. **Activer l'authentification anonyme dans Supabase** (optionnel mais recommandé)
   - Aller dans Supabase Dashboard
   - Authentication > Settings
   - Activer "Enable Anonymous sign-ins"

### Test du Login

1. Lancer l'app avec les variables d'environnement
2. Utiliser un des comptes mock :
   - `admin@cocodymarket.com` / `admin123`
   - `manager@cocodymarket.com` / `manager123`
   - `supervisor@cocodymarket.com` / `super123`

3. Observer les logs :
   ```
   🔍 Testing Supabase connection...
   ✅ Supabase is accessible - found 1 etage(s)
   📝 Mock login successful - RLS public policies allow data access
   ```

4. Le dashboard devrait charger avec les données

### Si l'erreur persiste

**Vérifier les logs de console** pour :

1. **Problème d'initialisation Supabase** :
   ```
   ❌ Failed to initialize Supabase: ...
   ```
   → Vérifier que `env.json` est correct et que l'app est lancée avec `--dart-define-from-file`

2. **Problème de connexion au login** :
   ```
   ❌ CRITICAL: Supabase connection failed: ...
   ```
   → Vérifier la connexion internet et l'URL Supabase

3. **Problème de chargement des données** :
   ```
   ❌ ERREUR getDashboardStats: ...
   ```
   → Vérifier que les tables existent dans Supabase

## 🔧 Commandes de Débogage

### Vérifier l'état de Supabase

```bash
# Appliquer les migrations
supabase db push

# Vérifier les tables
supabase db diff

# Reset complet (ATTENTION: supprime les données)
supabase db reset
```

### Logs détaillés

Dans votre terminal Flutter, cherchez :
- `✅` pour les succès
- `❌` pour les erreurs
- `📊` pour les stats de données
- `🔍` pour les tests de connexion

## 📝 Notes Importantes

1. **RLS Policies** : Les policies permettent déjà la lecture publique, donc pas besoin d'authentification pour les requêtes SELECT

2. **Mock Login** : Le mock login est maintenant plus robuste avec vérification de connexion Supabase avant navigation

3. **Variables d'environnement** : TOUJOURS lancer avec `--dart-define-from-file=env.json` sinon Supabase ne sera pas initialisé

4. **Authentification anonyme** : Optionnelle mais recommandée pour une meilleure expérience avec les mocks

## 🎯 Résultat Attendu

Après ces modifications :
- Le login mock vérifie que Supabase est accessible
- Si Supabase n'est pas accessible, un message d'erreur clair est affiché
- Si Supabase est accessible, le dashboard charge correctement toutes les données
- Plus de message "Something went wrong" mystérieux !
