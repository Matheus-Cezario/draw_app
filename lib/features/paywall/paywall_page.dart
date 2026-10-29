import 'package:flutter/material.dart';

import '../../core/billing/entitlement_service.dart';
import '../../core/billing/plan_limits.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/kid_ui.dart';

/// Offers the subscription. Closes itself once the user becomes a subscriber.
class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key, this.reason});

  /// Why the paywall opened, shown on top ("Free plan has 3 drawings").
  final String? reason;

  /// Opens the paywall and returns whether the user is a subscriber after it.
  static Future<bool> show(BuildContext context, {String? reason}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaywallPage(reason: reason)),
    );
    return EntitlementService.instance.isPremium;
  }

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  @override
  void initState() {
    super.initState();
    final service = EntitlementService.instance;
    if (service.products.isEmpty) service.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final reason = widget.reason;
    final service = EntitlementService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (service.isPremium) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
        }
        return Scaffold(
          backgroundColor: AppColors.board,
          appBar: AppBar(
            backgroundColor: AppColors.appBar,
            surfaceTintColor: Colors.transparent,
            shape: const Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
            leadingWidth: 60,
            leading: Center(
              child: RoundSticker(
                icon: Icons.close_rounded,
                color: AppColors.back,
                tooltip: 'Close',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            title: Text('Color Fun Plus', style: kidText(22, weight: 700)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (reason != null) ...[
                Text(reason,
                    textAlign: TextAlign.center, style: kidText(20, weight: 600)),
                const SizedBox(height: 16),
              ],
              _Benefit(Icons.all_inclusive_rounded, 'Unlimited drawings'),
              const SizedBox(height: 12),
              _Benefit(Icons.ios_share_rounded, 'Export your art as PNG'),
              const SizedBox(height: 12),
              _Benefit(Icons.block_rounded, 'No ads'),
              const SizedBox(height: 20),
              Text(
                'Free plan: up to $freeDrawingLimit drawings, no export, with ads.',
                textAlign: TextAlign.center,
                style: kidText(15, weight: 500, color: AppColors.disabledText),
              ),
              const SizedBox(height: 20),
              if (service.products.isEmpty && service.loadingProducts)
                const Center(child: CircularProgressIndicator(color: AppColors.ink))
              else if (service.products.isEmpty) ...[
                Text('Plans are not available right now.',
                    textAlign: TextAlign.center, style: kidText(18)),
                if (service.productsProblem != null) ...[
                  const SizedBox(height: 8),
                  Text(service.productsProblem!,
                      textAlign: TextAlign.center,
                      style: kidText(14, weight: 500, color: AppColors.disabledText)),
                ],
                const SizedBox(height: 12),
                Center(
                  child: StickerChoice(
                    label: 'Try again',
                    selected: false,
                    icon: Icons.refresh_rounded,
                    onTap: service.loadProducts,
                  ),
                ),
              ] else
                for (final product in service.products) ...[
                  StickerChoice(
                    label: '${product.title.split(' (').first} · ${product.price}',
                    selected: true,
                    color: AppColors.go,
                    icon: Icons.star_rounded,
                    onTap: service.busy ? () {} : () => service.buy(product),
                  ),
                  const SizedBox(height: 12),
                ],
              if (service.busy)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator(color: AppColors.ink)),
                ),
              if (service.error != null)
                Text(service.error!,
                    textAlign: TextAlign.center,
                    style: kidText(15, color: AppColors.danger)),
              const SizedBox(height: 8),
              Center(
                child: StickerChoice(
                  label: 'Restore purchases',
                  selected: false,
                  onTap: service.busy ? () {} : service.restore,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: AppColors.accentPurple),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: kidText(20, weight: 700))),
        ],
      ),
    );
  }
}
