// Static pages from the website: Terms, Privacy, Rules (/legal/:kind), Contact and The Show.
// Copy mirrors P2P-website/src/app/{terms,privacy,rules,contact,show}/page.tsx ("Last Updated: 1st April 2026").
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../../ui/sheets.dart';
import '../auth/session.dart';

const contactEmail = 'hello@pitchtopicture.in';
const _updated = 'Last Updated: 1st April 2026';

typedef _Doc = ({String title, String intro, List<(String, String)> sections, String? outro});

const _terms = (
  title: 'Terms and Conditions',
  intro: 'Welcome to PITCH TO PICTURE PRIVATE LIMITED ("Platform", "we", "our", "us"). These Terms and Conditions ("Terms") govern your access to and use of the Pitch To Picture website, app and services.\n\nBy registering, accessing, or using the Platform, you agree to be bound by these Terms.',
  sections: [
    (
      '1. Platform overview',
      'Pitch To Picture is a structured film creation and selection platform where users can:\n• Create professional creator profiles\n• Submit film scripts and project ideas\n• Build teams using platform creators or existing registered members\n• Submit trailers for screening\n• Participate in a curated show selection process\n\nThe Platform enables collaboration and discovery but does not guarantee project success, funding, or selection.'
    ),
    (
      '2. User eligibility',
      'By using the Platform, you confirm that:\n• You are at least 18 years of age\n• OR if you are under 18 years of age ("Minor"), you are using the Platform under the supervision of a parent or legal guardian.\n• The parent or legal guardian must review and accept these Terms on behalf of the Minor.\n• The parent or legal guardian will be fully responsible for all actions, submissions, payments, and participation of the Minor.\n• The Platform may request identity verification and written consent for Minor participation at any stage.'
    ),
    (
      '3. User account and identity',
      '• Each user is assigned a unique and permanent User ID (e.g., PTPC1001).\n• User IDs cannot be changed or reassigned.\n• Each user receives a permanent profile link.\n• Users are responsible for maintaining the confidentiality of their login credentials.\n• All activity under the account is the responsibility of the user or their guardian.'
    ),
    ('4. Creator profiles', 'Users may create profiles including roles, portfolio, and professional details.\n• Information must be accurate and not misleading.\n• The Platform may remove or restrict profiles that violate policies.'),
    (
      '5. Project submission',
      'Users may submit film projects including scripts and related materials. By submitting a project, you confirm that:\n• You own or have the legal rights to the submitted content.\n• The content does not infringe any third party rights.\n• The Platform does not verify ownership and is not responsible for disputes.\n• Each project will be assigned a permanent Project ID.'
    ),
    (
      '6. Script review and approval',
      '• All submitted scripts are reviewed by the Platform.\n• The Platform may approve, reject, or request modifications.\n• Only approved projects are allowed to proceed to team building.\n• Approval does not guarantee selection for the show.'
    ),
    (
      '7. Team building',
      'After script approval, creators may build their team by hiring creators from the Platform or adding existing team members who must be registered users. The Platform does not guarantee performance or reliability of any team member.'
    ),
    (
      '8. NDA and confidentiality',
      'Users must accept a Non Disclosure Agreement (NDA) before applying to any project. By accepting the NDA, you agree not to copy, reproduce, or disclose confidential information. Violations may result in legal action.'
    ),
    ('9. Governing law', 'These Terms are governed by the laws of India. All disputes shall be subject to the jurisdiction of Thane.'),
    ('10. Contact', 'For any queries, contact: $contactEmail'),
  ],
  outro: null,
);

// TODO(client): legal review. Adapted from the website: data now lives on Pitch To Picture's own servers
// (not "Firebase infrastructure"), and the account-deletion section is required by the app stores.
const _privacy = (
  title: 'Privacy Policy',
  intro: 'PITCH TO PICTURE PRIVATE LIMITED ("Platform", "we", "our", "us") respects your privacy and is committed to protecting your personal data.\n\nThis Privacy Policy explains how we collect, use, store, and protect your information when you use our platform.',
  sections: [
    (
      '1. Information we collect',
      'We collect Personal Information (Name, Email, Phone, Location), Account Information (User ID, credentials), Professional Content (Portfolios, Scripts, Media), Application activity (Team members, NDA records), messages you send, and a push-notification token for your device.'
    ),
    ('2. How we use your information', 'We use your data to manage accounts, display professional profiles, enable collaboration, process applications, deliver messages and notifications, and ensure security compliance across the ecosystem. We do not sell your personal data.'),
    (
      '3. Data security',
      'Your data is stored on secure servers operated for Pitch To Picture. We use Google Firebase only to deliver push notifications and for Google sign-in. Scripts are private: only you and the Pitch To Picture team can open them. No system is completely secure.'
    ),
    (
      '4. Data retention and deletion',
      'We retain your data as long as your account is active or as required for legal compliance. You can delete your account at any time in Profile → Settings → Delete Account; your personal details are then removed or anonymised. We may retain certain records (such as NDA acceptances) for legal protection after deletion.'
    ),
    ('5. Contact', 'For privacy related queries, contact: $contactEmail'),
  ],
  outro: null,
);

const _rules = (
  title: 'Platform Rules',
  intro: 'These Rules and Guidelines define how users are expected to behave on the PITCH TO PICTURE PRIVATE LIMITED platform. By using the Platform, you agree to follow these rules.',
  sections: [
    ('1. Honest representation', 'All users must provide accurate information in their profile. Faking experience, credits, or misleading claims may result in account suspension.'),
    ('2. Original content only', 'Only upload scripts, trailers, or media that you own or have rights to. IP violations lead to immediate removal and legal action.'),
    ('3. Professional conduct', 'Treat all users with respect. No harassment, abuse, or discrimination based on background, gender, or religion. Professionalism is paramount.'),
  ],
  outro: 'COMMUNITY GOAL\nPitch To Picture is built to support serious creators and real filmmaking.\nRespect the process. Build honestly. Collaborate professionally.',
);

class LegalScreen extends StatelessWidget {
  const LegalScreen(this.kind, {super.key});

  /// 'terms' | 'privacy' | 'rules'
  final String kind;

  @override
  Widget build(BuildContext context) {
    final _Doc doc = switch (kind) { 'privacy' => _privacy, 'rules' => _rules, _ => _terms };
    return Scaffold(
      appBar: AppHeader(title: doc.title, onBack: () => context.popOr('/home')),
      body: ListView(padding: const EdgeInsets.all(S.lg), children: [
        Constrained(
          maxWidth: 680,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.title.toUpperCase(), style: T.display),
            const SizedBox(height: S.xs),
            Text(_updated, style: T.caption.gold),
            const SizedBox(height: S.lg),
            Text(doc.intro, style: T.body.copyWith(height: 1.6).col(C.onSurface3)),
            for (final (title, body) in doc.sections) ...[
              const SizedBox(height: S.lg),
              Text(title.toUpperCase(), style: T.subtitle.size(14).gold.copyWith(letterSpacing: 0.8)),
              const SizedBox(height: S.xs),
              Text(body, style: T.body.copyWith(height: 1.6)),
            ],
            if (doc.outro != null) ...[
              const SizedBox(height: S.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(S.lg),
                decoration: BoxDecoration(color: C.brand3, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.brand.withValues(alpha: 0.4))),
                child: Text(doc.outro!, style: T.body.copyWith(height: 1.6).col(C.onBrand3), textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: S.x2),
          ]),
        ),
      ]),
    );
  }
}

// ───── Contact ─────

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  late final Session _s = ref.read(sessionProvider);
  late final _name = TextEditingController(text: '${_s.profile?['name'] ?? _s.account?.name ?? ''}');
  late final _email = TextEditingController(text: _s.account?.email ?? '');
  late final _userId = TextEditingController(text: _s.ptpcId ?? '');
  final _projectId = TextEditingController();
  final _message = TextEditingController();
  String _type = inquiryTypes.first;
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _userId, _projectId, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) return toast(context, 'Enter your name and email', tone: Tone.error);
    if (_message.text.trim().length < 10) return toast(context, 'Tell us a bit more (at least 10 characters)', tone: Tone.error);
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      ref,
      () => ref.read(apiClientProvider).post('$ptp/contact', {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'inquiryType': _type,
        if (_userId.text.trim().isNotEmpty) 'userId': _userId.text.trim(),
        if (_projectId.text.trim().isNotEmpty) 'projectId': _projectId.text.trim(),
        'message': _message.text.trim(),
      }),
      refresh: false,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = ok != null || _sent;
    });
  }

  Widget _info(IconData icon, String title, String text, {VoidCallback? onTap}) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: C.brand),
        title: Text(title, style: T.label.muted),
        subtitle: Text(text, style: T.body.col(onTap == null ? C.onSurface : C.brand)),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppHeader(title: 'Contact Us', onBack: () => context.popOr('/home')),
        body: ListView(padding: const EdgeInsets.all(S.lg), children: [
          Constrained(
            maxWidth: 560,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('CONTACT US', style: T.display),
              const SizedBox(height: S.xs),
              Text('Our team is here to help you navigate the Pitch To Picture ecosystem.', style: T.body.muted),
              const SizedBox(height: S.md),
              _info(PhosphorIconsRegular.envelopeSimple, 'General inquiries', contactEmail, onTap: () => openExternal('mailto:$contactEmail')),
              _info(PhosphorIconsRegular.mapPin, 'Location', 'Thane, Maharashtra, India'),
              _info(PhosphorIconsRegular.clock, 'Response time', 'We typically respond within 24 to 48 hours.'),
              _info(PhosphorIconsRegular.info, 'Creator instructions', 'Please include your User ID or Project ID for faster support.'),
              const Divider(height: S.x2),
              if (_sent) ...[
                const Icon(PhosphorIconsFill.checkCircle, color: C.success, size: 48),
                const SizedBox(height: S.sm),
                Text('MESSAGE RECEIVED', style: T.display.size(20), textAlign: TextAlign.center),
                Text('Thank you. We will get back to you within 24–48 hours.', style: T.body.muted, textAlign: TextAlign.center),
                const SizedBox(height: S.lg),
                AppButton('Send another', variant: BtnVariant.outline, onPressed: () => setState(() {
                  _sent = false;
                  _message.clear();
                  _projectId.clear();
                })),
              ] else ...[
                AppInput(label: 'Name', controller: _name, capitalization: TextCapitalization.words),
                const SizedBox(height: S.md),
                AppInput(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress, capitalization: TextCapitalization.none),
                const SizedBox(height: S.md),
                SelectorField(
                  label: 'Inquiry type',
                  placeholder: 'Choose one',
                  value: _type,
                  onTap: () async {
                    final pick = await showSelectSheet(context, title: 'Inquiry type', options: inquiryTypes, selected: [_type], searchable: false);
                    if (pick != null && pick.isNotEmpty) setState(() => _type = pick.first);
                  },
                ),
                const SizedBox(height: S.md),
                Row(children: [
                  Expanded(child: AppInput(label: 'User ID (optional)', controller: _userId, hint: 'PTPC…', capitalization: TextCapitalization.characters)),
                  const SizedBox(width: S.md),
                  Expanded(child: AppInput(label: 'Project ID (optional)', controller: _projectId, hint: 'PTPP…', capitalization: TextCapitalization.characters)),
                ]),
                const SizedBox(height: S.md),
                AppInput(label: 'Message', controller: _message, multiline: true, maxLength: 5000),
                const SizedBox(height: S.lg),
                AppButton('Send message', loading: _busy, onPressed: _submit),
              ],
              const SizedBox(height: S.x2),
            ]),
          ),
        ]),
      );
}

// ───── The Show ─────

class ShowScreen extends StatelessWidget {
  const ShowScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(padding: EdgeInsets.zero, children: [
          SizedBox(
            height: 380,
            child: Stack(fit: StackFit.expand, children: [
              const NetImage('https://images.unsplash.com/photo-1507924538820-ede94a04019d?crop=entropy&cs=srgb&fm=jpg&w=1200&q=80'),
              const Scrim(from: Color(0x660A0A0A), to: C.surface),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(S.lg),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleIconButton(icon: PhosphorIconsRegular.caretLeft, onTap: () => context.popOr('/home')),
                    const Spacer(),
                    const StatusBadge('Next episode: TBD', tone: Tone.brand),
                    const SizedBox(height: S.sm),
                    Text('THE SHOWCASE', style: T.hero),
                    const SizedBox(height: S.xs),
                    Text(
                      "The world's highest stakes filmmaking stage. Creators perform live, judges decide in real-time, and award-winning movies get made.",
                      style: T.body.col(C.onSurface3),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(S.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('EPISODE ARCHIVE', style: T.display.size(20)),
              const SizedBox(height: S.md),
              _Card(
                icon: PhosphorIconsRegular.filmReel,
                title: 'Season 1: Commencing Soon',
                body: 'All eyes are on the scripts currently in review. The first episode will premiere once the official selections are finalized.',
                action: AppButton('View selection pool', variant: BtnVariant.outline, onPressed: () => context.go('/projects')),
              ),
              const SizedBox(height: S.xl),
              Text('THE JURY PANEL', style: T.display.size(20)),
              const SizedBox(height: S.md),
              const _Card(icon: PhosphorIconsRegular.usersThree, title: 'Selection in progress', body: 'The jury will be announced with the first episode.'),
              const SizedBox(height: S.x2),
            ]),
          ),
        ]),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.body, this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(S.lg),
        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 0.5)),
        child: Column(children: [
          Icon(icon, size: 36, color: C.brand),
          const SizedBox(height: S.sm),
          Text(title, style: T.subtitle, textAlign: TextAlign.center),
          const SizedBox(height: S.xs),
          Text(body, style: T.body.muted, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: S.lg), action!],
        ]),
      );
}
