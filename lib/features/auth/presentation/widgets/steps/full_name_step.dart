import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/primary_gradient_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';
import '../auth_text_field.dart';

class FullNameStep extends ConsumerStatefulWidget {
  const FullNameStep({super.key});

  @override
  ConsumerState<FullNameStep> createState() => _FullNameStepState();
}

class _FullNameStepState extends ConsumerState<FullNameStep> {
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
    ref.read(authFlowControllerProvider.notifier).submitFullName(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);
    final notifier = ref.read(authFlowControllerProvider.notifier);

    return AuthStepScaffold(
      title: 'Comment devons-nous\nvous appeler ?',
      subtitle: 'Ce nom apparaîtra sur votre ticket.',
      onBack: notifier.editEmail,
      errorMessage: state.errorMessage,
      child: AuthTextField(
        controller: _controller,
        label: 'Nom et prénom',
        autofocus: true,
        textInputAction: TextInputAction.done,
        maxLength: 100,
        autofillHints: const [AutofillHints.name],
        onSubmitted: (_) => _submit(),
      ),
      footer: PrimaryGradientButton(
        label: 'Continuer',
        onPressed: _controller.text.trim().isEmpty ? null : _submit,
      ),
    );
  }
}
