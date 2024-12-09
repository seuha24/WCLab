import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:safelight/core/utils/app_sizes.dart';

class Gap extends StatelessWidget {
  const Gap({
    super.key,
    this.height,
    this.width,
  });

  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.scaledHeight(height ?? 14),
      width: AppSizes.scaledWidth(width ?? 14)
    );
  }
}