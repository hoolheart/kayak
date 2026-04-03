/// Method model
///
/// Represents a test method definition
library;

/// Method model
class Method {
  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic> processDefinition;
  final Map<String, dynamic> parameterSchema;
  final int version;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Method({
    required this.id,
    required this.name,
    this.description,
    required this.processDefinition,
    required this.parameterSchema,
    required this.version,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Method.fromJson(Map<String, dynamic> json) {
    return Method(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      // M5 fix: Use safer cast pattern to handle non-null but non-Map values
      processDefinition: _safeCastMap(json['process_definition']),
      parameterSchema: _safeCastMap(json['parameter_schema']),
      version: json['version'] as int,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// M5 fix: Safe cast to Map<String, dynamic> that handles non-null but non-Map values
  static Map<String, dynamic> _safeCastMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'process_definition': processDefinition,
      'parameter_schema': parameterSchema,
      'version': version,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Method copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? processDefinition,
    Map<String, dynamic>? parameterSchema,
    int? version,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Method(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      processDefinition: processDefinition ?? this.processDefinition,
      parameterSchema: parameterSchema ?? this.parameterSchema,
      version: version ?? this.version,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Method list response
class MethodListResponse {
  final List<Method> items;
  final int total;
  final int page;
  final int size;

  const MethodListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory MethodListResponse.fromJson(Map<String, dynamic> json) {
    // C1 fix: Accept unwrapped data (service extracts ['data'] before calling)
    return MethodListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => Method.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
    );
  }
}

/// Validation result
class ValidationResult {
  final bool valid;
  final List<String> errors;

  const ValidationResult({
    required this.valid,
    required this.errors,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    // C2 fix: Accept unwrapped data (service extracts ['data'] before calling)
    return ValidationResult(
      valid: json['valid'] as bool,
      errors:
          (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}

/// Parameter configuration
class ParameterConfig {
  final String name;
  final String type;
  final dynamic defaultValue;
  final String? unit;
  final String? description;

  const ParameterConfig({
    required this.name,
    required this.type,
    this.defaultValue,
    this.unit,
    this.description,
  });

  factory ParameterConfig.fromJson(String name, Map<String, dynamic> json) {
    return ParameterConfig(
      name: name,
      // m7 fix: Use toString() for type to avoid cast exceptions
      type: json['type']?.toString() ?? 'string',
      defaultValue: json['default'],
      unit: json['unit'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'default': defaultValue,
      if (unit != null) 'unit': unit,
      if (description != null) 'description': description,
    };
  }
}
