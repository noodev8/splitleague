/*
Entering the result of one game.

This is the screen the app exists to make easy - a league is only ever as up to date as
the last person who could be bothered to open this - so it is the shortest screen in the
app and the fixture itself is the whole of it.

What it replaces. For a win/lose league the old screen showed two identical cards, each
one headed "Winner" with a trophy and a name underneath, and neither of them said what
tapping did. For a points league it showed two boxed number fields under a heading. Then
a filled indigo Submit button, an italic note about who is allowed to update scores, a
grey timestamp, and a "Void Fixture" text button.

Now the fixture is drawn the way it is drawn everywhere else in the app - two names with
the score between them - and you set the result by tapping the person who won. The names
ARE the control, so there is nothing to explain. A points league gets two number fields in
the same three-column layout, so the two kinds of league look like the same screen.

The rule about who may enter a result has not changed; what changed is that it is only
mentioned when it applies to you. It used to be an italic note shown to everybody,
including the people it was granting permission to.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../api/update_fixture_score_api.dart';
import '../api/void_fixture_api.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import '../widgets/sl_button.dart';
import '../widgets/sl_empty.dart';

class UpdateScoreScreen extends StatefulWidget {
  final Map<String, dynamic> fixture;
  final Function? onScoreUpdated;

  const UpdateScoreScreen({
    super.key,
    required this.fixture,
    this.onScoreUpdated,
  });

  @override
  State<UpdateScoreScreen> createState() => _UpdateScoreScreenState();
}

class _UpdateScoreScreenState extends State<UpdateScoreScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _player1ScoreController = TextEditingController();
  final _player2ScoreController = TextEditingController();

  // Result selection for WIN/WDL win types
  String? _selectedResult;

  // Loading states
  bool _isSubmitting = false;
  bool _isVoiding = false;

  // Error message
  String? _errorMessage;

  // Win type from the league
  String? _winType;

  // User data
  Map<String, dynamic>? _userData;

  // Authorization flags
  bool _isAuthorized = false;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    // Initialize win type from fixture data
    _winType = widget.fixture['win_type'];

    // Initialize scores if they exist
    if (widget.fixture['played'] == true) {
      if (_winType == 'PTS') {
        _player1ScoreController.text =
            widget.fixture['player_1_score']?.toString() ?? '';
        _player2ScoreController.text =
            widget.fixture['player_2_score']?.toString() ?? '';
      } else {
        // For WIN/WDL types, set the selected result based on scores
        final p1Score = widget.fixture['player_1_score'];
        final p2Score = widget.fixture['player_2_score'];

        if (p1Score == 1 && p2Score == 0) {
          _selectedResult = 'WIN_1';
        } else if (p1Score == 0 && p2Score == 1) {
          _selectedResult = 'WIN_2';
        } else if (p1Score == 1 && p2Score == 1) {
          _selectedResult = 'DRAW';
        }
      }
    }

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _userData = await AuthHelper.getUserData();

    if (mounted) {
      setState(() {
        if (_userData != null) {
          final int userId = _userData!['id'];
          final int player1Id = widget.fixture['player_1_id'];
          final int player2Id = widget.fixture['player_2_id'];
          final bool isCreator = widget.fixture['is_creator'] ?? false;

          // User is authorized if they are the league creator or one of the players
          _isAuthorized =
              isCreator || userId == player1Id || userId == player2Id;

          // Set creator flag (only league creators can void fixtures)
          _isCreator = isCreator;
        }
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _player1ScoreController.dispose();
    _player2ScoreController.dispose();
    super.dispose();
  }

  // Handle form submission
  Future<void> _handleSubmit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Set loading state
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> response;

      // Call appropriate API based on win type
      if (_winType == 'PTS') {
        // For points-based leagues, send actual scores
        final player1Score = int.parse(_player1ScoreController.text);
        final player2Score = int.parse(_player2ScoreController.text);

        response = await UpdateFixtureScoreApi.updateFixtureScore(
          widget.fixture['id'],
          player1Score,
          player2Score,
        );
      } else {
        // For WIN or WDL leagues, send the result
        if (_selectedResult == null) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Tap whoever won, or Draw.';
          });
          return;
        }

        response = await UpdateFixtureScoreApi.updateFixtureResult(
          widget.fixture['id'],
          _selectedResult!,
        );
      }

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Call onScoreUpdated callback if provided
        if (widget.onScoreUpdated != null) {
          widget.onScoreUpdated!();
        }

        // Pop screen with result=true to indicate success
        if (mounted) {
          Navigator.of(context).pop(true);
        }

        // Remove the success toast since we're already showing feedback
        // ErrorHelper.showSuccessToast(response['message'] ?? 'Score updated successfully');
      } else {
        // Show error message
        setState(() {
          _isSubmitting = false;
          _errorMessage = response['message'];
        });
      }
    } catch (e) {
      // Show error message
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Could not save that result. Try again.';
      });
    }
  }

  // Handle void fixture
  Future<void> _handleVoidFixture() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Void this game?'),
            content: const Text(
              'It stops counting towards the table for either player. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep it'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppPalette.clay),
                child: const Text('Void it'),
              ),
            ],
          ),
    );

    // If user cancels, do nothing
    if (confirm != true) {
      return;
    }

    // Set loading state
    setState(() {
      _isVoiding = true;
      _errorMessage = null;
    });

    try {
      // Call void fixture API
      final response = await VoidFixtureApi.voidFixture(widget.fixture['id']);

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Call onScoreUpdated callback if provided (to refresh fixtures list)
        if (widget.onScoreUpdated != null) {
          widget.onScoreUpdated!();
        }

        // Pop screen with result=true to indicate success
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // Show error message
        setState(() {
          _isVoiding = false;
          _errorMessage = response['message'];
        });
      }
    } catch (e) {
      // Show error message
      setState(() {
        _isVoiding = false;
        _errorMessage = 'Could not void that game. Try again.';
      });
    }
  }

  // Helper method to remove 'guest_' prefix from player names
  String _formatPlayerName(String name) {
    if (name.startsWith('guest_')) {
      return name.substring(6); // Remove 'guest_' prefix
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final String player1Name = _formatPlayerName(
      widget.fixture['player_1_nickname']?.toString().isNotEmpty == true
          ? widget.fixture['player_1_nickname'].toString()
          : (widget.fixture['player_1_name']?.toString() ?? 'Player 1'),
    );

    final String player2Name = _formatPlayerName(
      widget.fixture['player_2_nickname']?.toString().isNotEmpty == true
          ? widget.fixture['player_2_nickname'].toString()
          : (widget.fixture['player_2_name']?.toString() ?? 'Player 2'),
    );

    final bool played = widget.fixture['played'] == true;

    String? updatedDate;
    if (widget.fixture['updated_at'] != null) {
      final DateTime? date = DateTime.tryParse(
        widget.fixture['updated_at'].toString(),
      );
      if (date != null) {
        updatedDate = DateFormat('d MMM, HH:mm').format(date.toLocal());
      }
    }

    return Scaffold(
      backgroundColor: AppPalette.chalk,
      appBar: AppBar(
        // The title says what you are doing, and changes with the state of the
        // fixture, because changing a result you already entered feels different
        // from entering one for the first time.
        title: Text(played ? 'Change the result' : 'Enter the result'),
        backgroundColor: AppPalette.surface,
        shape: const Border(bottom: BorderSide(color: AppPalette.hairline)),
      ),

      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              if (_winType == 'PTS')
                _buildScoreEntry(player1Name, player2Name)
              else
                _buildWinnerChoice(player1Name, player2Name),

              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                SlError(message: _errorMessage!),
              ],

              // Only said when it applies to you. The old screen told everybody the
              // rule, including the people it was granting permission to.
              if (!_isAuthorized && _userData != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Only the organiser and the two players can enter this result.',
                  textAlign: TextAlign.center,
                  style: AppType.b(AppType.meta),
                ),
              ],

              if (played && updatedDate != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Last changed $updatedDate',
                  textAlign: TextAlign.center,
                  style: AppType.b(AppType.meta, size: 12),
                ),
              ],

              // Voiding is rare, destructive and organiser-only, so it sits at the
              // bottom in clay text rather than as a button. Same rule as the
              // destructive rows on the Details screen.
              if (_isCreator && played) ...[
                const SizedBox(height: 28),
                Center(
                  child: TextButton(
                    onPressed:
                        _isSubmitting || _isVoiding ? null : _handleVoidFixture,
                    style: TextButton.styleFrom(
                      foregroundColor: AppPalette.clay,
                    ),
                    child: Text(
                      _isVoiding ? 'Voiding' : 'Void this game',
                      style: AppType.b(
                        AppType.action,
                        color: AppPalette.clay,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // A Scaffold does NOT lift its bottomNavigationBar clear of the keyboard - it
      // only shrinks the body - so with a score field focused the number pad sat on
      // top of 'Save result'. Padding the bar by the keyboard height makes the bar
      // taller by exactly that much, which puts the button back in view. Same fix as
      // the one on the create league screen; see the traps section of
      // docs/next-ui-redesign.md.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppPalette.chalk,
          border: Border(top: BorderSide(color: AppPalette.hairline)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SlButton.primary(
              label: _isSubmitting ? 'Saving' : 'Save result',
              busy: _isSubmitting,
              onPressed:
                  _isSubmitting || _isVoiding || !_isAuthorized
                      ? null
                      : _handleSubmit,
            ),
          ),
        ),
      ),
    );
  }

  // Win or lose, and draw where the league allows it.
  //
  // You tap the person who won. The name is the control, which is why there is no
  // instruction anywhere on this screen - the old one needed the word "Winner" printed
  // twice because two identical cards could not say what they were for.
  Widget _buildWinnerChoice(String player1Name, String player2Name) {
    // Only a win/draw/lose league can end in a draw. Offering it in a win/lose
    // league would be offering a result the table cannot represent.
    final bool allowsDraw = _winType == 'WDL';

    return Column(
      children: [
        Text('WHO WON?', style: AppType.b(AppType.eyebrow)),
        const SizedBox(height: 14),

        // IntrinsicHeight, not CrossAxisAlignment.stretch. This row sits in a
        // ListView, so its incoming height is unbounded, and asking two children to
        // stretch to fill an unbounded height is an assertion rather than a layout.
        // IntrinsicHeight measures the taller of the two names first, so a one-line
        // name and a two-line one still produce two tiles of the same height.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _winnerTile(player1Name, 'WIN_1')),
              const SizedBox(width: 10),
              Expanded(child: _winnerTile(player2Name, 'WIN_2')),
            ],
          ),
        ),

        if (allowsDraw) ...[
          const SizedBox(height: 10),
          _winnerTile('Neither — it was a draw', 'DRAW', wide: true),
        ],
      ],
    );
  }

  // One choice. Filled teal when it is the answer, plain white when it is not -
  // the same primary/secondary weighting as the buttons, so a selected answer reads
  // as the committed one.
  Widget _winnerTile(String label, String value, {bool wide = false}) {
    final bool selected = _selectedResult == value;
    final bool enabled = _isAuthorized;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppPalette.teal : AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? () => setState(() => _selectedResult = value) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: wide ? 16 : 28,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppPalette.teal : AppPalette.hairline,
                width: selected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.t(
                  wide ? AppType.titleSmall : AppType.title,
                  color: selected ? AppPalette.onDark : AppPalette.ink,
                  size: wide ? 15 : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A points league: the scoreline, with the numbers typed in.
  //
  // Laid out in the same three columns as every other scoreline in the app - name,
  // score, name - so entering a result looks like the row it is about to become.
  Widget _buildScoreEntry(String player1Name, String player2Name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.hairline),
      ),
      child: Column(
        children: [
          Text('THE SCORE', style: AppType.b(AppType.eyebrow)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _scoreField(player1Name, _player1ScoreController),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 34),
                child: Text(
                  '–',
                  style: AppType.t(AppType.score, color: AppPalette.slate),
                ),
              ),
              Expanded(
                child: _scoreField(player2Name, _player2ScoreController),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreField(String name, TextEditingController controller) {
    return Column(
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.b(AppType.name),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 96,
          child: TextFormField(
            controller: controller,
            enabled: _isAuthorized,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppType.t(AppType.score, size: 30),
            decoration: const InputDecoration(
              hintText: '0',
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
            maxLength: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Needed';
              if (int.tryParse(value.trim()) == null) return 'Numbers only';
              return null;
            },
          ),
        ),
      ],
    );
  }
}
