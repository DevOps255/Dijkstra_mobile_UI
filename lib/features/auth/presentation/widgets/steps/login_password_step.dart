import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/primary_gradient_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';
import '../auth_text_field.dart';

class LoginPasswordStep extends ConsumerStatefulWidget {
  const LoginPasswordStep({super.key});

  @override
  ConsumerState<LoginPasswordStep> createState() => _LoginPasswordStepState();
}

class _LoginPasswordStepState extends ConsumerState<LoginPasswordStep> {
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
    // Purge explicite du mot de passe de la mémoire du contrôleur
    // texte avant sa destruction.
    _controller.clear();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final notifier = ref.read(authFlowControllerProvider.notifier);
    final password = _controller.text;
    notifier.submitLoginPassword(password);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);
    final notifier = ref.read(authFlowControllerProvider.notifier);

    return AuthStepScaffold(
      title: 'Heureux de\nvous revoir.',
      subtitle: state.email,
      onBack: notifier.editEmail,
      errorMessage: state.errorMessage,
      infoMessage: state.infoMessage,
      child: AuthTextField(
        controller: _controller,
        label: 'Mot de passe',
        autofocus: true,
        obscureText: true,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => _submit(),
      ),
      footer: PrimaryGradientButton(
        label: 'Se connecter',
        isLoading: state.isLoading,
        onPressed: _controller.text.isEmpty ? null : _submit,
      ),
    );
  }
}
