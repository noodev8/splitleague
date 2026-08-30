/*
Setting up a new league.

The screen a person reaches about ninety seconds after installing the app, and the last
one before the part that actually matters - getting other people in.

Two things were wrong with it.

First, everything was on screen at once: five cards, seven number fields, and a set of
margin-bonus rules that only mean anything in a points-scored league. A person naming
their office pool ladder had to scroll past "Lose within margin bonus" to reach the button.
The defaults were fine for almost everybody, so the settings are now behind one disclosure
and the standing screen is a name, a scoring choice, and how many times people play.

Second - and this is the more expensive one - creating a league used to end in a dialog
showing the join code, and closing it dropped you back on the dashboard. The single most
important moment in the app, the moment a league exists and needs people, ended with the
user back where they started looking at a list. Creating a league now takes you into it,
onto the player list, where inviting people is the filled button. The join code has not
gone anywhere: it is the first thing on that league's Details tab, at four times the size
it was in the dialog.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/create_league_api.dart';
import '../api/update_last_accessed_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import '../widgets/sl_button.dart';
import 'login_user_screen.dart';
import 'player_list_screen.dart';
import 'register_user_screen.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _leagueNameController = TextEditingController();

  // Win type selection
  String _selectedWinType = 'WIN'; // Default to WIN

  // Points settings
  final _winPointsController = TextEditingController(text: '1');
  final _drawPointsController = TextEditingController(text: '0');
  final _losePointsController = TextEditingController(text: '0');
  final _winMarginBonusController = TextEditingController(text: '0');
  final _loseMarginBonusController = TextEditingController(text: '0');
  final _winMarginThresholdController = TextEditingController(text: '0');
  final _playEachOtherController = TextEditingController(text: '1');

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  // Whether the scoring settings are open. Closed by default - the defaults suit
  // almost every league, and the ones they do not suit belong to somebody who will
  // go looking.
  bool _settingsOpen = false;

  // Allow code share setting
  // Always true - the Privacy Settings card that toggled this is commented out further
  // down this file, so every league is created allowing players to see the code.
  final bool _allowCodeShare = true;

  @override
  void dispose() {
    // Clean up controllers
    _leagueNameController.dispose();
    _winPointsController.dispose();
    _drawPointsController.dispose();
    _losePointsController.dispose();
    _winMarginBonusController.dispose();
    _loseMarginBonusController.dispose();
    _winMarginThresholdController.dispose();
    _playEachOtherController.dispose();
    super.dispose();
  }

  // Handle create league button press
  Future<void> _handleCreateLeague() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if user is in guest mode
    final isGuest = await AuthHelper.getUserData().then(
      (userData) => userData == null || userData['nickname'] == 'Guest',
    );

    if (isGuest) {
      // Show registration dialog for guest users
      _showGuestRegistrationDialog();
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get form values
      String leagueName = _leagueNameController.text.trim();
      String winType = _selectedWinType;

      // Get points settings
      int winPoints = int.tryParse(_winPointsController.text) ?? 0;
      int drawPoints = int.tryParse(_drawPointsController.text) ?? 0;
      int winMarginBonus = int.tryParse(_winMarginBonusController.text) ?? 0;
      int loseMarginBonus = int.tryParse(_loseMarginBonusController.text) ?? 0;
      int winMarginThreshold =
          int.tryParse(_winMarginThresholdController.text) ?? 0;
      int playEachOther = int.tryParse(_playEachOtherController.text) ?? 1;

      // Call create league API
      Map<String, dynamic> response = await CreateLeagueApi.createLeague(
        name: leagueName,
        winType: winType,
        pointsForWin: winPoints,
        pointsForDraw: drawPoints,
        pointsForWinMargin: winMarginBonus,
        pointsForCloseLoss: loseMarginBonus,
        winMarginThreshold: winMarginThreshold,
        playEachOther: playEachOther,
        allowCodeShare: _allowCodeShare,
      );

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        final league = Map<String, dynamic>.from(response['league']);
        final leagueId = league['id'];

        if (leagueId != null) {
          await UpdateLastAccessedApi.updateLastAccessed(leagueId);
        }

        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        // Straight into the new league.
        //
        // The player list is the right landing place: the league has exactly one
        // member and its whole need is people, and that screen leads with Invite.
        // It replaces this screen rather than stacking on it, so Back from inside
        // the new league returns to the dashboard and not to a filled-in form for
        // a league that already exists.
        //
        // create_league returns the row itself, so the map handed on carries the
        // share slug and the join code - nothing here has to be fetched again.
        league['league_id'] = leagueId;
        league['is_creator'] = true;
        league['has_fixtures'] = false;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PlayerListScreen(league: league),
          ),
        );
      } else {
        // Show error message with more detail
        setState(() {
          _errorMessage = ErrorHelper.getErrorMessage(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not create the league. Try again.';
        _isLoading = false;
      });
    }
  }

  // Show guest registration dialog
  void _showGuestRegistrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create an account first'),
          content: const Text(
            'From here you can create a league to track scores. '
            'Either win, lose, draw or a points system. '
            'The league appears on the dashboard and is shared amongst players.\n\n'
            'To create a league, you need to register an account or sign in. '
            'This allows you to save your leagues and access them from any device.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to login screen with a clean slate
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginUserScreen(),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to register screen with a clean slate
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const RegisterUserScreen(),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  // Each scoring type, with the one line that tells you which is yours.
  //
  // These are the same three the app has always had. What is new is that each one says
  // what it means for the table, because "Win/Lose", "Win/Draw/Lose" and "Points" told
  // you the names of the options and nothing about the choice.
  static const List<List<String>> _scoringTypes = [
    [
      'WIN',
      'Win or lose',
      'One point for the winner. Nothing for anyone else.',
    ],
    ['WDL', 'Win, draw or lose', 'Points for a win, fewer for a draw.'],
    ['PTS', 'Points scored', 'You enter the actual score of every game.'],
  ];

  void _selectWinType(String type) {
    setState(() {
      _selectedWinType = type;

      // Sensible starting points for the type just chosen. Somebody who wants
      // something else opens the settings; nobody should have to fill in a form to
      // get the obvious answer.
      switch (type) {
        case 'WIN':
          _winPointsController.text = '1';
          _drawPointsController.text = '0';
          _losePointsController.text = '0';
        case 'WDL':
          _winPointsController.text = '3';
          _drawPointsController.text = '1';
          _losePointsController.text = '0';
        case 'PTS':
          _winPointsController.text = '3';
          _drawPointsController.text = '1';
          _losePointsController.text = '0';
      }
    });
  }

  // Has the person put anything into this screen that leaving would throw away?
  // The three things they can have touched: the name, the scoring choice, and how
  // many times people play. Everything else is a default they have not seen.
  bool get _hasUnsavedDetails {
    return _leagueNameController.text.trim().isNotEmpty ||
        _selectedWinType != 'WIN' ||
        _playEachOtherController.text != '1';
  }

  // Ask before throwing the details away. Returns true if the person wants to leave.
  Future<bool> _confirmDiscard() async {
    final bool? leave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard this league?'),
            content: Text(
              'The details you have entered will not be kept.',
              style: AppType.b(AppType.body),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Discard',
                  style: TextStyle(color: AppPalette.clay),
                ),
              ),
            ],
          ),
    );

    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Going back loses everything typed so far, and the back arrow is exactly what a
    // person reaches for when they cannot see the button. Block the pop while there
    // is something to lose and ask first. This covers the app bar arrow and the
    // Android system back gesture alike. Creating a league uses pushReplacement, so
    // the successful path is not affected.
    // canPop stays false rather than being computed from the fields, because typing
    // in a text field does not rebuild this screen - a canPop worked out up here would
    // still be reading an empty name after the person had filled it in. The decision is
    // made in the callback instead, where it is read fresh. Navigator.pop() is not
    // blocked by PopScope (only maybePop is, which is what the back arrow calls), so
    // popping from in here works.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        final NavigatorState navigator = Navigator.of(context);

        // Nothing typed yet - let them straight out
        if (!_hasUnsavedDetails) {
          navigator.pop();
          return;
        }

        if (await _confirmDiscard()) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppPalette.chalk,
        appBar: AppBar(
          title: const Text('New league'),
          backgroundColor: AppPalette.surface,
          shape: const Border(bottom: BorderSide(color: AppPalette.hairline)),
        ),

        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              TextFormField(
                controller: _leagueNameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 30,
                style: AppType.t(AppType.title),
                decoration: const InputDecoration(
                  labelText: 'League name',
                  hintText: 'Thursday Pool',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Give the league a name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'HOW A GAME IS SCORED',
                  style: AppType.b(AppType.eyebrow),
                ),
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
                    for (int i = 0; i < _scoringTypes.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          color: AppPalette.hairline,
                        ),
                      _scoringOption(
                        _scoringTypes[i][0],
                        _scoringTypes[i][1],
                        _scoringTypes[i][2],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('FIXTURES', style: AppType.b(AppType.eyebrow)),
              ),

              _meetingsPicker(),

              const SizedBox(height: 24),

              _settingsDisclosure(),

              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.clayTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppType.b(
                      AppType.body,
                      color: AppPalette.clay,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // A Scaffold does NOT lift its bottomNavigationBar clear of the keyboard - it
        // only shrinks the body - so with the name field focused the keyboard sat on
        // top of 'Create league'. Padding the bar by the keyboard height makes the bar
        // taller by exactly that much, which puts the button back in view and shortens
        // the list by the same amount. See the traps section of docs/next-ui-redesign.md.
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
                label: _isLoading ? 'Creating' : 'Create league',
                busy: _isLoading,
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          FocusScope.of(context).unfocus();
                          _handleCreateLeague();
                        },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // One scoring type. The whole row is the target, and the selected one is marked
  // with a filled teal tick rather than a coloured border, so the three rows stay a
  // list of equals rather than turning into three cards of different weights.
  Widget _scoringOption(String type, String title, String detail) {
    final bool selected = _selectedWinType == type;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $detail',
      excludeSemantics: true,
      child: Material(
        color:
            selected
                ? AppPalette.tealTint.withValues(alpha: 0.5)
                : AppPalette.surface,
        child: InkWell(
          onTap: () => _selectWinType(type),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppType.b(
                          AppType.action,
                          color:
                              selected ? AppPalette.tealDeep : AppPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(detail, style: AppType.b(AppType.meta)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppPalette.teal : Colors.transparent,
                    border: Border.all(
                      color:
                          selected
                              ? AppPalette.teal
                              : AppPalette.hairlineStrong,
                      width: 1.5,
                    ),
                  ),
                  child:
                      selected
                          ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppPalette.onDark,
                          )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // How many times everyone plays everyone.
  //
  // Three buttons rather than a number field. It used to be a text box labelled
  // "Times to play each other:" that would happily accept 40, which in a league of
  // eight people is 1,120 fixtures. One, two and three cover every real league, and
  // they say what they mean in words.
  Widget _meetingsPicker() {
    final int current = int.tryParse(_playEachOtherController.text) ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Everyone plays everyone', style: AppType.b(AppType.action)),
          const SizedBox(height: 12),
          Row(
            children: [
              _meetingOption('Once', 1, current),
              const SizedBox(width: 8),
              _meetingOption('Twice', 2, current),
              const SizedBox(width: 8),
              _meetingOption('3 times', 3, current),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meetingOption(String label, int value, int current) {
    final bool selected = current == value;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected ? AppPalette.tealTint : AppPalette.chalk,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap:
                () => setState(() => _playEachOtherController.text = '$value'),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color:
                      selected
                          ? AppPalette.teal.withValues(alpha: 0.45)
                          : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.b(
                    AppType.action,
                    color: selected ? AppPalette.tealDeep : AppPalette.slate,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // The settings almost nobody changes, behind one line.
  //
  // Which settings appear depends on the scoring type, and always did - margin
  // bonuses are meaningless in a win/lose league, where every score is 1-0. What is
  // new is that a win/lose league now has nothing here at all and says so, instead of
  // showing an empty section.
  Widget _settingsDisclosure() {
    final bool hasSettings = _selectedWinType != 'WIN';
    if (!hasSettings) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _settingsOpen = !_settingsOpen),
            icon: Icon(
              _settingsOpen ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            label: Text(
              _settingsOpen ? 'Hide points settings' : 'Points settings',
              style: AppType.b(
                AppType.action,
                color: AppPalette.tealDeep,
                size: 14,
              ),
            ),
          ),
        ),

        if (_settingsOpen) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _numberSetting('Points for a win', _winPointsController),

                if (_selectedWinType == 'WDL') ...[
                  _settingDivider(),
                  _numberSetting('Points for a draw', _drawPointsController),
                ],

                if (_selectedWinType == 'PTS') ...[
                  _settingDivider(),
                  _numberSetting(
                    'The margin',
                    _winMarginThresholdController,
                    detail: 'What counts as a comfortable win',
                  ),
                  _settingDivider(),
                  _numberSetting(
                    'Bonus for winning by it',
                    _winMarginBonusController,
                  ),
                  _settingDivider(),
                  _numberSetting(
                    'Bonus for losing within it',
                    _loseMarginBonusController,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _settingDivider() => const Divider(
    height: 1,
    thickness: 1,
    indent: 16,
    color: AppPalette.hairline,
  );

  Widget _numberSetting(
    String label,
    TextEditingController controller, {
    String? detail,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppType.b(AppType.action)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail, style: AppType.b(AppType.meta, size: 12)),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 68,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppType.t(AppType.figure, size: 17),
              decoration: const InputDecoration(
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
