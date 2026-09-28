import 'package:flutter/material.dart';

import '../core/logic.dart';
import '../data/models.dart';
import 'theme.dart';

class StatusBody extends StatelessWidget {
  const StatusBody({
    super.key,
    required this.status,
    required this.child,
    this.message,
    this.onRetry,
    this.actionLabel = 'Try again',
  });

  final ViewStatus status;
  final Widget child;
  final String? message;
  final VoidCallback? onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ViewStatus.loading => const Center(child: CircularProgressIndicator()),
      ViewStatus.offline => _Notice(
          icon: Icons.wifi_off,
          title: 'Offline',
          message: message ?? 'The Mercer API is unreachable. Check the connection and try again.',
          onRetry: onRetry,
          actionLabel: actionLabel,
        ),
      ViewStatus.serverError => _Notice(
          icon: Icons.cloud_off,
          title: 'Server error',
          message: message ?? 'The server returned an error. Nothing was charged.',
          onRetry: onRetry,
          actionLabel: actionLabel,
        ),
      ViewStatus.empty => _Notice(
          icon: Icons.inbox_outlined,
          title: 'Nothing here',
          message: message ?? 'No results yet.',
          onRetry: onRetry,
          actionLabel: actionLabel,
        ),
      ViewStatus.data => child,
    };
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    required this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: ink),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductArtwork extends StatelessWidget {
  const ProductArtwork({super.key, required this.hue, required this.category, this.radius = 14});

  final int hue;
  final String category;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final base = HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.42).toColor();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(color: base),
        child: Center(
          child: Icon(_icon(category), color: Colors.white, size: 36),
        ),
      ),
    );
  }

  IconData _icon(String category) {
    return switch (category) {
      'Kitchen' => Icons.soup_kitchen_outlined,
      'Grocery' => Icons.local_grocery_store_outlined,
      'Wellness' => Icons.spa_outlined,
      'Stationery' => Icons.edit_outlined,
      _ => Icons.inventory_2_outlined,
    };
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.saved,
    required this.onOpen,
    required this.onSave,
    required this.onAdd,
  });

  final Product product;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ProductArtwork(hue: product.hue, category: product.category)),
              const SizedBox(height: 8),
              Text(product.category.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1, color: Color(0xFF66707A))),
              Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              Row(
                children: [
                  Text(money(product.price), style: const TextStyle(color: amber, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(visualDensity: VisualDensity.compact, onPressed: onSave, icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: saved ? amber : ink)),
                  IconButton(visualDensity: VisualDensity.compact, onPressed: onAdd, icon: const Icon(Icons.add_shopping_cart)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
