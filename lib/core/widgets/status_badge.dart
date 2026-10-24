import 'package:flutter/material.dart';
import '../../features/orders/domain/order_status.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool showIcon;
  final double fontSize;
  final bool useShortName;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
    this.useShortName = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = useShortName ? status.shortDisplayName : status.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: fontSize + 2, color: status.color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status.color,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
