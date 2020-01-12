import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:git_touch/models/theme.dart';
import 'package:git_touch/widgets/label.dart';
import 'package:provider/provider.dart';
import '../utils/utils.dart';
import 'comment_item.dart';

class TimelineEventItem extends StatelessWidget {
  final String actor;
  final IconData iconData;
  final Color iconColor;
  final TextSpan textSpan;
  final item;

  TimelineEventItem({
    this.actor,
    this.iconData = Octicons.octoface,
    this.iconColor = Colors.grey,
    this.textSpan,
    this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeModel>(context);

    return Row(
      children: <Widget>[
        SizedBox(width: 6),
        Icon(iconData, color: iconColor, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: theme.palette.text, fontSize: 16),
              children: [
                // TODO: actor is null
                createUserSpan(context, actor),
                textSpan,
                // TextSpan(text: ' ' + TimeAgo.formatFromString(item['createdAt']))
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TimelineItem extends StatelessWidget {
  final Map<String, dynamic> payload;
  final Function(String emojiKey, bool isRemove) onReaction;

  TimelineItem(this.payload, {@required this.onReaction});

  TextSpan _buildReviewText(BuildContext context, item) {
    switch (item['state']) {
      case 'APPROVED':
        return TextSpan(text: ' approved these changes');
      case 'COMMENTED':
        return TextSpan(text: ' reviewed ');
      default:
        return warningSpan;
    }
  }

  InlineSpan _buildLabel(p) {
    return WidgetSpan(
      child: Label(
        name: p['label']['name'],
        cssColor: p['label']['color'],
      ),
    );
  }

  Widget _buildByType(BuildContext context, String type) {
    final theme = Provider.of<ThemeModel>(context);

    var defaultItem = TimelineEventItem(
      actor: '',
      iconData: Octicons.octoface,
      textSpan: TextSpan(children: [
        TextSpan(text: 'Woops, $type type not implemented yet'),
      ]),
      item: payload,
    );

    switch (type) {
      // common types
      case 'Commit':
        return TimelineEventItem(
          actor: payload['author']['user'] == null
              ? null
              : payload['author']['user']['login'],
          iconData: Octicons.git_commit,
          textSpan: TextSpan(children: [
            TextSpan(text: ' added commit '),
            TextSpan(text: payload['oid'].substring(0, 8))
          ]),
          item: payload,
        );
      case 'IssueComment':
        return CommentItem(payload, onReaction: onReaction);
      case 'CrossReferencedEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.primitive_dot,
          iconColor: GithubPalette.open,
          textSpan: TextSpan(
              text: ' referenced this on #' +
                  payload['source']['number'].toString()),
          item: payload,
        );
      case 'ClosedEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.circle_slash,
          iconColor: GithubPalette.closed,
          textSpan: TextSpan(text: ' closed this '),
          item: payload,
        );

      case 'ReopenedEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.primitive_dot,
          iconColor: GithubPalette.open,
          textSpan: TextSpan(text: ' reopened this '),
          item: payload,
        );
      case 'SubscribedEvent':
      case 'UnsubscribedEvent':
        return defaultItem; // TODO:
      case 'ReferencedEvent':
        // TODO: isCrossRepository
        if (payload['commit'] == null) {
          return Container();
        }

        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.bookmark,
          textSpan: TextSpan(children: [
            TextSpan(text: ' referenced this pull request from commit '),
            TextSpan(text: payload['commit']['oid'].substring(0, 8)),
          ]),
          item: payload,
        );
      case 'AssignedEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.key,
          textSpan: TextSpan(children: [
            TextSpan(text: ' assigned this to '),
            TextSpan(text: payload['user']['login'])
          ]),
          item: payload,
        );
      case 'UnassignedEvent':
        return defaultItem; // TODO:
      case 'LabeledEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.tag,
          textSpan: TextSpan(children: [
            TextSpan(text: ' added '),
            _buildLabel(payload),
            TextSpan(text: ' label'),
          ]),
          item: payload,
        );
      case 'UnlabeledEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.tag,
          textSpan: TextSpan(children: [
            TextSpan(text: ' removed '),
            _buildLabel(payload),
            TextSpan(text: ' label'),
          ]),
          item: payload,
        );

      case 'MilestonedEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.milestone,
          textSpan: TextSpan(children: [
            TextSpan(text: ' added this to '),
            TextSpan(text: payload['milestoneTitle']),
            TextSpan(text: ' milestone'),
          ]),
          item: payload,
        );
      case 'DemilestonedEvent':
        return defaultItem; // TODO:
      case 'RenamedTitleEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.pencil,
          textSpan: TextSpan(children: [
            TextSpan(text: ' changed the title '),
            TextSpan(
              text: payload['previousTitle'],
              style: TextStyle(decoration: TextDecoration.lineThrough),
            ),
            TextSpan(text: ' to '),
            TextSpan(text: payload['currentTitle'])
          ]),
          item: payload,
        );
      case 'LockedEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.lock,
          textSpan: TextSpan(children: [
            TextSpan(text: ' locked this conversation '),
          ]),
          item: payload,
        );
      case 'UnlockedEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.key,
          textSpan: TextSpan(children: [
            TextSpan(text: ' unlocked this conversation '),
          ]),
          item: payload,
        );

      // issue only types
      case 'TransferredEvent':
        return defaultItem; // TODO:

      // pull request only types
      case 'CommitCommentThread':
        return defaultItem; // TODO:
      case 'PullRequestReview':
        return TimelineEventItem(
          actor: payload['author']['login'],
          iconColor: GithubPalette.open,
          iconData: Octicons.check,
          textSpan: _buildReviewText(context, payload),
          item: payload,
        );
      case 'PullRequestReviewThread':
      case 'PullRequestReviewComment':
        return defaultItem; // TODO:
      case 'MergedEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.git_merge,
          iconColor: GithubPalette.merged,
          textSpan: TextSpan(children: [
            TextSpan(text: ' merged commit '),
            TextSpan(text: payload['commit']['oid'].substring(0, 8)),
            TextSpan(text: ' into '),
            TextSpan(text: payload['mergeRefName']),
          ]),
          item: payload,
        );
      case 'DeployedEvent':
      case 'DeploymentEnvironmentChangedEvent':
        return defaultItem; // TODO:
      case 'HeadRefDeletedEvent':
        return TimelineEventItem(
          actor: payload['actor']['login'],
          iconData: Octicons.git_branch,
          textSpan: TextSpan(children: [
            TextSpan(text: ' deleted the '),
            TextSpan(text: payload['headRefName']),
            TextSpan(text: ' branch'),
          ]),
          item: payload,
        );
      case 'HeadRefRestoredEvent':
      case 'HeadRefForcePushedEvent':
        return TimelineEventItem(
          iconData: Octicons.repo_force_push,
          actor: payload['actor']['login'],
          textSpan: TextSpan(
            children: [
              TextSpan(text: ' force-pushed the '),
              WidgetSpan(
                  child: PrimerBranchName(
                      payload['pullRequest']['headRef']['name'])),
              TextSpan(text: ' branch from '),
              TextSpan(
                text:
                    (payload['beforeCommit']['oid'] as String).substring(0, 7),
                style: TextStyle(color: theme.palette.primary),
              ),
              TextSpan(text: ' to '),
              TextSpan(
                text: (payload['afterCommit']['oid'] as String).substring(0, 7),
                style: TextStyle(color: theme.palette.primary),
              ),
            ],
          ),
          item: payload,
        );
      case 'BaseRefForcePushedEvent':
        return defaultItem; // TODO:
      case 'ReviewRequestedEvent':
        return TimelineEventItem(
          iconData: Octicons.eye,
          actor: payload['actor']['login'],
          textSpan: TextSpan(children: [
            TextSpan(text: ' requested a review from '),
            createUserSpan(context, payload['requestedReviewer']['login']),
          ]),
          item: payload,
        );
      case 'ReviewRequestRemovedEvent':
      case 'ReviewDismissedEvent':
        return defaultItem; // TODO:
      default:
        return defaultItem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = payload['__typename'] as String;

    Widget widget = Container(
      padding: CommonStyle.padding,
      child: _buildByType(context, type),
    );

    if (type == 'PullRequestReview') {
      final comments = payload['comments']['nodes'] as List;
      if (comments.isNotEmpty) {
        widget = Column(
          children: <Widget>[
            widget,
            Container(
              padding: CommonStyle.padding.copyWith(left: 50),
              child: Column(
                  children: comments.map((v) {
                return CommentItem(v, onReaction: (_, __) {});
              }).toList()),
            ),
          ],
        );
      }
    }

    return widget;
  }
}
