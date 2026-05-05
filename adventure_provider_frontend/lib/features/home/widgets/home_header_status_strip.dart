import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Frosted pill under the green header (Home / Groups, etc.).
class HomeHeaderStatusStrip extends StatelessWidget {
  const HomeHeaderStatusStrip({
    super.key,
    this.message = 'Perfect weather for an adventure',
    this.trailingLabel = 'Ready',
    this.leadingIcon = Icons.wb_sunny_outlined,
    this.leadingIconColor = const Color(0xFFF7B731),
    this.trailingIcon = Icons.terrain,
  });

  final String message;
  final String trailingLabel;
  final IconData leadingIcon;
  final Color leadingIconColor;
  final IconData trailingIcon;

  static const _accent = Color(0xFF52B788);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      leadingIcon,
                      color: leadingIconColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    trailingIcon,
                    color: _accent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trailingLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
