import 'dart:convert';
import 'package:flutter/material.dart';

/// 硬币等级枚举
enum CoinLevel {
  iron,   // 0 - 办事员/科员
  bronze, // 1 - 股所级
  silver, // 2 - 副科级
  gold,   // 3 - 正科级及以上
}

extension CoinLevelExtension on CoinLevel {
  String get displayName {
    switch (this) {
      case CoinLevel.gold:
        return '金币（正科级及以上）';
      case CoinLevel.silver:
        return '银币（副科级）';
      case CoinLevel.bronze:
        return '铜币（股所级）';
      case CoinLevel.iron:
        return '铁币（办事员/科员）';
    }
  }

  String get shortName {
    switch (this) {
      case CoinLevel.gold:
        return '正科级';
      case CoinLevel.silver:
        return '副科级';
      case CoinLevel.bronze:
        return '股所级';
      case CoinLevel.iron:
        return '科员';
    }
  }

  String get assetPath => 'assets/coins/coin_$name.png';

  int get value => index;

  static CoinLevel fromValue(int value) {
    return CoinLevel.values[value.clamp(0, CoinLevel.values.length - 1)];
  }
}

/// 精养对象（关联生灵池）
class RefinedPerson {
  final String id;              // 精养田记录ID
  final String personId;        // 关联生灵池ID
  final String name;            // 姓名
  final String? position;       // 职务（如"常委办主任"）
  final CoinLevel level;        // 硬币级别
  final String departmentId;    // 所属部门ID
  final String departmentName;  // 部门名称
  final String subCategoryId;   // 所属小类ID
  final String systemId;        // 所属系统ID
  final List<String> resources; // 可调用的资源标签
  final DateTime createdAt;

  RefinedPerson({
    required this.id,
    required this.personId,
    required this.name,
    this.position,
    required this.level,
    required this.departmentId,
    required this.departmentName,
    required this.subCategoryId,
    required this.systemId,
    List<String>? resources,
    DateTime? createdAt,
  })  : resources = resources ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_id': personId,
      'name': name,
      'position': position,
      'coin_level': level.value,
      'department_id': departmentId,
      'department_name': departmentName,
      'sub_category_id': subCategoryId,
      'system_id': systemId,
      'resources': jsonEncode(resources),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory RefinedPerson.fromMap(Map<String, dynamic> map) {
    return RefinedPerson(
      id: map['id'] as String,
      personId: map['person_id'] as String,
      name: map['name'] as String,
      position: map['position'] as String?,
      level: CoinLevelExtension.fromValue(map['coin_level'] as int),
      departmentId: map['department_id'] as String,
      departmentName: map['department_name'] as String,
      subCategoryId: map['sub_category_id'] as String,
      systemId: map['system_id'] as String,
      resources: _decodeJsonList(map['resources']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  static List<String> _decodeJsonList(dynamic value) {
    if (value == null || value == '') return [];
    try {
      final list = jsonDecode(value as String);
      return (list as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  RefinedPerson copyWith({
    String? id,
    String? personId,
    String? name,
    String? position,
    CoinLevel? level,
    String? departmentId,
    String? departmentName,
    String? subCategoryId,
    String? systemId,
    List<String>? resources,
  }) {
    return RefinedPerson(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      name: name ?? this.name,
      position: position ?? this.position,
      level: level ?? this.level,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      systemId: systemId ?? this.systemId,
      resources: resources ?? List.from(this.resources),
      createdAt: createdAt,
    );
  }
}

/// 部门（1-3个槽位）
class Department {
  final String id;
  final String name;
  final String subCategoryId;
  final int maxSlots; // 最多可放置的硬币数量，默认3
  List<RefinedPerson> persons;

  Department({
    required this.id,
    required this.name,
    required this.subCategoryId,
    this.maxSlots = 3,
    List<RefinedPerson>? persons,
  }) : persons = persons ?? [];

  bool get isFull => persons.length >= maxSlots;
  int get emptySlots => maxSlots - persons.length;
}

/// 小类（每个系统3个）
class SubCategory {
  final String id;
  final String name;
  final String systemId;
  final List<Department> departments;

  SubCategory({
    required this.id,
    required this.name,
    required this.systemId,
    required this.departments,
  });
}

/// 8大系统
class OfficialSystem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<SubCategory> subCategories;
  bool isExpanded;

  OfficialSystem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.subCategories,
    this.isExpanded = false,
  });
}

/// 8大系统初始化数据
class OfficialSystemData {
  static List<OfficialSystem> getSystems() {
    return [
      // 1. 党委系统
      OfficialSystem(
        id: 'party',
        name: '党委系统',
        icon: Icons.account_balance,
        color: const Color(0xFFD32F2F), // 红色
        isExpanded: true, // 默认展开
        subCategories: [
          SubCategory(
            id: 'party_core',
            name: '核心运行',
            systemId: 'party',
            departments: [
              Department(id: 'dept_xwb', name: '县委办', subCategoryId: 'party_core'),
              Department(id: 'dept_zys', name: '政研室', subCategoryId: 'party_core'),
              Department(id: 'dept_dsyjs', name: '党史研究室', subCategoryId: 'party_core'),
              Department(id: 'dept_dx', name: '党校', subCategoryId: 'party_core'),
            ],
          ),
          SubCategory(
            id: 'party_org',
            name: '组织与队伍',
            systemId: 'party',
            departments: [
              Department(id: 'dept_zzb', name: '组织部', subCategoryId: 'party_org'),
              Department(id: 'dept_bb', name: '编办', subCategoryId: 'party_org'),
            ],
          ),
          SubCategory(
            id: 'party_prop',
            name: '宣传统战与政法',
            systemId: 'party',
            departments: [
              Department(id: 'dept_xcb', name: '宣传部', subCategoryId: 'party_prop'),
              Department(id: 'dept_tzb', name: '统战部', subCategoryId: 'party_prop'),
              Department(id: 'dept_zfw', name: '政法委', subCategoryId: 'party_prop'),
            ],
          ),
          SubCategory(
            id: 'party_discipline',
            name: '纪检监察与巡察/司法',
            systemId: 'party',
            departments: [
              Department(id: 'dept_xjw', name: '县纪委', subCategoryId: 'party_discipline'),
              Department(id: 'dept_xcb2', name: '巡察办', subCategoryId: 'party_discipline'),
              Department(id: 'dept_fy', name: '法院', subCategoryId: 'party_discipline'),
              Department(id: 'dept_jcy', name: '检察院', subCategoryId: 'party_discipline'),
            ],
          ),
        ],
      ),

      // 2. 政经系统
      OfficialSystem(
        id: 'economy',
        name: '政经系统',
        icon: Icons.trending_up,
        color: const Color(0xFFF57C00), // 橙色
        subCategories: [
          SubCategory(
            id: 'econ_gov',
            name: '政府运行保障',
            systemId: 'economy',
            departments: [
              Department(id: 'dept_zfb', name: '政府办', subCategoryId: 'econ_gov'),
              Department(id: 'dept_zwfwzx', name: '政务服务中心', subCategoryId: 'econ_gov'),
              Department(id: 'dept_dag', name: '档案馆', subCategoryId: 'econ_gov'),
            ],
          ),
          SubCategory(
            id: 'econ_finance',
            name: '财政审计与国资',
            systemId: 'economy',
            departments: [
              Department(id: 'dept_czj', name: '财政局', subCategoryId: 'econ_finance'),
              Department(id: 'dept_sjj', name: '审计局', subCategoryId: 'econ_finance'),
              Department(id: 'dept_tjj', name: '统计局', subCategoryId: 'econ_finance'),
              Department(id: 'dept_fzjt', name: '发展集团', subCategoryId: 'econ_finance'),
              Department(id: 'dept_gxs', name: '供销社', subCategoryId: 'econ_finance'),
            ],
          ),
          SubCategory(
            id: 'econ_industry',
            name: '产业与投资',
            systemId: 'economy',
            departments: [
              Department(id: 'dept_fgj', name: '发改局', subCategoryId: 'econ_industry'),
              Department(id: 'dept_nyj', name: '能源局', subCategoryId: 'econ_industry'),
              Department(id: 'dept_gxj', name: '工信局', subCategoryId: 'econ_industry'),
              Department(id: 'dept_tzfwzx', name: '投资服务中心', subCategoryId: 'econ_industry'),
              Department(id: 'dept_cyyq', name: '产业园区', subCategoryId: 'econ_industry'),
            ],
          ),
        ],
      ),

      // 3. 民生与社保系统
      OfficialSystem(
        id: 'livelihood',
        name: '民生与社保系统',
        icon: Icons.people,
        color: const Color(0xFF00796B), // 青色
        subCategories: [
          SubCategory(
            id: 'live_culture',
            name: '教育文化与体育',
            systemId: 'livelihood',
            departments: [
              Department(id: 'dept_jtj', name: '教体局', subCategoryId: 'live_culture'),
              Department(id: 'dept_wlj', name: '文旅局', subCategoryId: 'live_culture'),
            ],
          ),
          SubCategory(
            id: 'live_health',
            name: '民政与卫健',
            systemId: 'livelihood',
            departments: [
              Department(id: 'dept_mzj', name: '民政局', subCategoryId: 'live_health'),
              Department(id: 'dept_rsj', name: '人社局', subCategoryId: 'live_health'),
              Department(id: 'dept_ybj', name: '医保局', subCategoryId: 'live_health'),
              Department(id: 'dept_wjj', name: '卫健局', subCategoryId: 'live_health'),
              Department(id: 'dept_xyy', name: '县医院', subCategoryId: 'live_health'),
              Department(id: 'dept_jkzx', name: '疾控中心', subCategoryId: 'live_health'),
              Department(id: 'dept_fybjy', name: '妇幼保健院', subCategoryId: 'live_health'),
              Department(id: 'dept_jsxh', name: '计生协会', subCategoryId: 'live_health'),
            ],
          ),
          SubCategory(
            id: 'live_veteran',
            name: '退役与民宗',
            systemId: 'livelihood',
            departments: [
              Department(id: 'dept_tyjrj', name: '退役军人局', subCategoryId: 'live_veteran'),
              Department(id: 'dept_mzj2', name: '民宗局', subCategoryId: 'live_veteran'),
            ],
          ),
        ],
      ),

      // 4. 三农与资源环境系统
      OfficialSystem(
        id: 'agriculture',
        name: '三农与资源环境系统',
        icon: Icons.grass,
        color: const Color(0xFF388E3C), // 绿色
        subCategories: [
          SubCategory(
            id: 'agri_rural',
            name: '农业农村',
            systemId: 'agriculture',
            departments: [
              Department(id: 'dept_nyj2', name: '农业局', subCategoryId: 'agri_rural'),
              Department(id: 'dept_xcfxj', name: '乡村振兴局', subCategoryId: 'agri_rural'),
              Department(id: 'dept_gtzx', name: '高特中心', subCategoryId: 'agri_rural'),
            ],
          ),
          SubCategory(
            id: 'agri_water',
            name: '水利与林草',
            systemId: 'agriculture',
            departments: [
              Department(id: 'dept_swj', name: '水务局', subCategoryId: 'agri_water'),
              Department(id: 'dept_lcj', name: '林草局', subCategoryId: 'agri_water'),
              Department(id: 'dept_skglj', name: '水库管理局', subCategoryId: 'agri_water'),
              Department(id: 'dept_hzb', name: '河长办', subCategoryId: 'agri_water'),
              Department(id: 'dept_gylc', name: '国有林场', subCategoryId: 'agri_water'),
            ],
          ),
          SubCategory(
            id: 'agri_resource',
            name: '自然资源与搬迁安置',
            systemId: 'agriculture',
            departments: [
              Department(id: 'dept_zrzyj', name: '自然资源局', subCategoryId: 'agri_resource'),
              Department(id: 'dept_bqazj', name: '搬迁安置局', subCategoryId: 'agri_resource'),
            ],
          ),
        ],
      ),

      // 5. 城建与交管系统
      OfficialSystem(
        id: 'urban',
        name: '城建与交管系统',
        icon: Icons.location_city,
        color: const Color(0xFF5D4037), // 棕色
        subCategories: [
          SubCategory(
            id: 'urban_plan',
            name: '城乡规划与建设',
            systemId: 'urban',
            departments: [
              Department(id: 'dept_zjj', name: '住建局', subCategoryId: 'urban_plan'),
              Department(id: 'dept_jtysj', name: '交通运输局', subCategoryId: 'urban_plan'),
              Department(id: 'dept_cgzfdd', name: '城管执法大队', subCategoryId: 'urban_plan'),
            ],
          ),
        ],
      ),

      // 6. 政法与应急管理
      OfficialSystem(
        id: 'law',
        name: '政法与应急管理',
        icon: Icons.gavel,
        color: const Color(0xFF1976D2), // 蓝色
        subCategories: [
          SubCategory(
            id: 'law_police',
            name: '公安与司法',
            systemId: 'law',
            departments: [
              Department(id: 'dept_gaj', name: '公安局', subCategoryId: 'law_police'),
              Department(id: 'dept_slgaj', name: '森林公安局', subCategoryId: 'law_police'),
              Department(id: 'dept_fy2', name: '法院', subCategoryId: 'law_police'),
              Department(id: 'dept_jcy2', name: '检察院', subCategoryId: 'law_police'),
              Department(id: 'dept_sfj', name: '司法局', subCategoryId: 'law_police'),
            ],
          ),
          SubCategory(
            id: 'law_emergency',
            name: '应急与安全',
            systemId: 'law',
            departments: [
              Department(id: 'dept_yjglj', name: '应急管理局', subCategoryId: 'law_emergency'),
              Department(id: 'dept_fzjzj', name: '防震减灾局', subCategoryId: 'law_emergency'),
            ],
          ),
          SubCategory(
            id: 'law_social',
            name: '社会治理专项',
            systemId: 'law',
            departments: [
              Department(id: 'dept_xfj', name: '信访局', subCategoryId: 'law_social'),
            ],
          ),
        ],
      ),

      // 7. 基层治理与群团武装
      OfficialSystem(
        id: 'grassroots',
        name: '基层治理与群团武装',
        icon: Icons.groups,
        color: const Color(0xFF7B1FA2), // 紫色
        subCategories: [
          SubCategory(
            id: 'grass_congress',
            name: '人大与政协',
            systemId: 'grassroots',
            departments: [
              Department(id: 'dept_xrd', name: '县人大', subCategoryId: 'grass_congress'),
              Department(id: 'dept_xzx', name: '县政协', subCategoryId: 'grass_congress'),
            ],
          ),
          SubCategory(
            id: 'grass_mass',
            name: '群团组织',
            systemId: 'grassroots',
            departments: [
              Department(id: 'dept_zgh', name: '总工会', subCategoryId: 'grass_mass'),
              Department(id: 'dept_txw', name: '团县委', subCategoryId: 'grass_mass'),
              Department(id: 'dept_fl', name: '妇联', subCategoryId: 'grass_mass'),
              Department(id: 'dept_kx', name: '科协', subCategoryId: 'grass_mass'),
              Department(id: 'dept_wl', name: '文联', subCategoryId: 'grass_mass'),
              Department(id: 'dept_skl', name: '社科联', subCategoryId: 'grass_mass'),
              Department(id: 'dept_gsl', name: '工商联', subCategoryId: 'grass_mass'),
              Department(id: 'dept_cl', name: '残联', subCategoryId: 'grass_mass'),
              Department(id: 'dept_hszh', name: '红十字会', subCategoryId: 'grass_mass'),
            ],
          ),
          SubCategory(
            id: 'grass_military',
            name: '军事武装',
            systemId: 'grassroots',
            departments: [
              Department(id: 'dept_wzb', name: '武装部', subCategoryId: 'grass_military'),
            ],
          ),
        ],
      ),

      // 8. 乡镇（街道）基层政权
      OfficialSystem(
        id: 'township',
        name: '乡镇（街道）基层政权',
        icon: Icons.home_work,
        color: const Color(0xFF455A64), // 灰蓝色
        subCategories: [
          SubCategory(
            id: 'town_core',
            name: '核心城区',
            systemId: 'township',
            departments: [
              Department(id: 'dept_wfjd', name: '乌峰街道办事处', subCategoryId: 'town_core'),
              Department(id: 'dept_ntjd', name: '南台街道办事处', subCategoryId: 'town_core'),
              Department(id: 'dept_jfjd', name: '旧府街道办事处', subCategoryId: 'town_core'),
            ],
          ),
          SubCategory(
            id: 'town_near',
            name: '近郊乡镇（≤20km）',
            systemId: 'township',
            departments: [
              Department(id: 'dept_csyz', name: '赤水源镇', subCategoryId: 'town_near'),
              Department(id: 'dept_cbz', name: '场坝镇', subCategoryId: 'town_near'),
              Department(id: 'dept_tfz', name: '塘房镇', subCategoryId: 'town_near'),
              Department(id: 'dept_ztz', name: '中屯镇', subCategoryId: 'town_near'),
            ],
          ),
          SubCategory(
            id: 'town_mid',
            name: '中郊乡镇（21-50km）',
            systemId: 'township',
            departments: [
              Department(id: 'dept_pjz', name: '泼机镇', subCategoryId: 'town_mid'),
              Department(id: 'dept_mbz', name: '芒部镇', subCategoryId: 'town_mid'),
              Department(id: 'dept_jsx', name: '尖山乡', subCategoryId: 'town_mid'),
              Department(id: 'dept_gzyzx', name: '果珠彝族乡', subCategoryId: 'town_mid'),
              Department(id: 'dept_lkyzhmzx', name: '林口彝族苗族乡', subCategoryId: 'town_mid'),
            ],
          ),
          SubCategory(
            id: 'town_far',
            name: '远郊乡镇（51-80km）',
            systemId: 'township',
            departments: [
              Department(id: 'dept_mzz', name: '木卓镇', subCategoryId: 'town_far'),
              Department(id: 'dept_wdz', name: '五德镇', subCategoryId: 'town_far'),
              Department(id: 'dept_psz', name: '坪上镇', subCategoryId: 'town_far'),
              Department(id: 'dept_ylz', name: '以勒镇', subCategoryId: 'town_far'),
              Department(id: 'dept_yhz', name: '雨河镇', subCategoryId: 'town_far'),
              Department(id: 'dept_ygz', name: '以古镇', subCategoryId: 'town_far'),
              Department(id: 'dept_ydx', name: '鱼洞乡', subCategoryId: 'town_far'),
              Department(id: 'dept_dwz', name: '大湾镇', subCategoryId: 'town_far'),
              Department(id: 'dept_ncz', name: '牛场镇', subCategoryId: 'town_far'),
              Department(id: 'dept_mxz', name: '母享镇', subCategoryId: 'town_far'),
              Department(id: 'dept_hsz', name: '黑树镇', subCategoryId: 'town_far'),
            ],
          ),
          SubCategory(
            id: 'town_remote',
            name: '偏远乡镇（≥81km）',
            systemId: 'township',
            departments: [
              Department(id: 'dept_hlx', name: '花朗乡', subCategoryId: 'town_remote'),
              Department(id: 'dept_ptz', name: '坡头镇', subCategoryId: 'town_remote'),
              Department(id: 'dept_lkz', name: '罗坎镇', subCategoryId: 'town_remote'),
              Department(id: 'dept_yyz', name: '盐源镇', subCategoryId: 'town_remote'),
              Department(id: 'dept_hsx', name: '花山乡', subCategoryId: 'town_remote'),
              Department(id: 'dept_wcz', name: '碗厂镇', subCategoryId: 'town_remote'),
              Department(id: 'dept_ssx', name: '杉树乡', subCategoryId: 'town_remote'),
            ],
          ),
        ],
      ),
    ];
  }
}
