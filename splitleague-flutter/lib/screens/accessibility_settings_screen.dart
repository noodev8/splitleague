/*
Accessibility settings screen for the SplitLeague app
Allows users to customize accessibility options
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../styles/app_palette.dart';
import '../styles/app_styles.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  late AccessibilityProvider _accessibilityProvider;

  @override
  void initState() {
    super.initState();
    // Provider will be initialized in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _accessibilityProvider = Provider.of<AccessibilityProvider>(context);
  }

  Future<void> _saveSettings() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text size and contrast'),
        backgroundColor: AppPalette.surface,
        shape: const Border(bottom: BorderSide(color: AppPalette.hairline)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // High Contrast Mode
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Display',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // High Contrast Mode
                    SwitchListTile(
                      title: const Text('High Contrast Mode'),
                      subtitle: const Text(
                        'Increases contrast for better visibility',
                      ),
                      value: _accessibilityProvider.highContrast,
                      onChanged: (value) {
                        _accessibilityProvider.setHighContrast(value);
                      },
                    ),

                    // Large Text
                    SwitchListTile(
                      title: const Text('Large Text'),
                      subtitle: const Text(
                        'Increases text size throughout the app',
                      ),
                      value: _accessibilityProvider.largeText,
                      onChanged: (value) {
                        _accessibilityProvider.setLargeText(value);
                      },
                    ),

                    // Reduce Animations
                    SwitchListTile(
                      title: const Text('Reduce Animations'),
                      subtitle: const Text(
                        'Minimizes motion for users sensitive to movement',
                      ),
                      value: _accessibilityProvider.reduceAnimations,
                      onChanged: (value) {
                        _accessibilityProvider.setReduceAnimations(value);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: AppStyles.primaryButtonStyle,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // The one thing worth saying, in plain text rather than a tinted
            // box with an icon. It was the last Material blue left in the app.
            Text(
              'A few things only change after the app is closed and opened again.',
              style: AppStyles.captionStyle,
            ),
          ],
        ),
      ),
    );
  }
}
