/// Root SDUI payload schema (§2). All keys required at top level.
class SduiRoot {
  final Map<String, dynamic> tokens;
  final Map<String, dynamic> styles;
  final Map<String, dynamic> apis;
  final Map<String, dynamic> actions;
  final Map<String, dynamic> components;
  final Map<String, dynamic> layout;

  const SduiRoot({
    required this.tokens,
    required this.styles,
    required this.apis,
    required this.actions,
    required this.components,
    required this.layout,
  });

  factory SduiRoot.fromJson(Map<String, dynamic> json) {
    return SduiRoot(
      tokens: json['tokens'] as Map<String, dynamic>? ?? {},
      styles: json['styles'] as Map<String, dynamic>? ?? {},
      apis: json['apis'] as Map<String, dynamic>? ?? {},
      actions: json['actions'] as Map<String, dynamic>? ?? {},
      components: json['components'] as Map<String, dynamic>? ?? {},
      layout: json['layout'] as Map<String, dynamic>? ?? {},
    );
  }

  /// styles.classes from doc §3.2
  Map<String, dynamic> get styleClasses {
    final classes = styles['classes'];
    if (classes is Map<String, dynamic>) return classes;
    return {};
  }
}
