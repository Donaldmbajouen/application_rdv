import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:line_icons/line_icons.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Bienvenue dans RDV Manager",
          body: "Gérez facilement vos rendez-vous professionnels avec une interface intuitive et moderne.",
          image: _buildImage(LineIcons.calendar, Colors.blue),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Gestion des clients",
          body: "Créez des fiches clients complètes avec historique des rendez-vous et préférences personnalisées.",
          image: _buildImage(LineIcons.users, Colors.green),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Calendrier intelligent",
          body: "Visualisez vos rendez-vous en un coup d'œil et évitez automatiquement les conflits de planning.",
          image: _buildImage(LineIcons.calendarCheck, Colors.orange),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Notifications et rappels",
          body: "Recevez des notifications automatiques et envoyez des rappels à vos clients.",
          image: _buildImage(LineIcons.bell, Colors.purple),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Statistiques détaillées",
          body: "Suivez vos revenus, votre fréquentation et identifiez vos clients les plus fidèles.",
          image: _buildImage(LineIcons.pieChart, Colors.red),
          decoration: _getPageDecoration(),
        ),
      ],
      onDone: () => _onDone(context),
      onSkip: () => _onDone(context),
      showSkipButton: true,
      skip: const Text('Passer', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Commencer', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(22.0, 10.0),
        activeColor: Theme.of(context).primaryColor,
        color: Colors.black26,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }

  Widget _buildImage(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(40),
      child: Icon(
        icon,
        size: 120,
        color: color,
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 18,
        color: Colors.black54,
      ),
      imagePadding: EdgeInsets.only(top: 40),
      pageColor: Colors.white,
    );
  }

  void _onDone(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
