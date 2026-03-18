/// Action definition for events (api, navigate, popup, toast, setState, log).
class SduiAction {
  final String event;
  final String type;
  final String? target;
  final Map<String, dynamic>? props;
  final SduiAction? onSuccess;
  final SduiAction? onFail;

  const SduiAction({
    required this.event,
    required this.type,
    this.target,
    this.props,
    this.onSuccess,
    this.onFail,
  });

  factory SduiAction.fromJson(Map<String, dynamic> json) {
    return SduiAction(
      event: json['event'] as String? ?? '',
      type: json['type'] as String? ?? '',
      target: json['target'] as String?,
      props: json['props'] as Map<String, dynamic>?,
      onSuccess: json['onSuccess'] != null
          ? SduiAction.fromJson(json['onSuccess'] as Map<String, dynamic>)
          : null,
      onFail: json['onFail'] != null
          ? SduiAction.fromJson(json['onFail'] as Map<String, dynamic>)
          : null,
    );
  }
}
