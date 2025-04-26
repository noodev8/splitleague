/*
Show the league details
This screen shows detailed information about the league
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/details_tab_content.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_styles.dart';

class LeagueDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const LeagueDetailsScreen({
    super.key,
    required this.league,
  });

  @override
  State<LeagueDetailsScreen> createState() => _LeagueDetailsScreenState();
}

class _LeagueDetailsScreenState extends State<LeagueDetailsScreen> {
  // Reference to the league provider
  late LeagueProvider _leagueProvider;

  // Flag to track if we're disposing
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    // Start initialization after the first build
    Future.microtask(() {
      if (mounted) {
        _initializeLeagueProvider();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store reference to the provider without resetting it
    // This preserves filter states when navigating between screens
    _leagueProvider = Provider.of<LeagueProvider>(context, listen: false);
  }

  // Initialize the league provider with the current league
  Future<void> _initializeLeagueProvider() async {
    // Check if current user is the creator
    final userData = await AuthHelper.getUserData();
    final isCreator = userData != null &&
        widget.league['creator_id'] != null &&
        userData['id'].toString() == widget.league['creator_id'].toString();

    // Initialize the league provider
    _leagueProvider.initLeague(widget.league['league_id'], isCreator);

    // Load league info specifically
    _leagueProvider.loadLeagueInfo();
  }

  // Handle copying text to clipboard
  void _handleCopyToClipboard(String? text) {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text)).then((_) {
        if (mounted && !_isDisposing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code copied to clipboard')),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    // Mark as disposing to prevent further updates
    _isDisposing = true;
    // Don't clear the provider data to preserve filter states
    // This allows filters to persist when returning to the fixtures screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.league['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<LeagueProvider>(
        builder: (context, leagueProvider, _) {
          return Container(
            color: AppStyles.backgroundColor,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Details content
                    leagueProvider.isLoadingLeagueInfo
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : DetailsTabContent(
                          leagueInfo: leagueProvider.leagueInfo,
                          hasFixtures: leagueProvider.fixtures.isNotEmpty,
                          onCopyToClipboard: _handleCopyToClipboard,
                          formatDate: leagueProvider.formatDate,
                          getPointsTypeDisplay: leagueProvider.getPointsTypeDisplay,
                        ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

