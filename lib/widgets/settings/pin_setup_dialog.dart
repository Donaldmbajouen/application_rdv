import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog pour configurer ou modifier le code PIN
class PinSetupDialog extends StatefulWidget {
  final String? currentPin;
  final bool isSetup; // true = création, false = modification

  const PinSetupDialog({
    super.key,
    this.currentPin,
    this.isSetup = true,
  });

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _currentController = TextEditingController();
  final _pinFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _currentFocus = FocusNode();

  bool _showCurrentPin = false;
  bool _showNewPin = false;
  bool _showConfirmPin = false;
  String? _errorMessage;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus sur le premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isSetup) {
        _pinFocus.requestFocus();
      } else {
        _currentFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _currentController.dispose();
    _pinFocus.dispose();
    _confirmFocus.dispose();
    _currentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lock,
            color: colors.primary,
          ),
          const SizedBox(width: 8),
          Text(widget.isSetup ? 'Configurer le PIN' : 'Modifier le PIN'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isSetup) ...[
              Text(
                'PIN actuel',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildPinField(
                controller: _currentController,
                focusNode: _currentFocus,
                isPassword: !_showCurrentPin,
                hintText: 'Entrez votre PIN actuel',
                onToggleVisibility: () => setState(() => _showCurrentPin = !_showCurrentPin),
                onSubmitted: (_) => _pinFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.isSetup ? 'Nouveau PIN' : 'Nouveau PIN',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildPinField(
              controller: _pinController,
              focusNode: _pinFocus,
              isPassword: !_showNewPin,
              hintText: 'Entrez un PIN à 4-6 chiffres',
              onToggleVisibility: () => setState(() => _showNewPin = !_showNewPin),
              onSubmitted: (_) => _confirmFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirmer le PIN',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildPinField(
              controller: _confirmController,
              focusNode: _confirmFocus,
              isPassword: !_showConfirmPin,
              hintText: 'Confirmez votre PIN',
              onToggleVisibility: () => setState(() => _showConfirmPin = !_showConfirmPin),
              onSubmitted: (_) => _validateAndSubmit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: colors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildSecurityTips(theme, colors),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isValidating ? null : _validateAndSubmit,
          child: _isValidating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isSetup ? 'Créer' : 'Modifier'),
        ),
      ],
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isPassword,
    required String hintText,
    required VoidCallback onToggleVisibility,
    required ValueChanged<String> onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: IconButton(
          icon: Icon(isPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onFieldSubmitted: onSubmitted,
      onChanged: (_) => _clearError(),
    );
  }

  Widget _buildSecurityTips(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: colors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Conseils de sécurité',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...const [
            '• Utilisez 4 à 6 chiffres',
            '• Évitez les séquences simples (1234, 0000)',
            '• Ne partagez jamais votre PIN',
            '• Changez-le régulièrement',
          ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  tip,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _validateAndSubmit() async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      // Validation du PIN actuel si modification
      if (!widget.isSetup) {
        if (_currentController.text.isEmpty) {
          throw 'Veuillez entrer votre PIN actuel';
        }
        if (_currentController.text != widget.currentPin) {
          throw 'PIN actuel incorrect';
        }
      }

      // Validation du nouveau PIN
      final newPin = _pinController.text;
      if (newPin.isEmpty) {
        throw 'Veuillez entrer un PIN';
      }
      if (newPin.length < 4) {
        throw 'Le PIN doit contenir au moins 4 chiffres';
      }
      if (newPin.length > 6) {
        throw 'Le PIN ne peut pas dépasser 6 chiffres';
      }

      // Vérification des séquences simples
      if (_isWeakPin(newPin)) {
        throw 'PIN trop simple. Évitez les séquences ou répétitions';
      }

      // Confirmation du PIN
      if (_confirmController.text != newPin) {
        throw 'La confirmation ne correspond pas au PIN';
      }

      // Simuler un délai de validation
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(newPin);
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isValidating = false;
      });
    }
  }

  bool _isWeakPin(String pin) {
    // Vérifier les répétitions (0000, 1111, etc.)
    if (pin.split('').toSet().length == 1) {
      return true;
    }

    // Vérifier les séquences croissantes (1234, 2345, etc.)
    bool isSequence = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i - 1]) + 1) {
        isSequence = false;
        break;
      }
    }
    if (isSequence) return true;

    // Vérifier les séquences décroissantes (4321, 5432, etc.)
    isSequence = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i - 1]) - 1) {
        isSequence = false;
        break;
      }
    }
    if (isSequence) return true;

    // PINs communs à éviter
    const commonPins = ['1234', '0000', '1111', '1212', '2020', '2021', '2022', '2023', '2024'];
    if (commonPins.contains(pin)) {
      return true;
    }

    return false;
  }
}

/// Widget pour la vérification du PIN
class PinVerificationDialog extends StatefulWidget {
  final String correctPin;
  final String title;
  final String subtitle;

  const PinVerificationDialog({
    super.key,
    required this.correctPin,
    this.title = 'Vérification PIN',
    this.subtitle = 'Entrez votre PIN pour continuer',
  });

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  bool _showPin = false;
  String? _errorMessage;
  int _attemptCount = 0;
  static const int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lock,
            color: colors.primary,
          ),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subtitle,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pinController,
            focusNode: _pinFocus,
            obscureText: !_showPin,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              hintText: 'PIN',
              suffixIcon: IconButton(
                icon: Icon(_showPin ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _showPin = !_showPin),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onFieldSubmitted: (_) => _verifyPin(),
            onChanged: (_) => _clearError(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: colors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_attemptCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Tentatives restantes: ${_maxAttempts - _attemptCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _verifyPin,
          child: const Text('Vérifier'),
        ),
      ],
    );
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _verifyPin() {
    final enteredPin = _pinController.text;

    if (enteredPin.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre PIN');
      return;
    }

    if (enteredPin == widget.correctPin) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _attemptCount++;
      if (_attemptCount >= _maxAttempts) {
        _errorMessage = 'Trop de tentatives. Accès refusé.';
        // Fermer avec échec après un délai
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(false);
          }
        });
      } else {
        _errorMessage = 'PIN incorrect';
        _pinController.clear();
        _pinFocus.requestFocus();
      }
    });
  }
}

/// Utilitaires pour les PINs
class PinUtils {
  /// Affiche le dialog de configuration de PIN
  static Future<String?> showSetupDialog(
    BuildContext context, {
    String? currentPin,
    bool isSetup = true,
  }) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinSetupDialog(
        currentPin: currentPin,
        isSetup: isSetup,
      ),
    );
  }

  /// Affiche le dialog de vérification de PIN
  static Future<bool> showVerificationDialog(
    BuildContext context, {
    required String correctPin,
    String title = 'Vérification PIN',
    String subtitle = 'Entrez votre PIN pour continuer',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinVerificationDialog(
        correctPin: correctPin,
        title: title,
        subtitle: subtitle,
      ),
    );
    return result ?? false;
  }

  /// Génère un PIN aléatoire sécurisé
  static String generateRandomPin({int length = 4}) {
    final random = DateTime.now().millisecondsSinceEpoch;
    String pin = '';
    int seed = random;
    
    for (int i = 0; i < length; i++) {
      seed = (seed * 9301 + 49297) % 233280;
      pin += (seed % 10).toString();
    }
    
    return pin;
  }

  /// Vérifie la force d'un PIN
  static PinStrength evaluatePinStrength(String pin) {
    if (pin.length < 4) return PinStrength.tooShort;
    if (pin.length < 6) {
      if (_isWeakPin(pin)) return PinStrength.weak;
      return PinStrength.medium;
    }
    if (_isWeakPin(pin)) return PinStrength.medium;
    return PinStrength.strong;
  }

  static bool _isWeakPin(String pin) {
    // Répétitions
    if (pin.split('').toSet().length == 1) return true;
    
    // Séquences
    bool isSequence = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i - 1]) + 1) {
        isSequence = false;
        break;
      }
    }
    if (isSequence) return true;
    
    // PINs communs
    const commonPins = ['1234', '0000', '1111', '1212'];
    return commonPins.contains(pin);
  }
}

enum PinStrength { tooShort, weak, medium, strong }
