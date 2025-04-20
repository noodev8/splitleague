/*
Show the league details
This screen shows detailed information about the league
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/details_tab_content.dart';
import '../widgets/skeleton_loading.dart';
import '../helpers/auth_helper.dart';

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
    // Store reference to the provider and reset it
    _leagueProvider = Provider.of<LeagueProvider>(context, listen: false);
    // Reset the provider to allow reuse
    _leagueProvider.reset();
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
    // Clear the league provider data when leaving the screen
    _leagueProvider.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.league['name']} - Details'),
      ),
      body: Consumer<LeagueProvider>(
        builder: (context, leagueProvider, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade100,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // League name header
                    Text(
                      'League Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Details content
                    leagueProvider.isLoadingLeagueInfo
                      ? const SkeletonLeagueDetails()
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
