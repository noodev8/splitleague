/*
The message shown when there is nothing to show, and the one shown when something failed.

The app had five separate versions of this - three of them classes called
EmptyStateDisplay, in three different files, all slightly different. Every one of them
was a 64-pixel grey icon above a grey sentence, which is the standard way of apologising
for an empty screen and tells the reader nothing.

An empty screen is a moment of direction. So there is no big grey icon; there is a line
saying what will be here, and where it makes sense, the action that fills it. When there
is no action to offer, there is no button - a screen that is empty because the organiser
has not started the league yet cannot be fixed by the person reading it, and putting a
button there would be a lie.
*/

import 'package:flutter/material.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import 'sl_button.dart';

class SlEmpty extends StatelessWidget {
  // One short line. Sentence case, no full stop needed on a fragment.
  final String title;

  // Optional second line saying what will make it appear.
  final String? detail;

  final String? actionLabel;
  final VoidCallback? onAction;

  const SlEmpty({
    super.key,
    required this.title,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppType.t(AppType.titleSmall),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: AppType.b(AppType.body, color: AppPalette.slate),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SlButton.secondary(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/*
Something went wrong, in the interface's voice.

It says what failed and offers the way to try again. It does not apologise and it is
never vague about what happened - "Could not load the fixtures" tells you which thing
broke, which "Something went wrong" does not.
*/
class SlError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const SlError({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.clayTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.error_outline,
                  color: AppPalette.clay,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppType.b(
                    AppType.body,
                    color: AppPalette.clay,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: SlButton.quiet(label: retryLabel, onPressed: onRetry),
            ),
          ],
        ],
      ),
    );
  }
}
