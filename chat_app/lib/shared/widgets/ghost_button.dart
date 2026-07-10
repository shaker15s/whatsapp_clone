import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../../core/theme/app_colors.dart';

class GhostButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool loading;
  final IconData? icon;

  const GhostButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        opacity: 0.02,
        blur: 10,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.0,
        ),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
