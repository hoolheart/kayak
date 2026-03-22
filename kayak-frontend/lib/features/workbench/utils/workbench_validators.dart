/// 工作台验证器
library;

class WorkbenchValidators {
  /// 验证工作台名称
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '名称不能为空';
    }
    if (value.trim().length > 255) {
      return '名称不能超过255个字符';
    }
    return null;
  }

  /// 验证工作台描述
  static String? validateDescription(String? value) {
    if (value != null && value.length > 1000) {
      return '描述不能超过1000个字符';
    }
    return null;
  }
}
