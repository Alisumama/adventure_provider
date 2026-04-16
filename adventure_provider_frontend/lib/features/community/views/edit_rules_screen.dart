import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/widgets/auth_button.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../controllers/community_controller.dart';
import '../data/models/community_rule_model.dart';

class EditRulesScreen extends StatefulWidget {
  const EditRulesScreen({super.key});

  @override
  State<EditRulesScreen> createState() => _EditRulesScreenState();
}

class _EditRulesScreenState extends State<EditRulesScreen> {
  final CommunityController _c = Get.find<CommunityController>();
  final RxList<CommunityRuleModel> _localRules = <CommunityRuleModel>[].obs;

  String get _communityId => Get.arguments?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Admin guard (should also be enforced before navigation).
      final role = _c.selectedCommunity.value?.userRole;
      if (role != 'admin') {
        Get.snackbar(
          'Access denied',
          'Only admins can edit rules.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back<void>();
        return;
      }

      final sorted = _c.rules.toList()..sort((a, b) => a.order.compareTo(b.order));
      _localRules.assignAll(sorted);
    });
  }

  void _reindexOrders() {
    for (var i = 0; i < _localRules.length; i++) {
      final r = _localRules[i];
      _localRules[i] = CommunityRuleModel(
        title: r.title,
        description: r.description,
        order: i,
      );
    }
    _localRules.refresh();
  }

  void _showRuleEditor({CommunityRuleModel? existing, required void Function(CommunityRuleModel) onSave}) {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final descC = TextEditingController(text: existing?.description ?? '');

    Get.bottomSheet<void>(
      Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF444444),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existing == null ? 'Add Rule' : 'Edit Rule',
                    style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: titleC,
                    label: 'Title',
                    hint: 'Rule title',
                    prefixIcon: Icons.title,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: descC,
                    label: 'Description',
                    hint: 'Optional description',
                    prefixIcon: Icons.article_outlined,
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  AuthButton(
                    label: existing == null ? 'Add' : 'Save',
                    onPressed: () {
                      final t = titleC.text.trim();
                      if (t.isEmpty) return;
                      final d = descC.text.trim();
                      final model = CommunityRuleModel(
                        title: t,
                        description: d,
                        order: existing?.order ?? _localRules.length,
                      );
                      onSave(model);
                      Get.back<void>();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityId = _communityId;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'Edit Rules',
          style: GoogleFonts.bebasNeue(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return ReorderableListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _localRules.removeAt(oldIndex);
                  _localRules.insert(newIndex, item);
                  _reindexOrders();
                },
                children: [
                  for (var i = 0; i < _localRules.length; i++)
                    Container(
                      key: ValueKey('rule_${i}_${_localRules[i].title}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.drag_handle, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _localRules[i].title,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_localRules[i].description.trim().isNotEmpty)
                                  Text(
                                    _localRules[i].description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryLight),
                            onPressed: () {
                              final existing = _localRules[i];
                              _showRuleEditor(
                                existing: existing,
                                onSave: (updated) {
                                  _localRules[i] = updated;
                                  _reindexOrders();
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () {
                              _localRules.removeAt(i);
                              _reindexOrders();
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryLight),
                      foregroundColor: AppColors.primaryLight,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () {
                      _showRuleEditor(
                        onSave: (r) {
                          _localRules.add(r);
                          _reindexOrders();
                        },
                      );
                    },
                    child: const Text('Add Rule'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AuthButton(
                    label: 'Save Rules',
                    onPressed: () => _c.saveRules(communityId, _localRules.toList()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

