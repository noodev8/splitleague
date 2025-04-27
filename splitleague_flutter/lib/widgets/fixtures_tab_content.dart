import 'package:flutter/material.dart';
import '../widgets/fixture_card.dart';
import '../widgets/error_display.dart';
import '../styles/app_styles.dart';

class FixturesTabContent extends StatelessWidget {
  final bool isCreator;
  final bool isLoadingFixtures;
  final bool isLoadingMembers;
  final List<Map<String, dynamic>> fixtures;
  final List<Map<String, dynamic>> filteredFixtures;
  final String? filterPlayerId;
  final String? filterPlayerName;
  final String? filterPlayedStatus;
  final String? fixturesErrorMessage;
  final String? successMessage;
  final int? lastUpdatedFixtureId;
  final ScrollController? scrollController;

  final Function() onLoadFixtures;
  final Function(BuildContext) onShowFilterMenu;
  final Function(Map<String, dynamic>) onNavigateToUpdateScore;
  final Function() onClearFilter;
  final Function(String)? onApplyPlayedStatusFilter;
  final Function()? onClearPlayedStatusFilter;

  const FixturesTabContent({
    super.key,
    required this.isCreator,
    required this.isLoadingFixtures,
    required this.isLoadingMembers,
    required this.fixtures,
    required this.filteredFixtures,
    required this.filterPlayerId,
    required this.filterPlayerName,
    this.filterPlayedStatus,
    required this.fixturesErrorMessage,
    required this.successMessage,
    this.lastUpdatedFixtureId,
    this.scrollController,
    required this.onLoadFixtures,
    required this.onShowFilterMenu,
    required this.onNavigateToUpdateScore,
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
        // Success message
        if (successMessage != null) ...[
          SuccessDisplay(
            message: successMessage!,
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
        if (fixturesErrorMessage != null && !fixturesErrorMessage!.contains('No fixtures')) ...[
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
          // Message for when no fixtures exist
          EmptyStateDisplay(
            message: 'No Fixtures Yet',
            icon: Icons.sports_soccer,
            showPullToRefresh: false,
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

// Success display widget
class SuccessDisplay extends StatelessWidget {
  final String message;

  const SuccessDisplay({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Empty state display widget
class EmptyStateDisplay extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final bool showPullToRefresh;

  const EmptyStateDisplay({
    super.key,
    required this.message,
    required this.icon,
    this.actionText,
    this.onAction,
    this.showPullToRefresh = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
