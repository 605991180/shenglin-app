import 'package:flutter/material.dart';
import '../database/spirit_dao.dart';
import '../database/refined_field_dao.dart';
import '../models/spirit.dart';
import '../models/refined_field_models.dart';
import '../widgets/spirit_list_item.dart';

/// 从生灵池选择人员添加到精养田
class SelectSpiritPage extends StatefulWidget {
  final String departmentId;
  final String departmentName;
  final String subCategoryId;
  final String systemId;

  const SelectSpiritPage({
    super.key,
    required this.departmentId,
    required this.departmentName,
    required this.subCategoryId,
    required this.systemId,
  });

  @override
  State<SelectSpiritPage> createState() => _SelectSpiritPageState();
}

class _SelectSpiritPageState extends State<SelectSpiritPage> {
  List<Spirit> _spirits = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpirits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpirits() async {
    setState(() => _isLoading = true);
    
    // 获取所有生灵（优先显示政客身份的）
    List<Spirit> spirits;
    if (_searchQuery.isEmpty) {
      spirits = await SpiritDao.getAll();
    } else {
      spirits = await SpiritDao.search(_searchQuery);
    }
    
    // 按身份排序：政客优先
    spirits.sort((a, b) {
      final aIsOfficial = a.identity == '政客' ? 0 : 1;
      final bIsOfficial = b.identity == '政客' ? 0 : 1;
      if (aIsOfficial != bIsOfficial) return aIsOfficial.compareTo(bIsOfficial);
      return (a.pinyin ?? '').compareTo(b.pinyin ?? '');
    });
    
    setState(() {
      _spirits = spirits;
      _isLoading = false;
    });
  }

  Future<void> _selectSpirit(Spirit spirit) async {
    // 检查是否已在精养田中
    final isInField = await RefinedFieldDao.isPersonInField(spirit.id);
    if (isInField) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${spirit.name} 已在精养田中')),
        );
      }
      return;
    }
    
    // 根据身份等级推荐硬币级别
    final recommendedLevel = _getRecommendedLevel(spirit);
    
    // 显示设置对话框
    final result = await _showAddDialog(spirit, recommendedLevel);
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  CoinLevel _getRecommendedLevel(Spirit spirit) {
    final level = spirit.identityLevel?.toLowerCase() ?? '';
    if (level.contains('正科') || level.contains('局长') || level.contains('主任') || level.contains('书记')) {
      return CoinLevel.gold;
    } else if (level.contains('副科') || level.contains('副局') || level.contains('副主任')) {
      return CoinLevel.silver;
    } else if (level.contains('股') || level.contains('所长') || level.contains('科长')) {
      return CoinLevel.bronze;
    }
    return CoinLevel.iron;
  }

  Future<RefinedPerson?> _showAddDialog(Spirit spirit, CoinLevel recommendedLevel) async {
    final levelController = ValueNotifier<CoinLevel>(recommendedLevel);
    final positionController = TextEditingController(text: spirit.identityLevel ?? '');
    final resourcesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加 ${spirit.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '添加到：${widget.departmentName}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('职务', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: positionController,
                decoration: const InputDecoration(
                  hintText: '如：办公室主任',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('硬币等级', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ValueListenableBuilder<CoinLevel>(
                valueListenable: levelController,
                builder: (context, level, _) => Column(
                  children: CoinLevel.values.reversed.map((l) {
                    final isRecommended = l == recommendedLevel;
                    return RadioListTile<CoinLevel>(
                      title: Row(
                        children: [
                          Text(l.displayName),
                          if (isRecommended)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '推荐',
                                style: TextStyle(fontSize: 10, color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                      value: l,
                      groupValue: level,
                      onChanged: (v) => levelController.value = v!,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D4037),
            ),
            child: const Text('确认添加'),
          ),
        ],
      ),
    );

    if (confirmed != true) return null;

    final resources = resourcesController.text
        .split(RegExp(r'[、,，]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final person = RefinedPerson(
      id: RefinedFieldDao.generateId(spirit.id, widget.departmentId),
      personId: spirit.id,
      name: spirit.name,
      position: positionController.text.isEmpty ? null : positionController.text,
      level: levelController.value,
      departmentId: widget.departmentId,
      departmentName: widget.departmentName,
      subCategoryId: widget.subCategoryId,
      systemId: widget.systemId,
      resources: resources,
    );

    await RefinedFieldDao.insert(person);
    return person;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.amber,
        title: Text('选择生灵 → ${widget.departmentName}'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                _searchQuery = v;
                _loadSpirits();
              },
              decoration: InputDecoration(
                hintText: '搜索姓名...',
                hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFCCCCCC), size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // 提示信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.amber[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '政客身份的生灵优先显示，点击选择添加到精养田',
                    style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                  ),
                ),
              ],
            ),
          ),
          // 生灵列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _spirits.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off, size: 64, color: Color(0xFFDDDDDD)),
                            SizedBox(height: 12),
                            Text('暂无生灵', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
                            SizedBox(height: 4),
                            Text('请先在生灵池添加联系人', style: TextStyle(fontSize: 13, color: Color(0xFFCCCCCC))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _spirits.length,
                        itemBuilder: (context, index) {
                          final spirit = _spirits[index];
                          return SpiritListItem(
                            name: spirit.name,
                            subtitle: _buildSubtitle(spirit),
                            avatarPath: spirit.avatar,
                            onTap: () => _selectSpirit(spirit),
                            trailing: spirit.identity == '政客'
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red[200]!),
                                    ),
                                    child: Text(
                                      '政客',
                                      style: TextStyle(fontSize: 11, color: Colors.red[700]),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(Spirit spirit) {
    final parts = <String>[];
    if (spirit.identityLevel != null && spirit.identityLevel!.isNotEmpty) {
      parts.add(spirit.identityLevel!);
    }
    if (spirit.affinity != null && spirit.affinity!.isNotEmpty) {
      parts.add(spirit.affinity!);
    }
    return parts.isEmpty ? '' : parts.join(' · ');
  }
}
