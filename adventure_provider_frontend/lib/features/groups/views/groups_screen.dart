import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/shell_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/home_header_status_strip.dart';
import '../controllers/group_controller.dart';
import '../data/models/group_model.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  GroupController get _gc => Get.find<GroupController>();

  final RxInt _activeTab = 0.obs;
  final TextEditingController _headerSearchCtrl = TextEditingController();
  bool _searchVisible = false;

  static const _scaffoldBg = Color(0xFFF0EDE8);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF6B7280);
  static const _primaryDark = Color(0xFF1B4332);
  static const _accent = Color(0xFF52B788);

  @override
  void initState() {
    super.initState();
    _gc.fetchMyGroups();
  }

  @override
  void dispose() {
    _headerSearchCtrl.dispose();
    super.dispose();
  }

  String? _resolveImage(String? stored) => ApiConfig.resolveMediaUrl(stored);

  List<GroupModel> _filteredGroups(List<GroupModel> groups) {
    final q = _headerSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return groups;
    return groups
        .where((g) => g.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _showCreateGroupSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final kb = MediaQuery.viewInsetsOf(modalContext).bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: kb),
          child: _CreateGroupSheet(
            onCreated: (name, description) =>
                _gc.createGroup(name, description),
          ),
        );
      },
    );
  }

  void _showJoinGroupSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final kb = MediaQuery.viewInsetsOf(modalContext).bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: kb),
          child: _JoinWithCodeSheet(
            onJoined: (code) => _gc.joinGroup(code),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GroupsGreenHeader(
              pulseDot: const _GroupsPulseDot(),
              searchVisible: _searchVisible,
              searchController: _headerSearchCtrl,
              onToggleSearch: () {
                setState(() {
                  _searchVisible = !_searchVisible;
                  if (!_searchVisible) {
                    _headerSearchCtrl.clear();
                  }
                });
              },
              onSearchChanged: (_) => setState(() {}),
              onAddTap: _showCreateGroupSheet,
            ),
            Expanded(
              child: Obx(() {
                if (_activeTab.value == 0) {
                  return _buildMyGroupsTab();
                }
                return _buildDiscoverTab();
              }),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _showCreateGroupSheet,
                        child: Ink(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _primaryDark,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryDark.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Create Group',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _showJoinGroupSheet,
                        child: Ink(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _primaryDark, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              'Join with Code',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: kSosFabScrollBottomInset - 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    final loading = _gc.isLoading.value;
    final groupsList = _gc.myGroups.toList();
    final groups = _filteredGroups(groupsList);

    if (loading && groupsList.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary.withValues(alpha: 0.85),
        ),
      );
    }

    if (groupsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off_outlined, size: 64, color: _muted.withValues(alpha: 0.65)),
            const SizedBox(height: 16),
            Text(
              'No groups yet',
              style: GoogleFonts.bebasNeue(
                fontSize: 26,
                color: _textPrimary.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join one!',
              style: GoogleFonts.poppins(fontSize: 13, color: _muted),
            ),
          ],
        ),
      );
    }

    if (groups.isEmpty && _headerSearchCtrl.text.trim().isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 52, color: _muted.withValues(alpha: 0.6)),
              const SizedBox(height: 14),
              Text(
                'No groups match your search.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: _muted),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _gc.fetchMyGroups,
      color: _accent,
      backgroundColor: Colors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GroupCard(
              group: groups[index],
              resolveImage: _resolveImage,
              onTap: () => Get.toNamed(AppRoutes.groupDetailNamed(groups[index].id)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_outlined, size: 64, color: _muted.withValues(alpha: 0.55)),
          const SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: GoogleFonts.bebasNeue(
              fontSize: 26,
              color: _textPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover groups near you',
            style: GoogleFonts.poppins(fontSize: 13, color: _muted),
          ),
        ],
      ),
    );
  }
}

// ─── Green header (Communities-style, non-collapsing) ───────────────────────

class _GroupsGreenHeader extends StatelessWidget {
  const _GroupsGreenHeader({
    required this.pulseDot,
    required this.searchVisible,
    required this.searchController,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.onAddTap,
  });

  final Widget pulseDot;
  final bool searchVisible;
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddTap;

  static const _accent = Color(0xFF52B788);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top + 8.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -18,
          right: -18,
          child: IgnorePointer(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -24,
          left: -24,
          child: IgnorePointer(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 52,
          child: IgnorePointer(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, topPad + 4, 18, searchVisible ? 14 : 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D2B1E),
                Color(0xFF1B4332),
                Color(0xFF2D6A4F),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            pulseDot,
                            const SizedBox(width: 5),
                            Text(
                              'MY GROUPS',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: _accent,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'GROUPS',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 26,
                            color: Colors.white,
                            letterSpacing: 1.3,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _OutlineHeaderIconButton(
                    icon: Icons.search_rounded,
                    onTap: onToggleSearch,
                  ),
                  const SizedBox(width: 6),
                  _OutlineHeaderIconButton(
                    icon: Icons.add,
                    onTap: onAddTap,
                  ),
                ],
              ),
              if (!searchVisible)
                HomeHeaderStatusStrip(
                  message:
                      'Invite your crew, share codes, and explore every trail together.',
                  trailingLabel: 'Together',
                  leadingIcon: Icons.groups_2_rounded,
                  leadingIconColor: _accent,
                  trailingIcon: Icons.route_rounded,
                ),
              if (searchVisible) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: TextField(
                              controller: searchController,
                              autofocus: true,
                              onChanged: onSearchChanged,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                                height: 1.25,
                              ),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.transparent,
                                isDense: true,
                                hintText: 'Search groups…',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: searchController,
                        builder: (context, _) {
                          if (searchController.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return GestureDetector(
                            onTap: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OutlineHeaderIconButton extends StatelessWidget {
  const _OutlineHeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _GroupsPulseDot extends StatefulWidget {
  const _GroupsPulseDot();

  @override
  State<_GroupsPulseDot> createState() => _GroupsPulseDotState();
}

class _GroupsPulseDotState extends State<_GroupsPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.6, end: 1.4).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF52B788),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Create Group bottom sheet (Stateful: controllers disposed safely) ───────

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet({required this.onCreated});

  final void Function(String name, String description) onCreated;

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  static const _primaryDark = Color(0xFF1B4332);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE2EDE8);
  static const _fieldFill = Color(0xFFF5F2ED);
  static const _accent = Color(0xFF52B788);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final desc = _descCtrl.text.trim();
    if (context.mounted) Navigator.of(context).pop<void>();
    widget.onCreated(name, desc);
  }

  InputDecoration _fieldDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: _muted),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _primaryDark, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Material(
          color: Colors.white,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NEW GROUP',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Create Group',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 32,
                    color: _textPrimary,
                    letterSpacing: 1.2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Give your crew a name and optional description.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _muted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _fieldDeco('Group name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                  decoration: _fieldDeco('Description (optional)'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Material(
                    color: _primaryDark,
                    borderRadius: BorderRadius.circular(999),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _submit,
                      child: Center(
                        child: Text(
                          'Create',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop<void>(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ─── Join with Code bottom sheet ─────────────────────────────────────────────

class _JoinWithCodeSheet extends StatefulWidget {
  const _JoinWithCodeSheet({required this.onJoined});

  final void Function(String inviteCode) onJoined;

  @override
  State<_JoinWithCodeSheet> createState() => _JoinWithCodeSheetState();
}

class _JoinWithCodeSheetState extends State<_JoinWithCodeSheet> {
  late final TextEditingController _codeCtrl;

  static const _primaryDark = Color(0xFF1B4332);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE2EDE8);
  static const _fieldFill = Color(0xFFF5F2ED);
  static const _accent = Color(0xFF52B788);

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _join() {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    if (context.mounted) Navigator.of(context).pop<void>();
    widget.onJoined(code);
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Material(
          color: Colors.white,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'INVITE',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join with Code',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 32,
                        color: _textPrimary,
                        letterSpacing: 1.2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the group invite code you received.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _codeCtrl,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        _UpperCaseCodeFormatter(),
                      ],
                      style: GoogleFonts.spaceMono(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: _primaryDark,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        hintText: 'CODE',
                        hintStyle: GoogleFonts.spaceMono(
                          fontSize: 18,
                          color: _muted.withValues(alpha: 0.55),
                          letterSpacing: 6,
                        ),
                        filled: true,
                        fillColor: _fieldFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(
                            color: _primaryDark,
                            width: 1.5,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: _border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Material(
                        color: _primaryDark,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: _join,
                          child: Center(
                            child: Text(
                              'Join',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop<void>(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _muted,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Group Card ─────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.resolveImage,
    required this.onTap,
  });

  final GroupModel group;
  final String? Function(String?) resolveImage;
  final VoidCallback onTap;

  static const _textPrimary = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF6B7280);
  static const _cardBorder = Color(0xFFE2EDE8);
  static const _pillGreen = Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    final url = resolveImage(group.coverImage);
    final letter =
        group.name.isNotEmpty ? group.name[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: url != null && url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                _GradientPlaceholder(letter: letter),
                            errorWidget: (_, __, ___) =>
                                _GradientPlaceholder(letter: letter),
                          )
                        : _GradientPlaceholder(letter: letter),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(fontSize: 12, color: _muted),
                      ),
                      if (group.inviteCode != null &&
                          group.inviteCode!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF52B788).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF52B788).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            group.inviteCode!,
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _pillGreen,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (group.isTrackingActive) const _LiveBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF52B788)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.bebasNeue(fontSize: 22, color: Colors.white),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF52B788).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF52B788).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2D6A4F),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'LIVE',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B4332),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
