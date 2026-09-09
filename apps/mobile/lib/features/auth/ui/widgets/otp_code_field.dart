import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six boxes for a 6-digit OTP (brief P5 item 3): auto-advances focus as each digit is
/// typed, moves back on backspace over an empty box, and accepts a full 6-digit paste into
/// any box. Calls [onCompleted] once all six boxes are filled.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({super.key, required this.onCompleted, this.onChanged, this.length = 6});

  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final int length;

  @override
  State<OtpCodeField> createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  late final _controllers = List.generate(widget.length, (_) => TextEditingController());
  late final _focusNodes = List.generate(widget.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      // A paste landed in one box — spread its digits across the remaining boxes.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length - index && i < digits.length; i++) {
        _controllers[index + i].text = digits[i];
      }
      final lastFilled = (index + digits.length - 1).clamp(0, widget.length - 1);
      _focusNodes[lastFilled].requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    widget.onChanged?.call(_code);
    if (_code.length == widget.length) {
      widget.onCompleted(_code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < widget.length; i++)
          SizedBox(
            width: 44,
            child: Focus(
              // Wraps (doesn't replace) the TextField's own focus node, so backspace
              // bubbles up here even though the TextField itself holds literal focus.
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace &&
                    _controllers[i].text.isEmpty &&
                    i > 0) {
                  _controllers[i - 1].clear();
                  _focusNodes[i - 1].requestFocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: widget.length, // allows a full paste to land in one box
                style: AppTypography.title,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
                onChanged: (value) => _handleChanged(i, value),
              ),
            ),
          ),
      ],
    );
  }
}
