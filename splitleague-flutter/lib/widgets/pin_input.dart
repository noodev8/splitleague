/*
Custom PIN input widget for entering a 4-digit code
Used for joining leagues with a public code
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_styles.dart';

class PinInput extends StatefulWidget {
  final Function(String) onCompleted;
  final int pinLength;
  final bool autoFocus;

  // Pre-filled code, used when the screen was opened from a shared league link
  final String? initialValue;

  const PinInput({
    super.key,
    required this.onCompleted,
    this.pinLength = 4,
    this.autoFocus = true,
    this.initialValue,
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
    _controllers = List.generate(widget.pinLength, (index) => TextEditingController());
    _focusNodes = List.generate(widget.pinLength, (index) => FocusNode());
    _pin = List.generate(widget.pinLength, (index) => '');

    // Fill the boxes in if a code came from a shared link
    //
    // The value is only used when it is exactly the right length and all digits - a link with
    // rubbish in it leaves the boxes empty rather than half-filling them.
    final initial = widget.initialValue;

    if (initial != null &&
        initial.length == widget.pinLength &&
        RegExp(r'^\d+$').hasMatch(initial)) {
      for (var i = 0; i < widget.pinLength; i++) {
        _controllers[i].text = initial[i];
        _pin[i] = initial[i];
      }

      // Hand the completed code to the screen exactly as if it had been typed, so whatever
      // is waiting on it - an enabled Join button, say - is ready straight away.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCompleted(initial);
      });
    }
    
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
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppStyles.primaryColor,
            ),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppStyles.primaryColor,
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
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
