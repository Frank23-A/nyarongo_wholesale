import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/models/order_model.dart';
import 'package:nyarongo_wholesale/services/order_service.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';

enum OrdersViewMode { customer, admin }

class OrdersScreen extends StatefulWidget {
  final OrdersViewMode mode;
  final String title;
  final String customerId;
  final bool embedded;

  const OrdersScreen({
    super.key,
    required this.mode,
    required this.title,
    this.customerId = 'customer_demo',
    this.embedded = false,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = const OrderService();
  String selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final ordersStream = widget.mode == OrdersViewMode.admin
        ? _orderService.watchAllOrders()
        : _orderService.watchCustomerOrders(widget.customerId);

    final content = Padding(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: StreamBuilder<List<OrderModel>>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _OrdersErrorState(message: snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          final filteredOrders = selectedStatus == 'All'
              ? orders
              : orders
                  .where((order) => order.status == selectedStatus.toLowerCase())
                  .toList(growable: false);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.embedded) ...[
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 18),
              ],
              _OrdersSummary(
                totalOrders: orders.length,
                pendingOrders:
                    orders.where((order) => order.status == 'pending').length,
                deliveredOrders:
                    orders.where((order) => order.status == 'delivered').length,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      ['All', 'Pending', 'Confirmed', 'Shipped', 'Delivered']
                          .map(
                            (status) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: Text(status),
                                selected: selectedStatus == status,
                                onSelected: (_) {
                                  setState(() => selectedStatus = status);
                                },
                                selectedColor:
                                    widget.mode == OrdersViewMode.admin
                                        ? const Color(0xFFD97B14)
                                        : const Color(0xFF4F9B66),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: selectedStatus == status
                                      ? Colors.white
                                      : AppConstants.textPrimaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                                side: BorderSide.none,
                              ),
                            ),
                          )
                          .toList(growable: false),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: filteredOrders.isEmpty
                    ? const Center(
                        child: Text('No orders match this filter yet.'),
                      )
                    : ListView.separated(
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _OrderCard(
                            order: order,
                            isAdmin: widget.mode == OrdersViewMode.admin,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: content,
    );
  }
}

class _OrdersSummary extends StatelessWidget {
  final int totalOrders;
  final int pendingOrders;
  final int deliveredOrders;

  const _OrdersSummary({
    required this.totalOrders,
    required this.pendingOrders,
    required this.deliveredOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'Total', value: '$totalOrders')),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(label: 'Pending', value: '$pendingOrders'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(label: 'Delivered', value: '$deliveredOrders'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isAdmin;

  const _OrderCard({
    required this.order,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isAdmin ? const Color(0xFFD97B14) : const Color(0xFF4F9B66);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _StatusBadge(status: order.status, color: accentColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${order.productIds.length} items',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Created ${_formatDate(order.createdAt)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'KSh ${order.totalAmount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            Text(
              'Customer: ${order.customerId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  final String message;

  const _OrdersErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44),
            const SizedBox(height: 12),
            Text(
              'Could not load orders from the database.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
