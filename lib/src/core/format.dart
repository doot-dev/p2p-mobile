// Pitch To Picture constants (mirrors P2P-website/src/app/lib/constants.ts) and small formatters.

typedef Json = Map<String, dynamic>;

enum Tone { info, success, warning, error, muted, brand }

/// Preset roles; people can add their own on top of these.
const roles = ['Actor', 'Cinematographer', 'Editor', 'Music Composer', 'Production Designer', 'Assistant Director', 'Producer'];

const genres = ['Drama', 'Action', 'Comedy', 'Thriller', 'Horror', 'Romance', 'Sci-Fi', 'Documentary', 'Crime', 'Fantasy'];

/// Project lifecycle (set by the Pitch To Picture team) → badge colour, as on the website.
const projectStatuses = <String, int>{
  'Script Under Review': 0xFFF97316,
  'Script Approved': 0xFF22C55E,
  'Script Rejected': 0xFFEF4444,
  'Team Building Stage': 0xFF3B82F6,
  'Team Completed': 0xFFA855F7,
  'Ready For Trailer Submission': 0xFFEAB308,
  'Trailer Submitted': 0xFF06B6D4,
  'Under Screening': 0xFF6366F1,
  'Selected For Show': 0xFFD4AF37,
  'Confirm Participation': 0xFFD4AF37,
  'Payment Confirmed': 0xFF10B981,
  'Show Confirmed': 0xFFD4AF37,
};

/// Rejected projects are hidden from everyone but their creator and can't be edited.
bool isRejected(Json project) => project['status'] == 'Script Rejected' || project['deletedAt'] != null;

const applicationStatuses = <String, (String label, Tone tone)>{
  'Applied': ('Applied', Tone.info),
  'Shortlisted': ('Shortlisted', Tone.warning),
  'Selected': ('Hired', Tone.success),
  'Rejected': ('Not selected', Tone.error),
};

const inquiryTypes = ['General', 'Project Support', 'Technical', 'Partnership/Sponsorship', 'Payment', 'Other'];

/// The roles a project is hiring for. No list on the project means every preset role.
List<String> projectRoles(Json p) {
  final r = strList(p['requiredRoles']);
  return r.isEmpty ? roles : r;
}

/// A role is open unless the creator closed it or someone was hired for it.
bool roleOpen(Json p, String role) => (p['roleAvailability'] as Map?)?[role] != false;

String joinNonEmpty(Iterable<Object?> parts, [String sep = ', ']) =>
    parts.where((p) => p != null && '$p'.trim().isNotEmpty).join(sep);

String locationOf(Json m) => joinNonEmpty([m['city'], m['state'], m['country']]);

List<String> strList(Object? v) => v is List ? v.map((e) => '$e').toList() : const [];

String initials(String? name) =>
    (name ?? '').split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

String shortDate(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  if (d == null) return '';
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Chat timestamp in local time: "14:05" today, "3 Oct, 14:05" otherwise.
String formatTime(String? iso, {DateTime? now}) {
  final t = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  final hm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  final today = now ?? DateTime.now();
  return t.year == today.year && t.month == today.month && t.day == today.day ? hm : '${t.day} ${_monthNames[t.month - 1]}, $hm';
}

/// "2026-10-25" → "25 Oct 2026" (as typed text if it isn't a date).
String formatDate(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso);
  return d == null ? (iso ?? '') : '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
}

/// From the website (countries-list package): name + main dialling code.
const countries = <(String, String)>[
  ('Afghanistan', '+93'),
  ('Aland', '+358'),
  ('Albania', '+355'),
  ('Algeria', '+213'),
  ('American Samoa', '+1684'),
  ('Andorra', '+376'),
  ('Angola', '+244'),
  ('Anguilla', '+1264'),
  ('Antarctica', '+672'),
  ('Antigua and Barbuda', '+1268'),
  ('Argentina', '+54'),
  ('Armenia', '+374'),
  ('Aruba', '+297'),
  ('Ascension Island', '+247'),
  ('Australia', '+61'),
  ('Austria', '+43'),
  ('Azerbaijan', '+994'),
  ('Bahamas', '+1242'),
  ('Bahrain', '+973'),
  ('Bangladesh', '+880'),
  ('Barbados', '+1246'),
  ('Belarus', '+375'),
  ('Belgium', '+32'),
  ('Belize', '+501'),
  ('Benin', '+229'),
  ('Bermuda', '+1441'),
  ('Bhutan', '+975'),
  ('Bolivia', '+591'),
  ('Bonaire', '+5997'),
  ('Bosnia and Herzegovina', '+387'),
  ('Botswana', '+267'),
  ('Bouvet Island', '+47'),
  ('Brazil', '+55'),
  ('British Indian Ocean Territory', '+246'),
  ('British Virgin Islands', '+1284'),
  ('Brunei', '+673'),
  ('Bulgaria', '+359'),
  ('Burkina Faso', '+226'),
  ('Burundi', '+257'),
  ('Cabo Verde', '+238'),
  ('Cambodia', '+855'),
  ('Cameroon', '+237'),
  ('Canada', '+1'),
  ('Cayman Islands', '+1345'),
  ('Central African Republic', '+236'),
  ('Chad', '+235'),
  ('Chile', '+56'),
  ('China', '+86'),
  ('Christmas Island', '+61'),
  ('Cocos (Keeling) Islands', '+61'),
  ('Colombia', '+57'),
  ('Comoros', '+269'),
  ('Cook Islands', '+682'),
  ('Costa Rica', '+506'),
  ('Croatia', '+385'),
  ('Cuba', '+53'),
  ('Curacao', '+5999'),
  ('Cyprus', '+357'),
  ('Czechia', '+420'),
  ('Democratic Republic of the Congo', '+243'),
  ('Denmark', '+45'),
  ('Djibouti', '+253'),
  ('Dominica', '+1767'),
  ('Dominican Republic', '+1809'),
  ('East Timor', '+670'),
  ('Ecuador', '+593'),
  ('Egypt', '+20'),
  ('El Salvador', '+503'),
  ('Equatorial Guinea', '+240'),
  ('Eritrea', '+291'),
  ('Estonia', '+372'),
  ('Eswatini', '+268'),
  ('Ethiopia', '+251'),
  ('Falkland Islands', '+500'),
  ('Faroe Islands', '+298'),
  ('Fiji', '+679'),
  ('Finland', '+358'),
  ('France', '+33'),
  ('French Guiana', '+594'),
  ('French Polynesia', '+689'),
  ('French Southern Territories', '+262'),
  ('Gabon', '+241'),
  ('Gambia', '+220'),
  ('Georgia', '+995'),
  ('Germany', '+49'),
  ('Ghana', '+233'),
  ('Gibraltar', '+350'),
  ('Greece', '+30'),
  ('Greenland', '+299'),
  ('Grenada', '+1473'),
  ('Guadeloupe', '+590'),
  ('Guam', '+1671'),
  ('Guatemala', '+502'),
  ('Guernsey', '+44'),
  ('Guinea', '+224'),
  ('Guinea-Bissau', '+245'),
  ('Guyana', '+592'),
  ('Haiti', '+509'),
  ('Heard Island and McDonald Islands', '+61'),
  ('Honduras', '+504'),
  ('Hong Kong', '+852'),
  ('Hungary', '+36'),
  ('Iceland', '+354'),
  ('India', '+91'),
  ('Indonesia', '+62'),
  ('Iran', '+98'),
  ('Iraq', '+964'),
  ('Ireland', '+353'),
  ('Isle of Man', '+44'),
  ('Israel', '+972'),
  ('Italy', '+39'),
  ('Ivory Coast', '+225'),
  ('Jamaica', '+1876'),
  ('Japan', '+81'),
  ('Jersey', '+44'),
  ('Jordan', '+962'),
  ('Kazakhstan', '+7'),
  ('Kenya', '+254'),
  ('Kiribati', '+686'),
  ('Kosovo', '+377'),
  ('Kuwait', '+965'),
  ('Kyrgyzstan', '+996'),
  ('Laos', '+856'),
  ('Latvia', '+371'),
  ('Lebanon', '+961'),
  ('Lesotho', '+266'),
  ('Liberia', '+231'),
  ('Libya', '+218'),
  ('Liechtenstein', '+423'),
  ('Lithuania', '+370'),
  ('Luxembourg', '+352'),
  ('Macao', '+853'),
  ('Madagascar', '+261'),
  ('Malawi', '+265'),
  ('Malaysia', '+60'),
  ('Maldives', '+960'),
  ('Mali', '+223'),
  ('Malta', '+356'),
  ('Marshall Islands', '+692'),
  ('Martinique', '+596'),
  ('Mauritania', '+222'),
  ('Mauritius', '+230'),
  ('Mayotte', '+262'),
  ('Mexico', '+52'),
  ('Micronesia', '+691'),
  ('Moldova', '+373'),
  ('Monaco', '+377'),
  ('Mongolia', '+976'),
  ('Montenegro', '+382'),
  ('Montserrat', '+1664'),
  ('Morocco', '+212'),
  ('Mozambique', '+258'),
  ('Myanmar', '+95'),
  ('Namibia', '+264'),
  ('Nauru', '+674'),
  ('Nepal', '+977'),
  ('Netherlands', '+31'),
  ('New Caledonia', '+687'),
  ('New Zealand', '+64'),
  ('Nicaragua', '+505'),
  ('Niger', '+227'),
  ('Nigeria', '+234'),
  ('Niue', '+683'),
  ('Norfolk Island', '+672'),
  ('North Korea', '+850'),
  ('North Macedonia', '+389'),
  ('Northern Mariana Islands', '+1670'),
  ('Norway', '+47'),
  ('Oman', '+968'),
  ('Pakistan', '+92'),
  ('Palau', '+680'),
  ('Palestine', '+970'),
  ('Panama', '+507'),
  ('Papua New Guinea', '+675'),
  ('Paraguay', '+595'),
  ('Peru', '+51'),
  ('Philippines', '+63'),
  ('Pitcairn Islands', '+64'),
  ('Poland', '+48'),
  ('Portugal', '+351'),
  ('Puerto Rico', '+1787'),
  ('Qatar', '+974'),
  ('Republic of the Congo', '+242'),
  ('Reunion', '+262'),
  ('Romania', '+40'),
  ('Russia', '+7'),
  ('Rwanda', '+250'),
  ('Saint Barthelemy', '+590'),
  ('Saint Helena', '+290'),
  ('Saint Kitts and Nevis', '+1869'),
  ('Saint Lucia', '+1758'),
  ('Saint Martin', '+590'),
  ('Saint Pierre and Miquelon', '+508'),
  ('Saint Vincent and the Grenadines', '+1784'),
  ('Samoa', '+685'),
  ('San Marino', '+378'),
  ('Sao Tome and Principe', '+239'),
  ('Saudi Arabia', '+966'),
  ('Senegal', '+221'),
  ('Serbia', '+381'),
  ('Seychelles', '+248'),
  ('Sierra Leone', '+232'),
  ('Singapore', '+65'),
  ('Sint Maarten', '+1721'),
  ('Slovakia', '+421'),
  ('Slovenia', '+386'),
  ('Solomon Islands', '+677'),
  ('Somalia', '+252'),
  ('South Africa', '+27'),
  ('South Georgia and the South Sandwich Islands', '+500'),
  ('South Korea', '+82'),
  ('South Sudan', '+211'),
  ('Spain', '+34'),
  ('Sri Lanka', '+94'),
  ('Sudan', '+249'),
  ('Suriname', '+597'),
  ('Svalbard and Jan Mayen', '+4779'),
  ('Sweden', '+46'),
  ('Switzerland', '+41'),
  ('Syria', '+963'),
  ('Taiwan', '+886'),
  ('Tajikistan', '+992'),
  ('Tanzania', '+255'),
  ('Thailand', '+66'),
  ('Togo', '+228'),
  ('Tokelau', '+690'),
  ('Tonga', '+676'),
  ('Trinidad and Tobago', '+1868'),
  ('Tristan da Cunha', '+290'),
  ('Tunisia', '+216'),
  ('Türkiye', '+90'),
  ('Turkmenistan', '+993'),
  ('Turks and Caicos Islands', '+1649'),
  ('Tuvalu', '+688'),
  ('U.S. Minor Outlying Islands', '+1'),
  ('U.S. Virgin Islands', '+1340'),
  ('Uganda', '+256'),
  ('Ukraine', '+380'),
  ('United Arab Emirates', '+971'),
  ('United Kingdom', '+44'),
  ('United States', '+1'),
  ('Uruguay', '+598'),
  ('Uzbekistan', '+998'),
  ('Vanuatu', '+678'),
  ('Vatican City', '+379'),
  ('Venezuela', '+58'),
  ('Vietnam', '+84'),
  ('Wallis and Futuna', '+681'),
  ('Western Sahara', '+212'),
  ('Yemen', '+967'),
  ('Zambia', '+260'),
  ('Zimbabwe', '+263'),
];
