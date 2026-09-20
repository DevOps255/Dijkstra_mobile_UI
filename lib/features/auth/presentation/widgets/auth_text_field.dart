import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Champ de texte unique pour tout le flux d'authentification.
///
/// Zéro icône — y compris pour la bascule d'affichage du mot de
/// passe, remplacée par un mot ("Afficher" / "Masquer"), conformément
/// à la consigne explicite du projet. Validation stricte via
/// [validator], fournie par chaque écran selon son besoin propre
/// (email, mot de passe, nom) plutôt qu'une regex générique ici.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.maxLength,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final int? maxLength;
  final void Function(String)? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured = widget.obscureText;
  String? _errorText;

  void _validate(String value) {
    final result = widget.validator?.call(value);
    if (result != _errorText) {
      setState(() => _errorText = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      maxLength: widget.maxLength,
      autofillHints: widget.autofillHints,
      // Désactive suggestions/autocorrection sur les champs sensibles
      // — évite qu'un clavier tiers mal configuré ne journalise ou
      // ne suggère un mot de passe en clair.
      enableSuggestions: !widget.obscureText,
      autocorrect: !widget.obscureText,
      onChanged: _validate,
      onFieldSubmitted: widget.onSubmitted,
      inputFormatters: widget.maxLength != null
          ? [LengthLimitingTextInputFormatter(widget.maxLength)]
          : null,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: _errorText,
        counterText: '',
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: widget.obscureText
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.textSecondary,
                    textStyle: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  child: Text(_obscured ? 'Afficher' : 'Masquer'),
                ),
              )
            : null,
      ),
    );
  }
}
