import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constantscolors.dart';
import '../../services/auth_provider.dart';
import '../../services/dash_board_provider.dart';
import '../../widgets/low_stock_tile.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/sales_hero_card.dart';
import '../../widgets/stat_cards.dart';
import '../../services/product_provider.dart';
import '../products/product_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final lowStock = products.lowStock;
    final user = context.watch<AuthProvider>().user;
    final data = context.watch<DashboardProvider>();
    final money = NumberFormat('#,##0');

    // First name only, falls back to "there" if no name is saved
    final firstName = (user?.displayName ?? '').trim().split(' ').first;
    final name = firstName.isEmpty ? 'there' : firstName;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Header ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.textGrey,
                    ),
                    onPressed: () => context.read<AuthProvider>().logout(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---------- Hero card ----------
              SalesHeroCard(
                sales: data.todaySales,
                growthPercent: data.growthPercent,
                weeklySales: data.weeklySales,
              ),
              const SizedBox(height: 16),

              // ---------- 2x2 stat cards ----------
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Products',
                      value: '${products.products.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.warning_amber_rounded,
                      label: 'Low stock',
                      value: '${lowStock.length}',
                      isWarning: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Items sold',
                      value: '${data.itemsSold}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Profit',
                      value: 'Rs ${money.format(data.todayProfit)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------- Quick actions ----------
              const Text(
                'Quick actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.south_west_rounded,
                      label: 'Stock in',
                      onTap: () {
                        // TODO: open Stock In screen
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.north_east_rounded,
                      label: 'Stock out',
                      onTap: () {
                        // TODO: open Stock Out screen
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan',
                      onTap: () {
                        // TODO: open Barcode Scanner screen
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------- Low stock list ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Low stock (${lowStock.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(
                            initialLowStockOnly: true,
                          ),
                        ),
                      );
                    },
                    child: (Text("see all")),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (lowStock.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'All products are well stocked.',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                )
              else
                // Show only the first 3 on the dashboard
                ...lowStock
                    .take(3)
                    .map(
                      (item) => LowStockTile(
                        name: item.name,
                        quantity: item.quantity,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
