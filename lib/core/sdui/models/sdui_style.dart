import 'package:flutter/material.dart';

class SduiResolvedStyle {
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Border? border;
  final Color? borderColor;
  final double? borderWidth;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final double? width;
  final double? height;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final TextAlign? textAlign;
  final double? elevation;
  final double? opacity;
  final int? flex;
  final double? gap;
  final int? maxLines;
  final double? letterSpacing;
  final double? lineHeight;
  final TextOverflow? textOverflow;
  final MainAxisSize? mainAxisSize;
  final TextDecoration? textDecoration;

  const SduiResolvedStyle({
    this.backgroundColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.borderColor,
    this.borderWidth,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.width,
    this.height,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.textAlign,
    this.elevation,
    this.opacity,
    this.flex,
    this.gap,
    this.maxLines,
    this.letterSpacing,
    this.lineHeight,
    this.textOverflow,
    this.mainAxisSize,
    this.textDecoration,
  });

  SduiResolvedStyle merge(SduiResolvedStyle other) {
    return SduiResolvedStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      padding: other.padding ?? padding,
      margin: other.margin ?? margin,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      fontSize: other.fontSize ?? fontSize,
      fontWeight: other.fontWeight ?? fontWeight,
      color: other.color ?? color,
      width: other.width ?? width,
      height: other.height ?? height,
      mainAxisAlignment: other.mainAxisAlignment ?? mainAxisAlignment,
      crossAxisAlignment: other.crossAxisAlignment ?? crossAxisAlignment,
      textAlign: other.textAlign ?? textAlign,
      elevation: other.elevation ?? elevation,
      opacity: other.opacity ?? opacity,
      flex: other.flex ?? flex,
      gap: other.gap ?? gap,
      maxLines: other.maxLines ?? maxLines,
      letterSpacing: other.letterSpacing ?? letterSpacing,
      lineHeight: other.lineHeight ?? lineHeight,
      textOverflow: other.textOverflow ?? textOverflow,
      mainAxisSize: other.mainAxisSize ?? mainAxisSize,
      textDecoration: other.textDecoration ?? textDecoration,
    );
  }
}
