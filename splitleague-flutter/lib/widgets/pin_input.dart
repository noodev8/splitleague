/*
Custom PIN input widget for entering a 4-digit code
Used for joining leagues with a public code somebody was told out loud

This widget is structurally four boxes, so it is ONLY for the typed route. Somebody who arrives
from a shared link is identified by a ten character share slug and is never shown code boxes at
all - see join_league_screen.dart. It briefly gained an initialValue for pre-filling a code out
of a link; that has gone, because a link no longer carries a code to pre-fill.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';

class PinInput extends StatefulWidget {
  final Function(String) onCompleted;
  final int pinLength;
  final bool autoFocus;

  const PinInput({
    super.key,
    required this.onCompleted,
    this.pinLength = 4,
    this.autoFocus = true,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _pin;

  @override
  void initState() {
    super.initState();

    // Initialize controllers, focus nodes, and pin values
    _controllers = List.generate(
      widget.pinLength,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.pinLength, (index) => FocusNode());
    _pin = List.generate(widget.pinLength, (index) => '');

    // Auto-focus the first field if enabled
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      });
    }
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Check if all fields are filled
  bool _isPinComplete() {
    for (var digit in _pin) {
      if (digit.isEmpty) {
        return false;
      }
    }
    return true;
  }

  // Get the complete PIN as a string
  String _getPin() {
    return _pin.join();
  }

  // Handle digit change
  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Update the pin value
      setState(() {
        _pin[index] = value;
      });

      // Move to next field if not the last one
      if (index < widget.pinLength - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        // Last field, check if PIN is complete
        if (_isPinComplete()) {
          // Call the callback with the complete PIN
          widget.onCompleted(_getPin());
        }
      }
    } else {
      // Clear the pin value
      setState(() {
        _pin[index] = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.pinLength,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 62,
          height: 68,
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.hairline),
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            // A join code is read off a phone screen and typed into another one,
            // so it gets the display face at the size the code is shown at on the
            // Details screen. The two now look like the same thing.
            style: AppType.t(AppType.score, size: 26),
            decoration: InputDecoration(
              counterText: '',
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.teal, width: 2),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              _onDigitChanged(value, index);
            },
            onSubmitted: (value) {
              if (_isPinComplete()) {
                widget.onCompleted(_getPin());
              }
            },
            onEditingComplete: () {
              if (_isPinComplete()) {
                widget.onCompleted(_getPin());
              }
            },
            onTap: () {
              // Select all text when tapped
              _controllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controllers[index].text.length,
              );
            },
          ),
        ),
      ),
    );
  }
}
