import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/primary_gradient_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';
import '../auth_text_field.dart';

const int _kMinPasswordLength = 8;

class CreatePasswordStep extends ConsumerStatefulWidget {
  const CreatePasswordStep({super.key});

  @override
  ConsumerState<CreatePasswordStep> createState() =>
      _CreatePasswordStepState();
}

class _CreatePasswordStepState extends ConsumerState<CreatePasswordStep> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.clear();
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _controller.text.length >= _kMinPasswordLength;

  void _submit() {
    if (!_isValid) return;
    ref
        .read(authFlowControllerProvider.notifier)
        .submitSignupPassword(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);
    final notifier = ref.read(authFlowControllerProvider.notifier);

    return AuthStepScaffold(
      title: 'Choisissez un\nmot de passe.',
      subtitle: 'Au moins $_kMinPasswordLength caractères.',
      onBack: notifier.editEmail,
      errorMessage: state.errorMessage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            controller: _controller,
            label: 'Mot de passe',
            autofocus: true,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submit(),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              if (value.length < _kMinPasswordLength) {
                return 'Trop court — $_kMinPasswordLength caractères minimum.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _StrengthIndicator(password: _controller.text),
        ],
      ),
      footer: PrimaryGradientButton(
        label: 'Créer mon compte',
        isLoading: state.isLoading,
        onPressed: _isValid ? _submit : null,
      ),
    );
  }
}

class _StrengthIndicator extends StatelessWidget {
  const _StrengthIndicator({required this.password});

  final String password;

  int get _score {
    int score = 0;
    if (password.length >= _kMinPasswordLength) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  Color _colorFor(int score) {
    if (score <= 1) return AppColors.danger;
    if (score <= 2) return AppColors.warning;
    return AppColors.success;
  }

  String _labelFor(int score) {
    if (password.isEmpty) return '';
    if (score <= 1) return 'Faible';
    if (score <= 2) return 'Correct';
    return 'Solide';
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final score = _score;
    final color = _colorFor(score);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (index) {
              final active = index < score;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: active ? color : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _labelFor(score),
          style: AppTypography.bodySmall.copyWith(color: color),
        ),
      ],
    );
  }
}
