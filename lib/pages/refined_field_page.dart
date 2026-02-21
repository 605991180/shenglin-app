import 'package:flutter/material.dart';
import '../models/refined_field_models.dart';
import '../database/refined_field_dao.dart';
import '../widgets/official_coin.dart';
import '../widgets/empty_coin_slot.dart';
import 'select_spirit_page.dart';

class RefinedFieldPage extends StatefulWidget {
  const RefinedFieldPage({super.key});

  @override
  State<RefinedFieldPage> createState() => _RefinedFieldPageState();
}

class _RefinedFieldPageState extends State<RefinedFieldPage> {
  List<OfficialSystem> _systems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // 获取8大系统静态数据
    final systems = OfficialSystemData.getSystems();
    
    // 从数据库加载已添加的精养人员
    final refinedPersons = await RefinedFieldDao.getAll();
    
    // 将人员分配到对应部门
    for (final system in systems) {
      for (final subCategory in system.subCategories) {
        for (final department in subCategory.departments) {
          department.persons = refinedPersons
              .where((p) => p.departmentId == department.id)
              .toList();
        }
      }
    }
    
    setState(() {
      _systems = systems;
      _isLoading = false;
    });
  }

  Future<void> _addPersonToDepartment(Department department, SubCategory subCategory, OfficialSystem system) async {
    if (department.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该部门已满（最多3人），请先移除现有人员')),
      );
      return;
    }
    
    final result = await Navigator.push<RefinedPerson>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectSpiritPage(
          departmentId: department.id,
          departmentName: department.name,
          subCategoryId: subCategory.id,
          systemId: system.id,
        ),
      ),
    );
    
    if (result != null) {
      await _loadData();
    }
  }

  void _showPersonDetail(RefinedPerson person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PersonDetailSheet(
        person: person,
        onEdit: () async {
          Navigator.pop(context);
          await _showEditDialog(person);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _confirmDelete(person);
        },
      ),
    );
  }

  Future<void> _showEditDialog(RefinedPerson person) async {
    final levelController = ValueNotifier<CoinLevel>(person.level);
    final resourcesController = TextEditingController(
      text: person.resources.join('、'),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑 ${person.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('硬币等级', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ValueListenableBuilder<CoinLevel>(
                valueListenable: levelController,
                builder: (context, level, _) => Column(
                  children: CoinLevel.values.reversed.map((l) => RadioListTile<CoinLevel>(
                    title: Text(l.displayName),
                    value: l,
                    groupValue: level,
                    onChanged: (v) => levelController.value = v!,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('资源标签', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: resourcesController,
                decoration: const InputDecoration(
                  hintText: '用顿号分隔，如：批条子、审项目',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true) {
      final resources = resourcesController.text
          .split(RegExp(r'[、,，]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final updated = person.copyWith(
        level: levelController.value,
        resources: resources,
      );
      await RefinedFieldDao.update(updated);
      await _loadData();
    }
  }

  Future<void> _confirmDelete(RefinedPerson person) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定将 ${person.name} 从精养田移除？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await RefinedFieldDao.delete(person.id);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5D4037), // 深棕色背景
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : CustomScrollView(
                slivers: [
                  // 顶部标题栏
                  SliverToBoxAdapter(child: _buildHeader()),
                  // 系统列表
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSystemCard(_systems[index]),
                      childCount: _systems.length,
                    ),
                  ),
                  // 底部留白
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: const Icon(Icons.grid_view, color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            '精养田',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.amber,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.amber, size: 24),
            onPressed: () {
              // TODO: 搜索功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('搜索功能开发中')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(OfficialSystem system) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        color: const Color(0xFFFFF8E1), // 米白色
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: system.isExpanded,
            onExpansionChanged: (expanded) {
              setState(() => system.isExpanded = expanded);
            },
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: system.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(system.icon, color: Colors.white, size: 24),
            ),
            title: Text(
              system.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: system.color,
              ),
            ),
            subtitle: Text(
              system.subCategories.map((s) => s.name).join(' | '),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            children: system.subCategories
                .map((sub) => _buildSubCategorySection(sub, system))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategorySection(SubCategory subCategory, OfficialSystem system) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 小类标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: system.color.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              subCategory.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: system.color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 部门列表
          ...subCategory.departments.map(
            (dept) => _buildDepartmentRow(dept, subCategory, system),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentRow(Department department, SubCategory subCategory, OfficialSystem system) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 部门名称（左侧）
          SizedBox(
            width: 70,
            child: Text(
              department.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 硬币槽位
          Expanded(
            child: Row(
              children: [
                // 已有人员的硬币
                ...department.persons.map(
                  (person) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OfficialCoin(
                      person: person,
                      onTap: () => _showPersonDetail(person),
                    ),
                  ),
                ),
                // 空槽位
                ...List.generate(
                  department.emptySlots,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: EmptyCoinSlot(
                      onTap: () => _addPersonToDepartment(department, subCategory, system),
                    ),
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

/// 人员详情底部弹窗
class _PersonDetailSheet extends StatelessWidget {
  final RefinedPerson person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PersonDetailSheet({
    required this.person,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部拖动条
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 硬币和姓名
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  person.level.assetPath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${person.departmentName} · ${person.level.shortName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    if (person.position != null && person.position!.isNotEmpty)
                      Text(
                        person.position!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 资源标签
          if (person.resources.isNotEmpty) ...[
            const Text(
              '可调用资源',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: person.resources
                  .map((r) => Chip(
                        label: Text(r, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.amber[50],
                        side: BorderSide(color: Colors.amber[200]!),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('移除'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
