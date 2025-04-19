/*
Show the fixtures screen for a league
This screen shows fixtures, standings, and league details
Uses Provider for state management
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/tab_selector.dart';
import '../widgets/fixtures_tab_content.dart';
import '../widgets/standings_tab_content.dart';
import '../widgets/details_tab_content.dart';
import '../helpers/auth_helper.dart';
import 'update_score_screen.dart';

class FixturesScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const FixturesScreen({
    super.key,
    required this.league,
  });

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  // Selected tab index
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeLeagueProvider();
  }

  // Initialize the league provider with the current league
  Future<void> _initializeLeagueProvider() async {
    final leagueProvider = Provider.of<LeagueProvider>(context, listen: false);

    // Check if current user is the creator
    final userData = await AuthHelper.getUserData();
    final isCreator = userData != null &&
        widget.league['creator_id'] != null &&
        userData['id'].toString() == widget.league['creator_id'].toString();

    // Initialize the league provider
    leagueProvider.initLeague(widget.league['league_id'], isCreator);
  }

  // Handle tab change
  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    // Load standings if switching to standings tab
    if (index == 1) {
      final leagueProvider = Provider.of<LeagueProvider>(context, listen: false);
      if (leagueProvider.standings.isEmpty && !leagueProvider.isLoadingStandings) {
        leagueProvider.loadStandings();
      }
    }
  }

  // Navigate to update score screen
  void _navigateToUpdateScore(Map<String, dynamic> fixture) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UpdateScoreScreen(
          fixture: fixture,
          onScoreUpdated: () => true,
        ),
      ),
    );

    // If score was updated, reload fixtures and standings
    if (result == true && mounted) {
      final leagueProvider = Provider.of<LeagueProvider>(context, listen: false);
      leagueProvider.loadFixtures();
      if (_selectedTabIndex == 1) {
        leagueProvider.loadStandings();
      }
    }
  }

  // Show filter menu
  void _showFilterMenu(BuildContext context) {
    final leagueProvider = Provider.of<LeagueProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter Fixtures',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('All Fixtures'),
                onTap: () {
                  leagueProvider.clearFilter();
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: leagueProvider.leagueMembers.length,
                  itemBuilder: (context, index) {
                    final member = leagueProvider.leagueMembers[index];
                    final memberId = member['id'].toString();
                    final memberName = member['nickname'] ?? member['name'] ?? 'Unknown Player';

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(memberName),
                      onTap: () {
                        leagueProvider.applyFilter(memberId, memberName);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Clear the league provider data when leaving the screen
    Provider.of<LeagueProvider>(context, listen: false).clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the league provider
    final leagueProvider = Provider.of<LeagueProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league['name']),
      ),
      body: Container(
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
                // Tab selector
                TabSelector(
                  selectedIndex: _selectedTabIndex,
                  onTabChanged: _onTabChanged,
                ),
                const SizedBox(height: 24),

                // Tab content
                if (_selectedTabIndex == 0) // Fixtures tab
                  FixturesTabContent(
                    isCreator: leagueProvider.isCreator,
                    isLoadingFixtures: leagueProvider.isLoadingFixtures,
                    isLoadingMembers: leagueProvider.isLoadingMembers,
                    isGeneratingFixtures: leagueProvider.isGeneratingFixtures,
                    fixtures: leagueProvider.fixtures,
                    filteredFixtures: leagueProvider.filteredFixtures,
                    leagueMembers: leagueProvider.leagueMembers,
                    filterPlayerId: leagueProvider.filterPlayerId,
                    filterPlayerName: leagueProvider.filterPlayerName,
                    generateErrorMessage: leagueProvider.generateErrorMessage,
                    fixturesErrorMessage: leagueProvider.fixturesErrorMessage,
                    membersErrorMessage: leagueProvider.membersErrorMessage,
                    successMessage: leagueProvider.successMessage,
                    fixturesCount: leagueProvider.fixturesCount,
                    onGenerateFixtures: () => leagueProvider.generateFixtures(context),
                    onLoadFixtures: leagueProvider.loadFixtures,
                    onShowFilterMenu: _showFilterMenu,
                    onNavigateToUpdateScore: _navigateToUpdateScore,
                    onRemovePlayerFromLeague: (playerId, playerName) =>
                        leagueProvider.removePlayerFromLeague(context, playerId, playerName),
                    onClearFilter: leagueProvider.clearFilter,
                  )
                else if (_selectedTabIndex == 1) // Standings tab
                  StandingsTabContent(
                    isLoadingStandings: leagueProvider.isLoadingStandings,
                    standings: leagueProvider.standings,
                    standingsErrorMessage: leagueProvider.standingsErrorMessage,
                    winType: leagueProvider.leagueInfo['win_type'],
                    onLoadStandings: leagueProvider.loadStandings,
                  )
                else // Details tab
                  DetailsTabContent(
                    leagueInfo: leagueProvider.leagueInfo,
                    hasFixtures: leagueProvider.fixtures.isNotEmpty,
                    onCopyToClipboard: (text) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      Clipboard.setData(ClipboardData(text: text ?? '')).then((_) {
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Code copied to clipboard')),
                          );
                        }
                      });
                    },
                    formatDate: leagueProvider.formatDate,
                    getPointsTypeDisplay: leagueProvider.getPointsTypeDisplay,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
