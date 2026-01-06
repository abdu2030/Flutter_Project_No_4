import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String roleText;
  final IconData icon;

  const DashboardHeader({
    super.key,
    required this.roleText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              roleText,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }
}
