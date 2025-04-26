/*
Hidden developer screen that shows app version information and allows configuration changes
Only accessible by tapping the app title 5 consecutive times
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/config.dart';
import '../helpers/runtime_config.dart';
import '../styles/app_styles.dart';
import '../helpers/error_helper.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  // Text controller for custom URL input
  final TextEditingController _urlController = TextEditingController();

  // Selected URL from dropdown
  String? _selectedUrlKey;

  @override
  void initState() {
    super.initState();
    // Initialize with current base URL
    _urlController.text = Config.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // Update the base URL
  Future<void> _updateBaseUrl(String url) async {
    try {
      await RuntimeConfig().setBaseUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base URL updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update Base URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Reset to default base URL
  Future<void> _resetBaseUrl() async {
    try {
      await RuntimeConfig().resetBaseUrl();

      setState(() {
        _urlController.text = RuntimeConfig.defaultBaseUrl;
        _selectedUrlKey = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base URL reset to default'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset Base URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get environment name for a URL if it exists in the presets
  String? _getEnvironmentName(String url) {
    // Find the entry in availableBaseUrls where the value matches the URL
    final entry = RuntimeConfig.availableBaseUrls.entries
        .firstWhere(
          (entry) => entry.value == url,
          orElse: () => const MapEntry<String, String>('', ''),
        );

    // Return the key (environment name) if found, otherwise null
    return entry.key.isNotEmpty ? entry.key : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Mode'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: AppStyles.backgroundColor,
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App version display
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.developer_mode,
                      size: 48,
                      color: AppStyles.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SplitLeague',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version: ${Config.appVersion}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Build timestamp hidden but preserved in code
                    // const SizedBox(height: 8),
                    // Text(
                    //   'Build: ${Config.buildTimestamp}',
                    //   style: const TextStyle(
                    //     fontSize: 14,
                    //     color: Colors.grey,
                    //   ),
                    //   textAlign: TextAlign.center,
                    // ),
                  ],
                ),
              ),

              // Base URL configuration
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Base URL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current base URL display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show environment name if available
                          if (_getEnvironmentName(Config.baseUrl) != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.label, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getEnvironmentName(Config.baseUrl)!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Show the URL
                          Row(
                            children: [
                              const Icon(Icons.link, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Config.baseUrl,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Preset URLs dropdown
                    const Text(
                      'Select Preset URL:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedUrlKey,
                      isExpanded: true, // Make dropdown take full width
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      hint: const Text('Select a preset URL'),
                      items: RuntimeConfig.availableBaseUrls.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          // Use a single Text widget with the key as the display
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _selectedUrlKey = value;
                            _urlController.text = RuntimeConfig.availableBaseUrls[value]!;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Custom URL input
                    const Text(
                      'Custom URL:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Enter custom base URL',
                        prefixIcon: const Icon(Icons.edit),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _urlController.clear();
                          },
                        ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Reset button
                        OutlinedButton.icon(
                          onPressed: _resetBaseUrl,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset to Default'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),

                        // Apply button
                        ElevatedButton.icon(
                          onPressed: () {
                            _updateBaseUrl(_urlController.text);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Apply'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Exit button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Exit Developer Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
