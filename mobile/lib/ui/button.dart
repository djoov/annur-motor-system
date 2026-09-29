import 'package:flutter/material.dart';
import '../core/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;
  final bool isOutline;

  final double? width;
  final IconData? icon;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDestructive = false,
    this.isOutline = false,
    this.width,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = isDestructive
        ? AppColors.destructive
        : (color ?? AppColors.primary);

    // Outline buttons: transparent with colored text; destructive text uses the
    // darker red for contrast.
    final Color bgColor = isOutline ? Colors.transparent : accent;
    final Color fgColor = isOutline
        ? (isDestructive ? AppColors.destructiveStrong : accent)
        : Colors.white;
    final BorderSide? side = isOutline
        ? BorderSide(
            color: isDestructive
                ? AppColors.destructive.withValues(alpha: 0.4)
                : AppColors.border,
          )
        : null;

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: side,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutline ? fgColor : AppColors.mutedForeground,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
