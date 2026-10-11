// Sign-in, sign-up, password reset, email verification and onboarding (mirrors P2P-website /auth/*).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../ui/icons.dart';
import '../../ui/kit.dart';
import '../../ui/sheets.dart';
import 'session.dart';

const _hero = 'https://images.unsplash.com/photo-1485846234645-a62644f84728?crop=entropy&cs=srgb&fm=jpg&w=1080&q=80';

/// Busy flag + error toast around an async action. Returns true on success.
/// "Continue with Google" (Android / iOS). New people go on to "Complete your profile".
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).signInWithGoogle();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, tone: Tone.error);
    } catch (e) {
      debugPrint('google sign-in failed: $e');
      if (mounted) toast(context, 'Google sign-in did not work. Please try again.', tone: Tone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => kIsWeb
      ? const SizedBox.shrink()
      : AppButton(
          'Continue with Google',
          variant: BtnVariant.secondary,
          loading: _busy,
          icon: const Icon(Icons.g_mobiledata, size: 28, color: C.onSurface),
          onPressed: _go,
        );
}

mixin _Busy<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  bool busy = false;

  Future<bool> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, tone: Tone.error);
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

/// Scrollable, width-capped form page with the standard header.
class _FormPage extends StatelessWidget {
  const _FormPage({required this.title, this.subtitle, required this.children, this.showBack = true});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppHeader(showBack: showBack),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(S.xl),
          child: Constrained(
            maxWidth: 460,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title.toUpperCase(), style: T.display),
                if (subtitle != null) Padding(padding: const EdgeInsets.only(top: S.xs), child: Text(subtitle!, style: T.body.muted)),
                const SizedBox(height: S.xl),
                ...children,
              ],
            ),
          ),
        ),
      );
}

const _gap = SizedBox(height: S.md);

// ───── Splash ─────

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreachable = ref.watch(sessionProvider).status == SessionStatus.unreachable;
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const BrandMark(size: 96),
          const SizedBox(height: S.md),
          Text('PITCH TO PICTURE', style: T.display.size(28).gold),
          Text('Where vision meets screens', style: T.caption.muted.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 28),
          if (unreachable) ...[
            Text('Could not reach the server.', style: T.body.muted),
            const SizedBox(height: S.md),
            AppButton('Retry', fullWidth: false, onPressed: () => ref.read(sessionProvider.notifier).bootstrap()),
          ] else
            const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: C.muted)),
        ]),
      ),
    );
  }
}

// ───── Login ─────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with _Busy {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return toast(context, 'Enter your email and password', tone: Tone.error);
    run(() => ref.read(sessionProvider.notifier).login(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: Stack(children: [
        SizedBox(
          height: h * 0.55,
          width: double.infinity,
          child: const Stack(fit: StackFit.expand, children: [NetImage(_hero), Scrim(from: Color(0x4D0A0A0A), to: C.surface)]),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.all(S.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - S.xl * 2),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Constrained(
                    maxWidth: 460,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        if (context.canPop()) ...[CircleIconButton(icon: PhosphorIconsRegular.caretLeft, onTap: () => context.pop()), const SizedBox(width: S.md)],
                        const BrandMark(size: 28),
                        const SizedBox(width: S.sm),
                        Text('PITCH TO PICTURE', style: T.caption.gold.copyWith(letterSpacing: 2)),
                      ]),
                      const SizedBox(height: S.sm),
                      Text('WELCOME BACK', style: T.hero),
                      const SizedBox(height: S.xs),
                      Text('Sign in to pitch your film and build your team.', style: T.body.muted),
                      const SizedBox(height: S.xl),
                      AutofillGroup(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          AppInput(
                            label: 'Email',
                            controller: _email,
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            capitalization: TextCapitalization.none,
                            autofillHints: const [AutofillHints.email],
                          ),
                          _gap,
                          AppInput(
                            label: 'Password',
                            controller: _password,
                            hint: 'Your password',
                            obscure: true,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _submit(),
                          ),
                        ]),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text('Forgot password?', style: T.label.gold)),
                      ),
                      AppButton('Log In', loading: busy, onPressed: _submit),
                      const SizedBox(height: S.sm),
                      const GoogleSignInButton(),
                      const SizedBox(height: S.md),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('New to Pitch To Picture? ', style: T.body.muted),
                        GestureDetector(onTap: () => context.go('/signup'), child: Text('Sign up', style: T.body.gold.semi)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ───── Signup ─────

/// The website's password rules (checked as you type).
const _passwordRules = <(String, String)>[
  ('At least 8 characters', r'.{8,}'),
  ('An uppercase letter', r'[A-Z]'),
  ('A lowercase letter', r'[a-z]'),
  ('A number', r'\d'),
  ('A special character', r'[^A-Za-z0-9]'),
];

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> with _Busy {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _passes(String pattern) => RegExp(pattern).hasMatch(_password.text);

  void _submit() {
    if ([_name, _email, _password].any((c) => c.text.trim().isEmpty)) return toast(context, 'Please fill in all fields', tone: Tone.error);
    if (!_passwordRules.every((r) => _passes(r.$2))) return toast(context, 'Your password needs to meet every rule below', tone: Tone.error);
    run(() => ref.read(sessionProvider.notifier).register(name: _name.text, email: _email.text, password: _password.text));
  }

  @override
  Widget build(BuildContext context) => _FormPage(
        title: 'Join the vision',
        subtitle: 'Create your account to submit scripts and join film teams.',
        children: [
          AppInput(label: 'Full Name', controller: _name, hint: 'Your name', capitalization: TextCapitalization.words, autofillHints: const [AutofillHints.name]),
          _gap,
          AppInput(
            label: 'Email',
            controller: _email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            capitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
          ),
          _gap,
          AppInput(
            label: 'Password',
            controller: _password,
            hint: 'Create a strong password',
            obscure: true,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: S.sm),
          for (final (label, pattern) in _passwordRules)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                Icon(_passes(pattern) ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.checkCircle, size: 15, color: _passes(pattern) ? C.success : C.muted),
                const SizedBox(width: S.sm),
                Text(label, style: T.caption.col(_passes(pattern) ? C.onSurface3 : C.muted)),
              ]),
            ),
          const SizedBox(height: S.lg),
          AppButton('Create Account', loading: busy, onPressed: _submit),
          const SizedBox(height: S.sm),
          const GoogleSignInButton(),
          const SizedBox(height: S.md),
          Text('By signing up you agree to our Terms and Privacy Policy.', style: T.caption.muted, textAlign: TextAlign.center),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: () => context.push('/legal/terms'), child: Text('Terms', style: T.label.gold)),
            TextButton(onPressed: () => context.push('/legal/privacy'), child: Text('Privacy', style: T.label.gold)),
          ]),
          Center(child: TextButton(onPressed: () => context.go('/login'), child: Text('Already have an account? Log in', style: T.body.gold))),
        ],
      );
}

// ───── Forgot password ─────

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> with _Busy {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty) return toast(context, 'Enter your email', tone: Tone.error);
    if (await run(() => ref.read(sessionProvider.notifier).forgotPassword(_email.text))) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) => _FormPage(
        title: 'Reset password',
        subtitle: _sent ? 'If an account exists for that email, we have sent a reset link. It expires in 1 hour.' : "We'll email you a link to choose a new password.",
        children: [
          if (!_sent) ...[
            AppInput(label: 'Email', controller: _email, hint: 'you@example.com', keyboardType: TextInputType.emailAddress, capitalization: TextCapitalization.none, onSubmitted: (_) => _submit()),
            const SizedBox(height: S.lg),
            AppButton('Send Reset Link', loading: busy, onPressed: _submit),
          ] else
            AppButton('Back to log in', variant: BtnVariant.secondary, onPressed: () => context.go('/login')),
        ],
      );
}

// ───── Verify email ─────

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> with _Busy {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  // Sign-up already emailed the first code; this sends a fresh one.
  Future<void> _send() async {
    if (await run(() => ref.read(sessionProvider.notifier).requestVerificationCode()) && mounted) {
      toast(context, 'New code sent. Check your inbox.', tone: Tone.success);
    }
  }

  void _submit() {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) return toast(context, 'Enter the 6-digit code', tone: Tone.error);
    run(() => ref.read(sessionProvider.notifier).confirmEmail(_code.text));
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(sessionProvider).account?.email ?? 'your email';
    return _FormPage(
      showBack: false,
      title: 'Verify your email',
      subtitle: 'Enter the 6-digit code we sent to $email',
      children: [
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          style: T.title.copyWith(letterSpacing: 10),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: '······',
            hintStyle: T.title.muted.copyWith(letterSpacing: 10),
            filled: true,
            fillColor: C.surface3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: const BorderSide(color: C.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: const BorderSide(color: C.brand)),
          ),
        ),
        const SizedBox(height: S.lg),
        AppButton('Verify', loading: busy, onPressed: _submit),
        const SizedBox(height: S.sm),
        AppButton('Resend code', variant: BtnVariant.ghost, onPressed: busy ? null : _send),
        AppButton('Use a different account', variant: BtnVariant.ghost, onPressed: () => ref.read(sessionProvider.notifier).logout()),
      ],
    );
  }
}

// ───── Onboarding ("Complete your profile") ─────

/// Profile form shared by onboarding and Edit Profile. Required like the website's onboarding:
/// phone, bio, city, state, country and at least one role.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key, required this.submitLabel, required this.onSaved, this.onboarding = false});
  final String submitLabel;
  final VoidCallback onSaved;
  final bool onboarding;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> with _Busy {
  late final Json _p = {...?ref.read(sessionProvider).profile};
  late final _name = TextEditingController(text: '${_p['name'] ?? ''}');
  late final _bio = TextEditingController(text: '${_p['bio'] ?? ''}');
  late final _city = TextEditingController(text: '${_p['city'] ?? ''}');
  late final _state = TextEditingController(text: '${_p['state'] ?? ''}');
  late final _experience = TextEditingController(text: '${_p['experience'] ?? ''}');
  late final _portfolio = TextEditingController(text: '${_p['portfolioUrl'] ?? ''}');
  late final _showreel = TextEditingController(text: '${_p['showreelUrl'] ?? ''}');
  late final _instagram = TextEditingController(text: '${_p['instagramUrl'] ?? ''}');
  late final _website = TextEditingController(text: '${_p['websiteUrl'] ?? ''}');
  late final _custom = TextEditingController();
  late String _country = '${_p['country'] ?? ''}'.isEmpty ? 'India' : '${_p['country']}';
  late String _dial = _splitPhone().$1;
  late final _phone = TextEditingController(text: _splitPhone().$2);
  late final List<String> _roles = strList(_p['roles']);
  late String _photo = '${_p['profilePhoto'] ?? ''}';

  /// "+91987…" → ("+91", "987…"), using the longest dialling code that matches.
  (String, String) _splitPhone() {
    final raw = '${_p['phoneNumber'] ?? ''}'.replaceAll(' ', '');
    if (raw.isEmpty) return ('+91', '');
    final codes = {for (final c in countries) c.$2}.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final code in codes) {
      if (raw.startsWith(code)) return (code, raw.substring(code.length));
    }
    return ('+91', raw.replaceAll(RegExp(r'\D'), ''));
  }

  @override
  void dispose() {
    for (final c in [_name, _bio, _city, _state, _experience, _portfolio, _showreel, _instagram, _website, _custom, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final url = await pickAndUpload(context, ref, kind: 'profilePhoto', maxWidth: 800);
    if (url != null) setState(() => _photo = url);
  }

  void _addCustomRole() {
    final r = _custom.text.trim();
    if (r.isEmpty || _roles.contains(r)) return;
    setState(() {
      _roles.add(r);
      _custom.clear();
    });
  }

  Future<void> _submit() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_name.text.trim().isEmpty) return toast(context, 'Enter your name', tone: Tone.error);
    if (digits.length < 6) return toast(context, 'Enter a valid phone number', tone: Tone.error);
    if (_bio.text.trim().isEmpty) return toast(context, 'Tell us a little about yourself', tone: Tone.error);
    if (_city.text.trim().isEmpty || _state.text.trim().isEmpty) return toast(context, 'Enter your city and state', tone: Tone.error);
    if (_roles.isEmpty) return toast(context, 'Pick at least one role', tone: Tone.error);
    final ok = await run(() => ref.read(sessionProvider.notifier).saveProfile({
          'name': _name.text.trim(),
          'phoneNumber': '$_dial$digits',
          'bio': _bio.text.trim(),
          'city': _city.text.trim(),
          'state': _state.text.trim(),
          'country': _country,
          'roles': _roles,
          'experience': _experience.text.trim(),
          'portfolioUrl': _portfolio.text.trim(),
          'showreelUrl': _showreel.text.trim(),
          'instagramUrl': _instagram.text.trim(),
          'websiteUrl': _website.text.trim(),
          'profilePhoto': _photo,
          if (widget.onboarding) 'onboardingCompleted': true,
        }));
    if (ok) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Stack(children: [
              Avatar(url: _photo, name: _name.text, size: 96),
              const Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(radius: 15, backgroundColor: C.brand, child: Icon(PhosphorIconsRegular.camera, size: 16, color: C.onBrand)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: S.lg),
        AppInput(label: 'Full Name *', controller: _name, capitalization: TextCapitalization.words),
        _gap,
        Text('Phone Number *', style: T.label.col(C.onSurface3)),
        const SizedBox(height: S.xs),
        Row(children: [
          SizedBox(
            width: 96,
            child: SelectorField(
              placeholder: '+91',
              value: _dial,
              onTap: () async {
                final codes = {for (final c in countries) c.$2}.toList()..sort();
                final pick = await showSelectSheet(context, title: 'Country code', options: codes, labels: {for (final c in countries) c.$2: '${c.$2}  ${c.$1}'});
                if (pick != null && pick.isNotEmpty) setState(() => _dial = pick.first);
              },
            ),
          ),
          const SizedBox(width: S.sm),
          Expanded(child: AppInput(controller: _phone, hint: '9876543210', keyboardType: TextInputType.phone, maxLength: 15)),
        ]),
        _gap,
        AppInput(label: 'Bio *', controller: _bio, hint: 'Your craft, your story, what you want to make next.', multiline: true, maxLength: 500),
        _gap,
        Row(children: [
          Expanded(child: AppInput(label: 'City *', controller: _city, capitalization: TextCapitalization.words)),
          const SizedBox(width: S.md),
          Expanded(child: AppInput(label: 'State *', controller: _state, capitalization: TextCapitalization.words)),
        ]),
        _gap,
        SelectorField(
          label: 'Country *',
          placeholder: 'Select country',
          value: _country,
          onTap: () async {
            final pick = await showSelectSheet(context, title: 'Country', options: [for (final c in countries) c.$1], selected: [_country]);
            if (pick != null && pick.isNotEmpty) setState(() => _country = pick.first);
          },
        ),
        const SizedBox(height: S.lg),
        Text('Your roles *', style: T.label.col(C.onSurface3)),
        const SizedBox(height: S.sm),
        Wrap(spacing: S.sm, runSpacing: S.sm, children: [
          for (final r in {...roles, ..._roles})
            AppChip(r, selected: _roles.contains(r), onTap: () => setState(() => _roles.contains(r) ? _roles.remove(r) : _roles.add(r))),
        ]),
        const SizedBox(height: S.sm),
        Row(children: [
          Expanded(child: AppInput(controller: _custom, hint: 'Add another role (e.g. Writer)', capitalization: TextCapitalization.words, onSubmitted: (_) => _addCustomRole())),
          const SizedBox(width: S.sm),
          AppButton('Add', small: true, fullWidth: false, variant: BtnVariant.secondary, onPressed: _addCustomRole),
        ]),
        const SizedBox(height: S.lg),
        const SectionLabel('Optional'),
        AppInput(label: 'Experience', controller: _experience, hint: 'e.g. 5 years, 3 short films'),
        _gap,
        AppInput(label: 'Portfolio link', controller: _portfolio, hint: 'https://', keyboardType: TextInputType.url, capitalization: TextCapitalization.none),
        _gap,
        AppInput(label: 'Showreel link', controller: _showreel, hint: 'https://', keyboardType: TextInputType.url, capitalization: TextCapitalization.none),
        _gap,
        AppInput(label: 'Instagram', controller: _instagram, hint: 'https://instagram.com/…', keyboardType: TextInputType.url, capitalization: TextCapitalization.none),
        _gap,
        AppInput(label: 'Website', controller: _website, hint: 'https://', keyboardType: TextInputType.url, capitalization: TextCapitalization.none),
        const SizedBox(height: S.xl),
        AppButton(widget.submitLabel, loading: busy, onPressed: _submit),
      ]);
}

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _FormPage(
        showBack: false,
        title: 'Complete your profile',
        subtitle: ref.watch(sessionProvider).missing.length < 4
            ? "We've filled in what you already gave your P2P account. Check it and add the rest."
            : 'Creators see this when you apply, and it is how teams find you.',
        children: [
          ProfileForm(submitLabel: 'Finish', onboarding: true, onSaved: () => context.go('/home')),
          const SizedBox(height: S.sm),
          AppButton('Sign out', variant: BtnVariant.ghost, onPressed: () => ref.read(sessionProvider.notifier).logout()),
        ],
      );
}
