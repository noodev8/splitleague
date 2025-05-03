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
import 'fixtures_screen.dart';
import 'standings_screen.dart';
import 'dashboard_screen.dart';
import 'player_list_screen.dart';

class LeagueDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> league;
  final bool? hasFixtures; // Optional parameter to avoid the visual flip

  const LeagueDetailsScreen({
    super.key,
    required this.league,
    this.hasFixtures, // Pass this from the previous screen if known
  });

  @override
  State<LeagueDetailsScreen> createState() => _LeagueDetailsScreenState();
}

class _LeagueDetailsScreenState extends State<LeagueDetailsScreen> {
  // Reference to the league provider
  late LeagueProvider _leagueProvider;

  // Flag to track if we're disposing
  bool _isDisposing = false;

  // Flag to track if fixtures exist - initialized with the passed parameter if available
  bool _hasFixtures = false;

  @override
  void initState() {
    super.initState();

    // Initialize hasFixtures from widget parameter if provided
    if (widget.hasFixtures != null) {
      _hasFixtures = widget.hasFixtures!;
    }

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

    // Load fixtures and update hasFixtures state if not already set from widget parameter
    if (widget.hasFixtures == null) {
      _leagueProvider.loadFixtures().then((_) {
        if (mounted && !_isDisposing) {
          setState(() {
            _hasFixtures = _leagueProvider.fixtures.isNotEmpty;
          });
        }
      });
    }
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

  // Handle editing league name
  void _handleEditLeagueName(String newName) {
    if (mounted && !_isDisposing) {
      _leagueProvider.updateLeagueName(context, newName);
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
        title: Consumer<LeagueProvider>(
          builder: (context, provider, _) => Text(
            provider.isLoadingLeagueInfo
                ? widget.league['name']
                : provider.leagueInfo['name'] ?? widget.league['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF005F8A), // Top color from logo gradient
                Color(0xFF00B3A4), // Bottom color from logo gradient
              ],
            ),
          ),
        ),
      ),
      body: Consumer<LeagueProvider>(
        builder: (context, leagueProvider, _) {
          return Container(
            color: AppStyles.backgroundColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section with unified design
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(30),
                          spreadRadius: 0,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      children: [
                        // Navigation buttons - unified design
                        Row(
                          children: [
                            // Fixtures/Players button (depends on whether fixtures exist)
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  // Navigate to Players screen if no fixtures, otherwise to Fixtures screen
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                        _hasFixtures
                                          ? FixturesScreen(
                                              league: widget.league,
                                            )
                                          : PlayerListScreen(
                                              league: widget.league,
                                            ),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Show different icon and text based on whether fixtures exist
                                      Icon(
                                        _hasFixtures
                                          ? Icons.sports_soccer
                                          : Icons.people,
                                        color: AppStyles.primaryColor,
                                        size: 18
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _hasFixtures
                                          ? 'Fixtures'
                                          : 'Players',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppStyles.primaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Only show Standings button if fixtures exist
                            if (_hasFixtures) ...[
                              const SizedBox(width: 8),
                              // Standings button
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => StandingsScreen(
                                          league: widget.league,
                                        ),
                                        transitionDuration: Duration.zero,
                                        reverseTransitionDuration: Duration.zero,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.leaderboard, color: AppStyles.primaryColor, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Standings',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppStyles.primaryColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),

                            // Details label (current screen)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppStyles.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Details content - takes remaining space
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: leagueProvider.isLoadingLeagueInfo
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : SingleChildScrollView(
                            child: DetailsTabContent(
                              leagueInfo: leagueProvider.leagueInfo,
                              hasFixtures: leagueProvider.fixtures.isNotEmpty,
                              onCopyToClipboard: _handleCopyToClipboard,
                              formatDate: leagueProvider.formatDate,
                              getPointsTypeDisplay: leagueProvider.getPointsTypeDisplay,
                              onEditLeagueName: _handleEditLeagueName,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}






