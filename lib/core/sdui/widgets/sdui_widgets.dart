import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:fh_sdui_v2/core/state/sdui_state_controller.dart';

import '../engine/layout_engine.dart';
import '../models/sdui_action.dart';
import '../models/sdui_node.dart';
import '../resolver/token_resolver.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget wrapEnabled(Widget child, bool enabled) {
  if (enabled) return child;
  return IgnorePointer(child: Opacity(opacity: 0.5, child: child));
}

void runEvent(LayoutEngine engine, SduiNode node, String event) {
  for (final a in node.actions) {
    if (a.event == event) engine.actionExecutor.run(a);
  }
}

List<Widget> _addGap(List<Widget> children, double gap) {
  if (gap <= 0 || children.length <= 1) return children;
  final out = <Widget>[];
  for (int i = 0; i < children.length; i++) {
    out.add(children[i]);
    if (i < children.length - 1) out.add(SizedBox(height: gap, width: gap));
  }
  return out;
}

IconData resolveIcon(String? name) {
  switch (name) {
    case 'home':
      return Icons.home_outlined;
    case 'home_filled':
      return Icons.home;
    case 'search':
      return Icons.search;
    case 'mic':
      return Icons.mic_none;
    case 'notifications':
      return Icons.notifications_outlined;
    case 'person':
      return Icons.person;
    case 'grid_view':
      return Icons.grid_view;
    case 'local_pharmacy':
      return Icons.local_pharmacy_outlined;
    case 'shopping_cart':
      return Icons.shopping_cart_outlined;
    case 'headphones':
      return Icons.headset_mic_outlined;
    case 'chevron_right':
      return Icons.chevron_right;
    case 'arrow_drop_down':
      return Icons.arrow_drop_down;
    case 'arrow_back':
      return Icons.arrow_back;
    case 'close':
      return Icons.close;
    case 'check':
      return Icons.check;
    case 'add':
      return Icons.add;
    case 'location_on':
      return Icons.location_on_outlined;
    case 'science':
      return Icons.science_outlined;
    case 'medical_services':
      return Icons.medical_services_outlined;
    case 'visibility':
      return Icons.visibility_outlined;
    case 'local_hospital':
      return Icons.local_hospital_outlined;
    case 'vaccines':
      return Icons.vaccines_outlined;
    case 'biotech':
      return Icons.biotech_outlined;
    default:
      return Icons.circle;
  }
}

// ---------------------------------------------------------------------------
// screen
// ---------------------------------------------------------------------------

class SduiScreen extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiScreen({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final style = engine.styleResolver.resolve(node.style);
    final children = engine.buildChildren(node.children);

    Widget body = Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: style.crossAxisAlignment ?? CrossAxisAlignment.stretch,
      children: children,
    );

    body = wrapEnabled(body, enabled);

    return Scaffold(
      backgroundColor: style.backgroundColor ?? Colors.white,
      body: SafeArea(
        child: Padding(
          padding: style.padding ?? EdgeInsets.zero,
          child: body,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// row
// ---------------------------------------------------------------------------

class SduiRow extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiRow({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final style = engine.styleResolver.resolve(node.style);
    var children = engine.buildChildren(node.children);
    if (style.gap != null && style.gap! > 0) children = _addGap(children, style.gap!);
    return wrapEnabled(
      Row(
        mainAxisAlignment: style.mainAxisAlignment ?? MainAxisAlignment.start,
        crossAxisAlignment: style.crossAxisAlignment ?? CrossAxisAlignment.center,
        mainAxisSize: style.mainAxisSize ?? MainAxisSize.max,
        children: children,
      ),
      enabled,
    );
  }
}

// ---------------------------------------------------------------------------
// column
// ---------------------------------------------------------------------------

class SduiColumn extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiColumn({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final style = engine.styleResolver.resolve(node.style);
    var children = engine.buildChildren(node.children);
    if (style.gap != null && style.gap! > 0) children = _addGap(children, style.gap!);
    return wrapEnabled(
      Column(
        mainAxisAlignment: style.mainAxisAlignment ?? MainAxisAlignment.start,
        crossAxisAlignment: style.crossAxisAlignment ?? CrossAxisAlignment.start,
        mainAxisSize: style.mainAxisSize ?? MainAxisSize.min,
        children: children,
      ),
      enabled,
    );
  }
}

// ---------------------------------------------------------------------------
// container
// ---------------------------------------------------------------------------

class SduiContainer extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiContainer({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final style = engine.styleResolver.resolve(node.style);
    final children = engine.buildChildren(node.children);
    Widget child = children.isEmpty
        ? const SizedBox.shrink()
        : (children.length == 1 ? children[0] : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: children));

    Widget container = Container(
      padding: style.padding,
      margin: style.margin,
      width: style.width,
      height: style.height,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: style.borderRadius != null ? BorderRadius.circular(style.borderRadius!) : null,
        border: style.borderColor != null
            ? Border.all(color: style.borderColor!, width: style.borderWidth ?? 1)
            : style.border,
        boxShadow: style.elevation != null && style.elevation! > 0
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: style.elevation! * 2, offset: Offset(0, style.elevation!))]
            : null,
      ),
      child: child,
    );

    if (style.opacity != null) {
      container = Opacity(opacity: style.opacity!, child: container);
    }

    if (node.actions.isNotEmpty && node.actions.any((a) => a.event == 'onClick')) {
      container = GestureDetector(
        onTap: () => runEvent(engine, node, 'onClick'),
        child: container,
      );
    }

    return wrapEnabled(container, enabled);
  }
}

// ---------------------------------------------------------------------------
// text
// ---------------------------------------------------------------------------

class SduiText extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiText({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final style = engine.styleResolver.resolve(node.style);
    final text = engine.expressionResolver.resolveString(node.props['text'] as String?);

    Widget w = Text(
      text,
      textAlign: style.textAlign,
      maxLines: style.maxLines,
      overflow: style.textOverflow,
      style: TextStyle(
        fontSize: style.fontSize ?? 14,
        fontWeight: style.fontWeight,
        color: style.color ?? Colors.black87,
        letterSpacing: style.letterSpacing,
        height: style.lineHeight,
        decoration: style.textDecoration,
      ),
    );

    if (style.padding != null) w = Padding(padding: style.padding!, child: w);

    if (node.actions.isNotEmpty && node.actions.any((a) => a.event == 'onClick')) {
      w = GestureDetector(onTap: () => runEvent(engine, node, 'onClick'), child: w);
    }

    return wrapEnabled(w, enabled);
  }
}

// ---------------------------------------------------------------------------
// rich_text: spans with mixed styles
// ---------------------------------------------------------------------------

class SduiRichText extends StatefulWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiRichText({super.key, required this.node, required this.engine, required this.enabled});

  @override
  State<SduiRichText> createState() => _SduiRichTextState();
}

class _SduiRichTextState extends State<SduiRichText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = widget.node.props['spans'] as List? ?? [];
    final textSpans = <TextSpan>[];

    for (final span in spans) {
      if (span is! Map) continue;
      final text = widget.engine.expressionResolver.resolveString(span['text'] as String?);
      final spanStyleRaw = span['style'] as Map<String, dynamic>?;
      Color? color;
      double? fontSize;
      FontWeight? fontWeight;
      TextDecoration? decoration;

      if (spanStyleRaw != null) {
        final cs = spanStyleRaw['color'] as String?;
        if (cs != null) color = TokenResolver.parseColor(cs);
        final fs = spanStyleRaw['fontSize'];
        if (fs is num) fontSize = fs.toDouble();
        final fw = spanStyleRaw['fontWeight'] as String?;
        if (fw == 'bold') fontWeight = FontWeight.bold;
        if (fw == 'w600') fontWeight = FontWeight.w600;
        if (fw == 'w500') fontWeight = FontWeight.w500;
        final td = spanStyleRaw['textDecoration'] as String?;
        if (td == 'underline') decoration = TextDecoration.underline;
      }

      GestureRecognizer? recognizer;
      final spanActions = span['actions'] as List?;
      if (spanActions != null && spanActions.isNotEmpty) {
        final tapRecognizer = TapGestureRecognizer()
          ..onTap = () {
            for (final a in spanActions) {
              if (a is Map<String, dynamic>) {
                widget.engine.actionExecutor.run(SduiAction.fromJson(a));
              }
            }
          };
        _recognizers.add(tapRecognizer);
        recognizer = tapRecognizer;
      }

      textSpans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontSize: fontSize ?? 13,
          fontWeight: fontWeight,
          decoration: decoration,
        ),
        recognizer: recognizer,
      ));
    }

    return wrapEnabled(
      Text.rich(TextSpan(children: textSpans)),
      widget.enabled,
    );
  }
}

// ---------------------------------------------------------------------------
// image
// ---------------------------------------------------------------------------

class SduiImage extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiImage({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final url = engine.expressionResolver.resolveString(node.props['url'] as String?);
    final style = engine.styleResolver.resolve(node.style);
    if (url.isEmpty) return const SizedBox.shrink();

    Widget img = Image.network(
      url,
      width: style.width,
      height: style.height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: style.width,
        height: style.height,
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey),
      ),
    );

    if (style.borderRadius != null) {
      img = ClipRRect(
        borderRadius: BorderRadius.circular(style.borderRadius!),
        child: img,
      );
    }

    return wrapEnabled(img, enabled);
  }
}

// ---------------------------------------------------------------------------
// icon
// ---------------------------------------------------------------------------

class SduiIcon extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiIcon({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final name = node.props['name'] as String?;
    final size = (node.props['size'] as num?)?.toDouble() ?? 24;
    final style = engine.styleResolver.resolve(node.style);
    final color = style.color ?? Colors.black54;

    Widget icon = Icon(resolveIcon(name), size: size, color: color);

    if (style.backgroundColor != null || style.padding != null || style.borderRadius != null) {
      icon = Container(
        padding: style.padding ?? const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: style.borderRadius != null ? BorderRadius.circular(style.borderRadius!) : null,
        ),
        child: icon,
      );
    }

    if (node.actions.isNotEmpty && node.actions.any((a) => a.event == 'onClick')) {
      icon = GestureDetector(onTap: () => runEvent(engine, node, 'onClick'), child: icon);
    }

    return wrapEnabled(icon, enabled);
  }
}

// ---------------------------------------------------------------------------
// button
// ---------------------------------------------------------------------------

class SduiButton extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiButton({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final style = engine.styleResolver.resolve(node.style);
    final label = engine.expressionResolver.resolveString(node.props['text'] as String?);
    final variant = node.props['variant'] as String? ?? 'elevated';
    final isSubmit = node.actions.any((SduiAction a) => a.event == 'onSubmit');
    final textColor = style.color ?? Colors.white;
    final bg = style.backgroundColor ?? const Color(0xFFF5A89A);
    final radius = style.borderRadius ?? 30;

    Widget btn;

    if (variant == 'outlined') {
      btn = OutlinedButton(
        onPressed: enabled ? () {
          if (isSubmit) runEvent(engine, node, 'onSubmit');
          runEvent(engine, node, 'onClick');
        } : null,
        style: OutlinedButton.styleFrom(
          padding: style.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          side: BorderSide(color: style.borderColor ?? Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(color: style.color ?? Colors.black87, fontSize: style.fontSize ?? 14, fontWeight: style.fontWeight)),
      );
    } else if (variant == 'text') {
      btn = TextButton(
        onPressed: enabled ? () {
          if (isSubmit) runEvent(engine, node, 'onSubmit');
          runEvent(engine, node, 'onClick');
        } : null,
        child: Text(label, style: TextStyle(color: style.color ?? Theme.of(context).primaryColor, fontSize: style.fontSize ?? 14, fontWeight: style.fontWeight)),
      );
    } else {
      btn = SizedBox(
        width: style.width,
        height: style.height ?? 52,
        child: ElevatedButton(
          onPressed: enabled ? () {
            if (isSubmit) runEvent(engine, node, 'onSubmit');
            runEvent(engine, node, 'onClick');
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            disabledBackgroundColor: bg.withValues(alpha: 0.5),
            foregroundColor: textColor,
            padding: style.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          ),
          child: Text(label, style: TextStyle(fontSize: style.fontSize ?? 16, fontWeight: style.fontWeight ?? FontWeight.w600)),
        ),
      );
    }

    if (style.margin != null) btn = Padding(padding: style.margin!, child: btn);
    return btn;
  }
}

// ---------------------------------------------------------------------------
// input
// ---------------------------------------------------------------------------

class SduiInput extends StatefulWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiInput({super.key, required this.node, required this.engine, required this.enabled});

  @override
  State<SduiInput> createState() => _SduiInputState();
}

class _SduiInputState extends State<SduiInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final name = widget.node.props['name'] as String? ?? 'field';
    final stateController = Get.find<SduiStateController>();
    final initial = stateController.form[name]?.toString() ?? '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.node.props['name'] as String? ?? 'field';
    final label = widget.node.props['label'] as String?;
    final placeholder = widget.engine.expressionResolver.resolveString(widget.node.props['placeholder'] as String?);
    final obscure = widget.node.props['obscure'] == true;
    final keyboardType = widget.node.props['keyboardType'] as String?;
    final maxLength = (widget.node.props['maxLength'] as num?)?.toInt();
    final stateController = Get.find<SduiStateController>();
    final style = widget.engine.styleResolver.resolve(widget.node.style);

    TextInputType? inputType;
    if (keyboardType == 'phone') inputType = TextInputType.phone;
    if (keyboardType == 'email') inputType = TextInputType.emailAddress;
    if (keyboardType == 'number') inputType = TextInputType.number;

    Widget field = TextField(
      controller: _controller,
      enabled: widget.enabled,
      obscureText: obscure,
      keyboardType: inputType,
      maxLength: maxLength,
      buildCounter: maxLength != null ? (context, {required currentLength, required isFocused, required maxLength}) => null : null,
      style: TextStyle(fontSize: style.fontSize ?? 16),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: style.backgroundColor ?? Colors.white,
        contentPadding: style.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius ?? 12),
          borderSide: BorderSide(color: style.borderColor ?? Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius ?? 12),
          borderSide: BorderSide(color: style.borderColor ?? Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.borderRadius ?? 12),
          borderSide: BorderSide(color: style.borderColor ?? const Color(0xFFE8734A)),
        ),
      ),
      onChanged: (v) {
        stateController.setFormField(name, v);
        runEvent(widget.engine, widget.node, 'onChange');
      },
      onSubmitted: (_) => runEvent(widget.engine, widget.node, 'onSubmit'),
    );

    if (label != null) {
      field = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          field,
        ],
      );
    }

    if (style.margin != null) field = Padding(padding: style.margin!, child: field);
    return wrapEnabled(field, widget.enabled);
  }
}

// ---------------------------------------------------------------------------
// spacer
// ---------------------------------------------------------------------------

class SduiSpacer extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;

  const SduiSpacer({super.key, required this.node, required this.engine});

  @override
  Widget build(BuildContext context) {
    final h = (node.props['height'] as num?)?.toDouble();
    final w = (node.props['width'] as num?)?.toDouble();
    final flex = (node.props['flex'] as num?)?.toInt();

    if (flex != null) return Expanded(flex: flex, child: const SizedBox.shrink());
    return SizedBox(height: h, width: w);
  }
}

// ---------------------------------------------------------------------------
// expanded
// ---------------------------------------------------------------------------

class SduiExpanded extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;

  const SduiExpanded({super.key, required this.node, required this.engine});

  @override
  Widget build(BuildContext context) {
    final flex = (node.props['flex'] as num?)?.toInt() ?? 1;
    final children = engine.buildChildren(node.children);
    final child = children.isEmpty
        ? const SizedBox.shrink()
        : (children.length == 1 ? children[0] : Column(mainAxisSize: MainAxisSize.min, children: children));
    return Expanded(flex: flex, child: child);
  }
}

// ---------------------------------------------------------------------------
// scroll
// ---------------------------------------------------------------------------

class SduiScroll extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;

  const SduiScroll({super.key, required this.node, required this.engine});

  @override
  Widget build(BuildContext context) {
    final style = engine.styleResolver.resolve(node.style);
    final children = engine.buildChildren(node.children);
    final child = children.isEmpty
        ? const SizedBox.shrink()
        : (children.length == 1
            ? children[0]
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: children));
    return SingleChildScrollView(
      padding: style.padding,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// checkbox
// ---------------------------------------------------------------------------

class SduiCheckbox extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiCheckbox({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final name = node.props['name'] as String? ?? 'checkbox';
    final stateController = Get.find<SduiStateController>();
    final isChecked = stateController.form[name] == true;
    final labelSpans = node.props['spans'] as List?;
    final labelText = node.props['label'] as String? ?? '';

    Widget label;
    if (labelSpans != null && labelSpans.isNotEmpty) {
      final textSpans = <TextSpan>[];
      for (final span in labelSpans) {
        if (span is! Map) continue;
        final text = span['text'] as String? ?? '';
        final cs = span['color'] as String?;
        Color? c;
        if (cs != null) c = TokenResolver.parseColor(cs);
        textSpans.add(TextSpan(
          text: text,
          style: TextStyle(color: c ?? Colors.grey.shade600, fontSize: 13),
        ));
      }
      label = Text.rich(TextSpan(children: textSpans));
    } else {
      label = Text(labelText, style: TextStyle(fontSize: 13, color: Colors.grey.shade600));
    }

    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: isChecked,
            onChanged: enabled ? (v) {
              stateController.setFormField(name, v ?? false);
              runEvent(engine, node, 'onChange');
            } : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: Colors.grey.shade400),
            activeColor: const Color(0xFFE8734A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: label),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// otp_input
// ---------------------------------------------------------------------------

class SduiOtpInput extends StatefulWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiOtpInput({super.key, required this.node, required this.engine, required this.enabled});

  @override
  State<SduiOtpInput> createState() => _SduiOtpInputState();
}

class _SduiOtpInputState extends State<SduiOtpInput> {
  late int _length;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _length = (widget.node.props['length'] as num?)?.toInt() ?? 6;
    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.node.props['name'] as String? ?? 'otp';
    final stateController = Get.find<SduiStateController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(_length, (i) {
        return Container(
          width: 48,
          height: 52,
          margin: EdgeInsets.only(right: i < _length - 1 ? 10 : 0),
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8734A)),
              ),
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < _length - 1) {
                _focusNodes[i + 1].requestFocus();
              }
              final otp = _controllers.map((c) => c.text).join();
              stateController.setFormField(name, otp);
              if (otp.length == _length) {
                runEvent(widget.engine, widget.node, 'onChange');
              }
            },
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// divider
// ---------------------------------------------------------------------------

class SduiDivider extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;

  const SduiDivider({super.key, required this.node, required this.engine});

  @override
  Widget build(BuildContext context) {
    final style = engine.styleResolver.resolve(node.style);
    return Divider(
      color: style.color ?? Colors.grey.shade200,
      thickness: style.height ?? 1,
    );
  }
}

// ---------------------------------------------------------------------------
// grid (GridView.count shrinkWrap)
// ---------------------------------------------------------------------------

class SduiGrid extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiGrid({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = (node.props['crossAxisCount'] as num?)?.toInt() ?? 2;
    final spacing = (node.props['spacing'] as num?)?.toDouble() ?? 12;
    final childAspectRatio = (node.props['childAspectRatio'] as num?)?.toDouble() ?? 1.0;
    final children = engine.buildChildren(node.children);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

// ---------------------------------------------------------------------------
// stack
// ---------------------------------------------------------------------------

class SduiStack extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiStack({super.key, required this.node, required this.engine, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final style = engine.styleResolver.resolve(node.style);
    final children = engine.buildChildren(node.children);

    return Container(
      width: style.width,
      height: style.height,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: style.borderRadius != null ? BorderRadius.circular(style.borderRadius!) : null,
      ),
      child: Stack(children: children),
    );
  }
}

// ---------------------------------------------------------------------------
// carousel (PageView with dot indicator)
// ---------------------------------------------------------------------------

class SduiCarousel extends StatefulWidget {
  final SduiNode node;
  final LayoutEngine engine;
  final bool enabled;

  const SduiCarousel({super.key, required this.node, required this.engine, required this.enabled});

  @override
  State<SduiCarousel> createState() => _SduiCarouselState();
}

class _SduiCarouselState extends State<SduiCarousel> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = (widget.node.props['height'] as num?)?.toDouble() ?? 180;
    final style = widget.engine.styleResolver.resolve(widget.node.style);
    final children = widget.engine.buildChildren(widget.node.children);
    final count = children.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: count,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(style.borderRadius ?? 12),
                child: children[i],
              ),
            ),
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _currentPage ? const Color(0xFF333333) : Colors.grey.shade300,
              ),
            )),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// bottom_nav
// ---------------------------------------------------------------------------

class SduiBottomNav extends StatelessWidget {
  final SduiNode node;
  final LayoutEngine engine;

  const SduiBottomNav({super.key, required this.node, required this.engine});

  @override
  Widget build(BuildContext context) {
    final items = node.props['items'] as List? ?? [];
    final activeIndex = (node.props['activeIndex'] as num?)?.toInt() ?? 0;
    final activeColorStr = node.props['activeColor'] as String?;
    final activeColor = activeColorStr != null ? TokenResolver.parseColor(activeColorStr) ?? const Color(0xFFE8734A) : const Color(0xFFE8734A);

    return BottomNavigationBar(
      currentIndex: activeIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: activeColor,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: items.map<BottomNavigationBarItem>((item) {
        if (item is! Map) return const BottomNavigationBarItem(icon: Icon(Icons.circle), label: '');
        final iconName = item['icon'] as String? ?? 'circle';
        final label = item['label'] as String? ?? '';
        return BottomNavigationBarItem(
          icon: Icon(resolveIcon(iconName)),
          label: label,
        );
      }).toList(),
      onTap: (i) {
        final items_ = node.props['items'] as List? ?? [];
        if (i < items_.length) {
          final item = items_[i];
          if (item is Map && item['route'] != null) {
            Get.toNamed(item['route'] as String);
          }
        }
      },
    );
  }
}

