import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/fixture_card.dart';
import '../widgets/error_display.dart';
import '../widgets/skeleton_loading.dart';
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
          // Filter controls section
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Played status filter row - improved design
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(30),
                              spreadRadius: 0,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFilterChip(
                              label: 'All',
                              isSelected: filterPlayedStatus == null,
                              onTap: onClearPlayedStatusFilter != null
                                ? () {
                                    // Clear filter and force UI refresh
                                    onClearPlayedStatusFilter!.call();
                                  }
                                : null,
                              isFirst: true,
                            ),
                            _buildFilterChip(
                              label: 'Played',
                              isSelected: filterPlayedStatus == 'played',
                              onTap: onApplyPlayedStatusFilter != null
                                ? () {
                                    // Apply filter and force UI refresh
                                    onApplyPlayedStatusFilter!('played');
                                  }
                                : null,
                            ),
                            _buildFilterChip(
                              label: 'Not Played',
                              isSelected: filterPlayedStatus == 'not_played',
                              onTap: onApplyPlayedStatusFilter != null
                                ? () {
                                    // Apply filter and force UI refresh
                                    onApplyPlayedStatusFilter!('not_played');
                                  }
                                : null,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Player filter row - improved design
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(30),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Filter menu button
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onShowFilterMenu(context),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  color: filterPlayerId != null ? AppStyles.primaryColor : Colors.grey.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Player',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: filterPlayerId != null ? AppStyles.primaryColor : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Player filter indicator
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            filterPlayerId != null ? (filterPlayerName ?? 'Selected Player') : 'All Players',
                            style: TextStyle(
                              fontSize: 14,
                              color: filterPlayerId != null ? AppStyles.primaryColor : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),

                      // Clear filter button
                      if (filterPlayerId != null)
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: onClearFilter,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: AppStyles.primaryColor,
                              ),
                            ),
                          ),
                        ),

                      // Divider
                      Container(
                        height: 24,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.grey.withAlpha(100),
                      ),

                      // Refresh button
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onLoadFixtures,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.refresh,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonFixtureCard(),
                ),
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
          // Use a ListView.builder with shrinkWrap and physics to avoid Expanded
          ListView.builder(
            shrinkWrap: true, // Important to avoid overflow
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling as parent handles it
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
        left: isFirst ? const Radius.circular(18) : Radius.zero,
        right: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppStyles.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(18) : Radius.zero,
            right: isLast ? const Radius.circular(18) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}



