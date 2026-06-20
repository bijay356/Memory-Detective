import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_panel.dart';
import '../theme/app_theme.dart';

class DetectiveCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? icon;
  final VoidCallback onTap;
  final bool isLocked;
  final Widget? actionWidget;

  const DetectiveCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.isLocked = false,
    this.actionWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.6 : 1.0,
        child: GlassPanel(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useStackedAction =
                  actionWidget != null && constraints.maxWidth < 380;
              final trailing = isLocked
                  ? const Icon(Icons.lock, color: AppTheme.textSecondary)
                  : actionWidget;

              final contentRow = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: icon!,
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null && !useStackedAction) ...[
                    const SizedBox(width: 12),
                    Flexible(child: trailing),
                  ],
                ],
              );

              if (!useStackedAction) return contentRow;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  contentRow,
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: actionWidget!,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
