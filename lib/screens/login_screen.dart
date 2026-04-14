import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../cardex_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUpMode = false;

  void _handleAuth() async {
    // Vérification basique des champs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isSignUpMode) {
        // INSCRIPTION
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Compte créé ! Connectez-vous maintenant.'),
                backgroundColor: Color(0xFF2EBD69)
            ),
          );
          setState(() => _isSignUpMode = false); // Repasse en mode connexion
        }
      } else {
        // CONNEXION
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;

        // Initialisation des données utilisateur
        await Provider.of<CarDexState>(context, listen: false).initApp();

        // Redirection vers l'accueil
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation())
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : Identifiants invalides ou problème réseau.'),
              backgroundColor: Colors.redAccent
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1411), // Fond sombre cohérent
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_filled, size: 80, color: Color(0xFF2EBD69)),
              const SizedBox(height: 20),
              const Text(
                  'CarDex Premium',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)
              ),
              const SizedBox(height: 40),

              // Champ Email
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2EBD69)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Champ Mot de passe
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF2EBD69)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton d'action
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF2EBD69))
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF2EBD69),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleAuth,
                child: Text(
                    _isSignUpMode ? 'CRÉER UN COMPTE' : 'SE CONNECTER',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),

              const SizedBox(height: 16),

              // Lien de bascule
              TextButton(
                onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                child: Text(
                  _isSignUpMode
                      ? 'Déjà inscrit ? Connectez-vous'
                      : 'Nouveau ? Créez un compte ici',
                  style: const TextStyle(color: Color(0xFF2EBD69)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}