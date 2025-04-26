import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/fixture_card.dart';
import '../widgets/error_display.dart';
import '../styles/app_styles.dart';

class FixturesTabContent extends StatelessWidget {
  final bool isCreator;
  final bool isLoadingFixtures;
  final bool isLoadingMembers;
  final bool isGeneratingFixtures;
  final List<Map<String, dynamic>> fixtures;
  final List<Map<String, dynamic>> filteredFixtures;
  final List<Map<String, dynamic>> leagueMembers;
  final String? filterPlayerId;
  final String? filterPlayerName;
  final String? filterPlayedStatus;
  final String? generateErrorMessage;
  final String? fixturesErrorMessage;
  final String? membersErrorMessage;
  final String? successMessage;
  final int? fixturesCount;
  final int? lastUpdatedFixtureId;
  final ScrollController? scrollController;

  final Function() onGenerateFixtures;
  final Function() onLoadFixtures;
  final Function(BuildContext) onShowFilterMenu;
  final Function(Map<String, dynamic>) onNavigateToUpdateScore;
  final Function(int, String) onRemovePlayerFromLeague;
  final Function() onClearFilter;
  final Function(String)? onApplyPlayedStatusFilter;
  final Function()? onClearPlayedStatusFilter;

  const FixturesTabContent({
    super.key,
    required this.isCreator,
    required this.isLoadingFixtures,
    required this.isLoadingMembers,
    required this.isGeneratingFixtures,
    required this.fixtures,
    required this.filteredFixtures,
    required this.leagueMembers,
    required this.filterPlayerId,
    required this.filterPlayerName,
    this.filterPlayedStatus,
    required this.generateErrorMessage,
    required this.fixturesErrorMessage,
    required this.membersErrorMessage,
    required this.successMessage,
    required this.fixturesCount,
    this.lastUpdatedFixtureId,
    this.scrollController,
    required this.onGenerateFixtures,
    required this.onLoadFixtures,
    required this.onShowFilterMenu,
    required this.onNavigateToUpdateScore,
    required this.onRemovePlayerFromLeague,
    required this.onClearFilter,
    this.onApplyPlayedStatusFilter,
    this.onClearPlayedStatusFilter,
  });

  @override
  Widget build(BuildContext context) {
    // Use a SingleChildScrollView to make the entire content scrollable
    return SingleChildScrollView(
      controller: scrollController,
      // Add padding to ensure there's enough space at the bottom
      padding: const EdgeInsets.only(bottom: 16.0),
      // Use a unique key based on the filter status to force rebuild when filters change
      key: ValueKey('fixtures_scroll_${filterPlayedStatus ?? "all"}'),
      // Use BouncingScrollPhysics for more reliable scrolling behavior
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Generate fixtures section (only for league creator and if no fixtures exist)
        if (isCreator && fixtures.isEmpty && !isLoadingFixtures) ...[
          const Text(
            'Generate Fixtures',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'As the league organiser, you can generate fixtures for all members of the league. '
            'This will create matches based on the "Play Each Other" setting.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Generate fixtures button
          ElevatedButton.icon(
            onPressed: isGeneratingFixtures ? null : onGenerateFixtures,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.sports),
            label: isGeneratingFixtures
                ? const SpinKitThreeBounce(
                    color: Colors.white,
                    size: 24,
                  )
                : const Text('Generate Fixtures'),
          ),
          const SizedBox(height: 24),
        ],

        // Generate error message
        if (generateErrorMessage != null) ...[
          ErrorDisplay(
            message: generateErrorMessage!,
            onRetry: onGenerateFixtures,
            retryText: 'Try Again',
          ),
          const SizedBox(height: 24),
        ],

        // Success message
        if (successMessage != null) ...[
          SuccessDisplay(
            message: fixturesCount != null
              ? '$successMessage\nCreated $fixturesCount fixtures'
              : successMessage!,
          ),
          const SizedBox(height: 24),
        ],

        // Fixtures section (only shown when fixtures exist)
        if (fixtures.isNotEmpty) ...[
          // Filter controls section - unified design
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(20),
                  spreadRadius: 0,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Played status filter row - unified design
                Row(
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildFilterChip(
                                label: 'All',
                                isSelected: filterPlayedStatus == null,
                                onTap: onClearPlayedStatusFilter != null
                                  ? () => onClearPlayedStatusFilter!.call()
                                  : null,
                                isFirst: true,
                              ),
                            ),
                            Expanded(
                              child: _buildFilterChip(
                                label: 'Played',
                                isSelected: filterPlayedStatus == 'played',
                                onTap: onApplyPlayedStatusFilter != null
                                  ? () => onApplyPlayedStatusFilter!('played')
                                  : null,
                              ),
                            ),
                            Expanded(
                              child: _buildFilterChip(
                                label: 'Not Played',
                                isSelected: filterPlayedStatus == 'not_played',
                                onTap: onApplyPlayedStatusFilter != null
                                  ? () => onApplyPlayedStatusFilter!('not_played')
                                  : null,
                                isLast: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Player filter row - unified design
                Row(
                  children: [
                    const Text(
                      'Player:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Player selection button
                    Expanded(
                      child: InkWell(
                        onTap: () => onShowFilterMenu(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: filterPlayerId != null
                              ? Border.all(color: AppStyles.primaryColor, width: 1)
                              : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: filterPlayerId != null ? AppStyles.primaryColor : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  filterPlayerId != null ? (filterPlayerName ?? 'Selected Player') : 'All Players',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: filterPlayerId != null ? AppStyles.primaryColor : Colors.grey.shade700,
                                    fontWeight: filterPlayerId != null ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (filterPlayerId != null)
                                InkWell(
                                  onTap: onClearFilter,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppStyles.primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Refresh button
                    InkWell(
                      onTap: onLoadFixtures,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Fixtures error message - only show for actual errors, not just empty fixtures
        if (!isCreator && fixturesErrorMessage != null && !fixturesErrorMessage!.contains('No fixtures')) ...[
          ErrorDisplay(
            message: fixturesErrorMessage!,
            onRetry: onLoadFixtures,
          ),
          const SizedBox(height: 16),
        ],

        // Fixtures list
        if (isLoadingFixtures || isLoadingMembers)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading fixtures...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (fixtures.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCreator) ...[
                // League members section for creator
                const Text(
                  'League Members',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check that all players have joined before generating fixtures.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Show league members list
                if (leagueMembers.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leagueMembers.length,
                    itemBuilder: (context, index) {
                      final member = leagueMembers[index];
                      final bool isCreatorMember = member['is_creator'] == true;
                      final int memberId = member['id'];
                      final String memberName = member['nickname'] ?? member['name'] ?? 'Unknown Player';

                      return ListTile(
                        leading: Icon(
                          isCreatorMember ? Icons.star : Icons.person,
                          color: isCreatorMember ? Colors.amber : null,
                        ),
                        title: Text(memberName),
                        // Only show delete button for non-creator members and if current user is creator
                        trailing: isCreator && !isCreatorMember
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => onRemovePlayerFromLeague(memberId, memberName),
                                tooltip: 'Remove player',
                              )
                            : null,
                      );
                    },
                  )
                else if (membersErrorMessage != null)
                  Text(
                    membersErrorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
              ] else ...[
                // Message for non-creator members
                EmptyStateDisplay(
                  message: 'No Fixtures Yet',
                  icon: Icons.sports_soccer,
                  showPullToRefresh: false,
                ),
              ],
            ],
          )
        else if ((filterPlayerId != null || filterPlayedStatus != null) && filteredFixtures.isEmpty)
          EmptyStateDisplay(
            message: filterPlayerId != null && filterPlayedStatus != null
              ? filterPlayedStatus == 'played'
                ? 'No played fixtures found for ${filterPlayerName ?? "selected player"}'
                : 'No unplayed fixtures found for ${filterPlayerName ?? "selected player"}'
              : filterPlayerId != null
                ? 'No fixtures found for ${filterPlayerName ?? "selected player"}'
                : filterPlayedStatus == 'played'
                  ? 'No played fixtures found'
                  : 'No unplayed fixtures found',
            icon: Icons.filter_alt_off,
            actionText: filterPlayerId != null && filterPlayedStatus != null
              ? 'Clear All Filters'
              : filterPlayerId != null
                ? 'Clear Player Filter'
                : 'Clear Status Filter',
            onAction: filterPlayerId != null && filterPlayedStatus != null
              ? () {
                  onClearFilter();
                  onClearPlayedStatusFilter?.call();
                }
              : filterPlayerId != null
                ? onClearFilter
                : onClearPlayedStatusFilter != null
                  ? () => onClearPlayedStatusFilter!.call()
                  : null,
            showPullToRefresh: false,
          )
        else
          // Use a ListView.builder with shrinkWrap
          ListView.builder(
            shrinkWrap: true, // Important to avoid overflow
            physics: const ClampingScrollPhysics(), // Allow scrolling within the parent
            itemCount: (filterPlayerId != null || filterPlayedStatus != null) ? filteredFixtures.length : fixtures.length,
            itemBuilder: (context, index) {
              final fixture = (filterPlayerId != null || filterPlayedStatus != null) ? filteredFixtures[index] : fixtures[index];
              final fixtureId = fixture['id'] is int ? fixture['id'] : int.tryParse(fixture['id'].toString()) ?? 0;

              // Check if this is the fixture we need to scroll to
              if (lastUpdatedFixtureId != null && fixtureId == lastUpdatedFixtureId && scrollController != null) {
                // Use a post-frame callback to ensure the widget is built before scrolling
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Calculate approximate position (each card is about 120 pixels high)
                  // We're using a simple approximation since we're now using a SingleChildScrollView
                  final estimatedPosition = index * 120.0;

                  // Scroll to the position without animation for smoother experience
                  scrollController!.jumpTo(estimatedPosition);
                });
              }

              // Removed animation for smoother performance
              return FixtureCard(
                fixture: fixture,
                onTap: onNavigateToUpdateScore,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.horizontal(
        left: isFirst ? const Radius.circular(6) : Radius.zero,
        right: isLast ? const Radius.circular(6) : Radius.zero,
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppStyles.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(6) : Radius.zero,
            right: isLast ? const Radius.circular(6) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}



