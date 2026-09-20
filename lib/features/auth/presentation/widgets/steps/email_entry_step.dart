import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/primary_gradient_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';
import '../auth_text_field.dart';

class EmailEntryStep extends ConsumerStatefulWidget {
  const EmailEntryStep({super.key});

  @override
  ConsumerState<EmailEntryStep> createState() => _EmailEntryStepState();
}

class _EmailEntryStepState extends ConsumerState<EmailEntryStep> {
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
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(authFlowControllerProvider.notifier).submitEmail(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);

    return AuthStepScaffold(
      title: 'Ne ratez plus jamais\nvotre bus.',
      subtitle: 'Entrez votre email pour continuer.',
      errorMessage: state.errorMessage,
      child: AuthTextField(
        controller: _controller,
        label: 'Email',
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        onSubmitted: (_) => _submit(),
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
          return regex.hasMatch(value) ? null : 'Format d\'email invalide.';
        },
      ),
      footer: PrimaryGradientButton(
        label: 'Continuer',
        isLoading: state.isLoading,
        onPressed: _controller.text.trim().isEmpty ? null : _submit,
      ),
    );
  }
}
