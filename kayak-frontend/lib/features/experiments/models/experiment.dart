/// 实验数据模型
///
/// 定义试验的核心属性和序列化逻辑
library;

/// 实验状态
enum ExperimentStatus {
  idle('IDLE'),
  loaded('LOADED'),
  running('RUNNING'),
  paused('PAUSED'),
  completed('COMPLETED'),
  aborted('ABORTED');

  final String value;
  const ExperimentStatus(this.value);

  static ExperimentStatus fromString(String value) {
    return ExperimentStatus.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => ExperimentStatus.idle,
    );
  }
}

/// 实验实体
class Experiment {
  final String id;
  final String userId;
  final String? methodId;
  final String name;
  final String? description;
  final ExperimentStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Experiment({
    required this.id,
    required this.userId,
    this.methodId,
    required this.name,
    this.description,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Experiment.fromJson(Map<String, dynamic> json) {
    return Experiment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      methodId: json['method_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: ExperimentStatus.fromString(json['status'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'method_id': methodId,
      'name': name,
      'description': description,
      'status': status.value,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Experiment copyWith({
    String? id,
    String? userId,
    String? methodId,
    String? name,
    String? description,
    ExperimentStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Experiment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      methodId: methodId ?? this.methodId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 实验列表分页响应
class PagedExperimentResponse {
  final List<Experiment> items;
  final int page;
  final int size;
  final int total;
  final bool hasNext;
  final bool hasPrev;

  const PagedExperimentResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PagedExperimentResponse.fromJson(Map<String, dynamic> json) {
    return PagedExperimentResponse(
      items: (json['items'] as List)
          .map((e) => Experiment.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      total: json['total'] as int,
      hasNext: json['has_next'] as bool,
      hasPrev: json['has_prev'] as bool,
    );
  }
}
