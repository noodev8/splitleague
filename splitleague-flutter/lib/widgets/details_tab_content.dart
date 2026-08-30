/*
The body of the Details screen.

Three blocks, in the order somebody needs them:

  1. The join code, while it still works. It is the biggest thing on the screen and it
     is set in the display face with wide tracking, because it is a code somebody is
     about to read out loud or type into another phone. It disappears the moment the
     league starts, which is correct - the code stops working then.

  2. What the league is: who runs it, how points work, when it started. A definition
     list of label and value, not five rows of tinted icon tiles.

  3. Organiser controls, in a section headed ORGANISER so that a member never wonders
     why they cannot see them. Ordinary controls first, the two that destroy data last
     and in clay.

What is gone: five icon tiles in blue-tinted squares, six "points card" rows each in its
own tinted blue box with its own white icon tile, and four full-width filled blue buttons.
The points rules are now a plain two-column list, which is how a rules table is written
everywhere else in the world.
*/

import 'package:flutter/material.dart';
import '../helpers/share_helper.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import 'sl_action_row.dart';
import 'sl_button.dart';

class DetailsTabContent extends StatelessWidget {
  final Map<String, dynamic> leagueInfo;
  final bool hasFixtures;
  final Function(String?) onCopyToClipboard;
  final String Function(String?) formatDate;
  final String Function(String?) getPointsTypeDisplay;
  final Function(String)? onEditLeagueName;
  final Function()? onResetScores;
  final Function()? onResetLeague;
  final Function()? onCopyLeague;
  final Function()? onViewMembers;
  final String? organizerNotes;

  const DetailsTabContent({
    super.key,
    required this.leagueInfo,
    required this.hasFixtures,
    required this.onCopyToClipboard,
    required this.formatDate,
    required this.getPointsTypeDisplay,
    this.onEditLeagueName,
    this.onResetScores,
    this.onResetLeague,
    this.onCopyLeague,
    this.onViewMembers,
    this.organizerNotes,
  });

  bool get _isCreator => leagueInfo['is_creator'] == true;

  // Share the league's public page.
  //
  // The message wording and the link are built by ShareHelper, so this and every other
  // share entry point in the app send exactly the same thing.
  Future<void> _shareLeague(BuildContext context) async {
    await ShareHelper.shareLeague(
      shareSlug: leagueInfo['share_slug']?.toString(),
      name: leagueInfo['name']?.toString(),
      hasFixtures: hasFixtures,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The code is only shown before the league starts, and only to people entitled to
    // hand it out. Both conditions were already here and both are right - the code
    // stops working at kick-off, so showing it afterwards would be a promise the
    // server does not keep.
    final bool showCode =
        !hasFixtures &&
        (_isCreator || leagueInfo['allow_code_share'] == true) &&
        leagueInfo['public_code'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCode) _buildJoinCode(context),

        // Before a league starts, getting people in is the whole job, so inviting
        // is the one filled button on the screen. Afterwards nobody can join, and
        // sharing becomes a quieter thing you do with a finished table - so it
        // steps down to the icon in the header and this button goes away.
        if (!hasFixtures) ...[
          const SizedBox(height: 20),
          SlButton.primary(
            label: 'Invite players',
            icon: Icons.person_add_alt,
            onPressed: () => _shareLeague(context),
          ),
        ],

        _buildAbout(context),
        _buildRules(),
        _buildOrganiserSection(),

        const SizedBox(height: 8),
      ],
    );
  }

  // The join code.
  //
  // It used to be a small blue chip tucked to the right of the league name, easy to
  // miss on the screen whose whole purpose at that moment is to get people in. It is
  // now the first thing, at the size of something meant to be read aloud.
  Widget _buildJoinCode(BuildContext context) {
    final String code = leagueInfo['public_code'].toString();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Semantics(
        button: true,
        label: 'Join code $code. Tap to copy it.',
        excludeSemantics: true,
        child: Material(
          color: AppPalette.tealTint,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onCopyToClipboard(code),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JOIN CODE',
                          style: AppType.b(
                            AppType.eyebrow,
                            color: AppPalette.tealDeep,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          code,
                          style: AppType.t(
                            AppType.display,
                            color: AppPalette.ink,
                            size: 34,
                          ).copyWith(letterSpacing: 6),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.copy, size: 18, color: AppPalette.tealDeep),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Who runs it, how it scores, when it started, and any note left for you.
  Widget _buildAbout(BuildContext context) {
    final String? note =
        (organizerNotes != null && organizerNotes!.isNotEmpty)
                // A guest cannot read their own note - guests are placeholders managed by
                // the organiser, not people holding this phone.
                &&
                !(leagueInfo['user_nickname'] != null &&
                    leagueInfo['user_nickname'].toString().startsWith('guest_'))
            ? organizerNotes
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('THIS LEAGUE', style: AppType.b(AppType.eyebrow)),
        ),

        Container(
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _fact(
                'Name',
                leagueInfo['name']?.toString() ?? 'Unknown',
                // Renaming is an organiser's edit of their own content, so it is a
                // pencil beside the value rather than a row of its own.
                onEdit:
                    _isCreator && onEditLeagueName != null
                        ? () => _showEditNameDialog(context)
                        : null,
              ),
              _divider(),
              _fact(
                'Organiser',
                leagueInfo['created_by_nickname']?.toString() ??
                    leagueInfo['created_by']?.toString() ??
                    'Unknown',
              ),
              _divider(),
              _fact(
                'Scoring',
                getPointsTypeDisplay(leagueInfo['win_type']?.toString()),
              ),
              _divider(),
              _fact(
                'Created',
                formatDate(leagueInfo['created_at']?.toString()),
              ),

              if (note != null) ...[
                _divider(),
                _fact(
                  _isCreator ? 'Your note' : 'Note from the organiser',
                  note,
                  wrap: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // How points work in this league.
  //
  // Rows that are always zero are dropped. A Win/Lose league has no draw points and
  // usually no margin bonus, and printing "Win margin bonus  0" tells nobody anything
  // except that the app does not know what matters.
  Widget _buildRules() {
    final String? winType = leagueInfo['win_type']?.toString();

    final List<Widget> rows = [];

    void rule(String label, dynamic value, {bool always = false}) {
      final int number = _asInt(value) ?? 0;
      if (number == 0 && !always) return;

      if (rows.isNotEmpty) rows.add(_divider());
      rows.add(_fact(label, '$number'));
    }

    // The points for a win are always shown, even at zero - they are the basis of
    // the whole table, so their absence would be a question rather than a silence.
    rule('Win', leagueInfo['points_for_win'], always: true);
    if (winType == 'WDL') {
      rule('Draw', leagueInfo['points_for_draw'], always: true);
    }
    rule(
      'Bonus for winning by the margin',
      leagueInfo['points_for_win_margin'],
    );
    rule(
      'Bonus for losing within the margin',
      leagueInfo['points_for_close_loss'],
    );
    rule('The margin', leagueInfo['win_margin_threshold']);

    final int meetings = _asInt(leagueInfo['play_each_other']) ?? 1;
    if (rows.isNotEmpty) rows.add(_divider());
    rows.add(
      _fact(
        'Everyone plays everyone',
        meetings == 1 ? 'Once' : (meetings == 2 ? 'Twice' : '$meetings times'),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('POINTS', style: AppType.b(AppType.eyebrow)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: rows),
        ),
      ],
    );
  }

  // The organiser's controls.
  //
  // Ordinary things first, then the two that destroy data. The dangerous pair are
  // rows in clay text, not filled buttons - see sl_action_row.dart.
  Widget _buildOrganiserSection() {
    if (!_isCreator) return const SizedBox.shrink();

    final List<Widget> rows = [];

    if (onViewMembers != null) {
      rows.add(
        SlActionRow(
          label: 'Players and notes',
          icon: Icons.group_outlined,
          onTap: onViewMembers,
        ),
      );
    }

    if (hasFixtures && onCopyLeague != null) {
      rows.add(
        SlActionRow(
          label: 'Start a new season',
          detail: 'Copies the players and the scoring into a fresh league',
          icon: Icons.copy_all_outlined,
          onTap: onCopyLeague,
        ),
      );
    }

    if (hasFixtures && onResetScores != null) {
      rows.add(
        SlActionRow(
          label: 'Clear all results',
          detail: 'Keeps the fixtures, empties every score',
          icon: Icons.backspace_outlined,
          onTap: onResetScores,
          destructive: true,
        ),
      );
    }

    if (hasFixtures && onResetLeague != null) {
      rows.add(
        SlActionRow(
          label: 'Reset the league',
          detail: 'Deletes every fixture and score, and reopens it for players',
          icon: Icons.restart_alt,
          onTap: onResetLeague,
          destructive: true,
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return SlSection(eyebrow: 'Organiser', topGap: 26, children: rows);
  }

  // One label-and-value row.
  Widget _fact(
    String label,
    String value, {
    VoidCallback? onEdit,
    bool wrap = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment:
            wrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 128,
            child: Text(label, style: AppType.b(AppType.meta)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppType.b(AppType.value),
              maxLines: wrap ? 6 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                size: 17,
                color: AppPalette.tealDeep,
              ),
              tooltip: 'Rename this league',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              padding: EdgeInsets.zero,
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    thickness: 1,
    indent: 16,
    color: AppPalette.hairline,
  );

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Rename the league.
  void _showEditNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: leagueInfo['name']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename this league'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'League name'),
            maxLength: 30,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();

                if (newName.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Give the league a name')),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();

                if (newName != leagueInfo['name']) {
                  onEditLeagueName?.call(newName);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
