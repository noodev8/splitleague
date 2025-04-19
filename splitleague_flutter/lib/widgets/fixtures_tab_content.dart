import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/fixture_card.dart';
import '../widgets/error_display.dart';
import '../widgets/skeleton_loading.dart';
import '../helpers/animation_helper.dart';

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
  final String? generateErrorMessage;
  final String? fixturesErrorMessage;
  final String? membersErrorMessage;
  final String? successMessage;
  final int? fixturesCount;

  final Function() onGenerateFixtures;
  final Function() onLoadFixtures;
  final Function(BuildContext) onShowFilterMenu;
  final Function(Map<String, dynamic>) onNavigateToUpdateScore;
  final Function(int, String) onRemovePlayerFromLeague;
  final Function() onClearFilter;

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
    required this.generateErrorMessage,
    required this.fixturesErrorMessage,
    required this.membersErrorMessage,
    required this.successMessage,
    required this.fixturesCount,
    required this.onGenerateFixtures,
    required this.onLoadFixtures,
    required this.onShowFilterMenu,
    required this.onNavigateToUpdateScore,
    required this.onRemovePlayerFromLeague,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          // Filter controls in a separate row
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                // Filter menu button
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: filterPlayerId != null ? Colors.blue : null,
                  ),
                  onPressed: () => onShowFilterMenu(context),
                  tooltip: 'Filter fixtures',
                  constraints: const BoxConstraints(
                    minWidth: 36, // Reduced from 40
                    minHeight: 36, // Reduced from 40
                  ),
                ),
                // Filter indicator with Expanded
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withAlpha(100)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            filterPlayerName ?? 'All Fixtures',
                            style: TextStyle(
                              fontSize: 12,
                              color: filterPlayerId != null ? Colors.blue : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (filterPlayerId != null) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: onClearFilter,
                            borderRadius: BorderRadius.circular(12),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onLoadFixtures,
                  tooltip: 'Refresh fixtures',
                  constraints: const BoxConstraints(
                    minWidth: 36, // Reduced from default
                    minHeight: 36, // Reduced from default
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
                  actionText: 'Refresh',
                  onAction: onLoadFixtures,
                ),
              ],
            ],
          )
        else if (filterPlayerId != null && filteredFixtures.isEmpty)
          EmptyStateDisplay(
            message: 'No fixtures found for ${filterPlayerName ?? "selected player"}',
            icon: Icons.filter_alt_off,
            actionText: 'Clear Filter',
            onAction: onClearFilter,
          )
        else
          Column(
            children: List.generate(
              (filterPlayerId != null ? filteredFixtures : fixtures).length,
              (index) {
                final fixture = (filterPlayerId != null ? filteredFixtures : fixtures)[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: FadeSlideAnimation(
                    duration: Duration(milliseconds: 400 + index * 100),
                    curve: AnimCurves.spring,
                    beginOffset: const Offset(0.0, 0.25),
                    beginOpacity: 0.0,
                    child: FixtureCard(
                      fixture: fixture,
                      onTap: onNavigateToUpdateScore,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
