import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';

/// Open the chat with a person (any API shape that has authUid / name / id (PTPC) / profilePhoto).
/// Name and photo ride along in the URL so a brand-new conversation can show its header before any
/// message exists.
void openChat(BuildContext context, Json person) {
  final q = Uri(queryParameters: {
    'name': '${person['name'] ?? ''}',
    'ptpc': '${person['id'] ?? ''}',
    'photo': '${person['profilePhoto'] ?? ''}',
  }).query;
  context.push('/chat/${person['authUid']}?$q');
}
