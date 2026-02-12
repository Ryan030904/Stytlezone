import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/admin_enums.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../utils/csv_export.dart';
import 'app_state_widgets.dart';

class PaymentContent extends StatefulWidget {
  const PaymentContent({super.key});

  @override
  State<PaymentContent> createState() => _PaymentContentState();
}

class _PaymentContentState extends State<PaymentContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PaymentProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Consumer<PaymentProvider>(
      builder: (context, provider, _) {
        final payments = provider.payments;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDarkMode, provider),
              const SizedBox(height: 16),
              _buildFilters(isDarkMode, provider),
              const SizedBox(height: 16),
              if (provider.isLoading && payments.isEmpty)
                const AppLoadingState(message: 'Đang tải dữ liệu thanh toán...')
              else if (provider.errorMessage != null && payments.isEmpty)
                AppErrorState(
                  message: provider.errorMessage!,
                  onRetry: provider.loadInitial,
                )
              else if (payments.isEmpty)
                AppEmptyState(
                  title: 'Chưa có dữ liệu thanh toán',
                  message: 'Hãy đồng bộ từ đơn hàng để tạo dữ liệu thanh toán.',
                  icon: Icons.account_balance_wallet_outlined,
                  actionLabel: 'Đồng bộ từ đơn hàng',
                  onAction: () async {
                    await provider.syncFromOrders();
                    if (!mounted) return;
                    if (provider.errorMessage == null) {
                      AppSnackBar.success(
                        context,
                        'Đã đồng bộ dữ liệu thanh toán từ đơn hàng',
                      );
                    } else {
                      AppSnackBar.error(
                        context,
                        provider.errorMessage ?? 'Đồng bộ thất bại',
                      );
                    }
                  },
                )
              else ...[
                _buildStatsRow(isDarkMode, payments),
                const SizedBox(height: 16),
                _buildTable(isDarkMode, payments, provider),
                const SizedBox(height: 12),
                if (provider.hasMore)
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton.icon(
                      onPressed: provider.isLoadingMore
                          ? null
                          : () => provider.loadMore(),
                      icon: provider.isLoadingMore
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more_rounded),
                      label: Text(
                        provider.isLoadingMore
                            ? 'Đang tải...'
                            : 'Tải thêm thanh toán',
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDarkMode, PaymentProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thanh toán / Đối soát',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dữ liệu thanh toán thực tế từ Firestore',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.textLight,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: provider.isSyncing
                  ? null
                  : () async {
                      await provider.syncFromOrders();
                      if (!mounted) return;
                      if (provider.errorMessage == null) {
                        AppSnackBar.success(
                          context,
                          'Đã đồng bộ thanh toán từ đơn hàng',
                        );
                      } else {
                        AppSnackBar.error(
                          context,
                          provider.errorMessage ?? 'Đồng bộ thất bại',
                        );
                      }
                    },
              icon: provider.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(provider.isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ đơn hàng'),
            ),
            OutlinedButton.icon(
              onPressed: () => _exportCsvCurrent(provider),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Xuất bộ lọc hiện tại'),
            ),
            ElevatedButton.icon(
              onPressed: () => _confirmExportAll(provider),
              icon: const Icon(Icons.file_download_rounded, size: 18),
              label: const Text('Xuất tất cả'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(bool isDarkMode, PaymentProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchController,
              onChanged: provider.setSearchQuery,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Tìm mã đơn, khách hàng, số điện thoại...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<PaymentStatus?>(
              key: ValueKey(provider.statusFilter),
              initialValue: provider.statusFilter,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Trạng thái thanh toán',
              ),
              items: [
                const DropdownMenuItem<PaymentStatus?>(
                  value: null,
                  child: Text('Tất cả trạng thái'),
                ),
                ...PaymentStatus.values.map(
                  (status) => DropdownMenuItem<PaymentStatus?>(
                    value: status,
                    child: Text(status.label),
                  ),
                ),
              ],
              onChanged: (value) => provider.setStatusFilter(value),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<PaymentMethod?>(
              key: ValueKey(provider.methodFilter),
              initialValue: provider.methodFilter,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Phương thức thanh toán',
              ),
              items: [
                const DropdownMenuItem<PaymentMethod?>(
                  value: null,
                  child: Text('Tất cả phương thức'),
                ),
                ...PaymentMethod.values.map(
                  (method) => DropdownMenuItem<PaymentMethod?>(
                    value: method,
                    child: Text(method.label),
                  ),
                ),
              ],
              onChanged: (value) => provider.setMethodFilter(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDarkMode, List<PaymentModel> payments) {
    final paid = payments
        .where(
          (p) =>
              p.status == PaymentStatus.paid ||
              p.status == PaymentStatus.reconciled,
        )
        .fold<double>(0, (sum, p) => sum + p.amount);
    final pending = payments
        .where((p) => p.status == PaymentStatus.pending)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final refunded = payments.fold<double>(
      0,
      (sum, p) => sum + p.refundedAmount,
    );

    final List<(String, String, IconData)> cards = [
      (
        'Tổng giao dịch',
        payments.length.toString(),
        Icons.receipt_long_rounded,
      ),
      ('Đã thanh toán', _money(paid), Icons.check_circle_rounded),
      ('Chờ xử lý', _money(pending), Icons.timelapse_rounded),
      ('Đã hoàn tiền', _money(refunded), Icons.replay_rounded),
    ];

    return Row(
      children: cards.map((item) {
        final isLast = item == cards.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppTheme.borderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(item.$3, color: const Color(0xFF7C3AED)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTable(
    bool isDarkMode,
    List<PaymentModel> payments,
    PaymentProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        children: [
          _tableHeader(isDarkMode),
          ...payments.map(
            (payment) => _tableRow(isDarkMode, payment, provider),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : AppTheme.lightBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          _headerText('Đơn hàng', 2, isDarkMode),
          _headerText('Khách hàng', 2, isDarkMode),
          _headerText('Số tiền', 1, isDarkMode),
          _headerText('Phương thức', 1, isDarkMode),
          _headerText('Trạng thái', 1, isDarkMode),
          _headerText('Thời gian', 1, isDarkMode),
          _headerText('Thao tác', 2, isDarkMode),
        ],
      ),
    );
  }

  Widget _headerText(String text, int flex, bool isDarkMode) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _tableRow(
    bool isDarkMode,
    PaymentModel payment,
    PaymentProvider provider,
  ) {
    final statusColor = _statusColor(payment.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              payment.orderCode.isEmpty ? payment.orderId : payment.orderCode,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  payment.customerName.isEmpty ? '--' : payment.customerName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white : AppTheme.textDark,
                  ),
                ),
                Text(
                  payment.customerPhone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _money(payment.amount),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              payment.method.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                payment.status.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _dateTime(payment.paidAt ?? payment.createdAt),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textLight,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              children: [
                _actionButton(
                  icon: Icons.check_rounded,
                  color: const Color(0xFF10B981),
                  tooltip: 'Đánh dấu đã thanh toán',
                  onTap:
                      payment.status == PaymentStatus.paid ||
                          payment.status == PaymentStatus.reconciled
                      ? null
                      : () => _markPaid(provider, payment),
                ),
                _actionButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFEF4444),
                  tooltip: 'Đánh dấu thất bại',
                  onTap: payment.status == PaymentStatus.failed
                      ? null
                      : () => _markFailed(provider, payment),
                ),
                _actionButton(
                  icon: Icons.replay_rounded,
                  color: const Color(0xFFF59E0B),
                  tooltip: 'Hoàn tiền',
                  onTap: () => _refund(provider, payment),
                ),
                _actionButton(
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF3B82F6),
                  tooltip: 'Đối soát',
                  onTap: payment.status == PaymentStatus.reconciled
                      ? null
                      : () => _reconcile(provider, payment),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: onTap == null ? Colors.grey : color),
      onPressed: onTap,
      tooltip: tooltip,
    );
  }

  Future<void> _markPaid(PaymentProvider provider, PaymentModel payment) async {
    final note = await _askNote(
      'Xác nhận thanh toán',
      'Ghi chú xác nhận (không bắt buộc)',
    );
    if (note == null) return;
    final success = await provider.markAsPaid(
      paymentId: payment.id,
      note: note,
    );
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(context, 'Đã cập nhật trạng thái đã thanh toán');
    } else {
      AppSnackBar.error(context, provider.errorMessage ?? 'Cập nhật thất bại');
    }
  }

  Future<void> _markFailed(
    PaymentProvider provider,
    PaymentModel payment,
  ) async {
    final note = await _askNote('Đánh dấu thất bại', 'Lý do thất bại');
    if (note == null) return;
    final success = await provider.markAsFailed(
      paymentId: payment.id,
      note: note,
    );
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(context, 'Đã cập nhật trạng thái thất bại');
    } else {
      AppSnackBar.error(context, provider.errorMessage ?? 'Cập nhật thất bại');
    }
  }

  Future<void> _refund(PaymentProvider provider, PaymentModel payment) async {
    final result = await _askRefund(payment.amount);
    if (result == null) return;
    final amount = result.$1;
    final note = result.$2;
    final success = await provider.refund(
      paymentId: payment.id,
      amount: amount,
      note: note,
    );
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(context, 'Hoàn tiền thành công');
    } else {
      AppSnackBar.error(context, provider.errorMessage ?? 'Hoàn tiền thất bại');
    }
  }

  Future<void> _reconcile(
    PaymentProvider provider,
    PaymentModel payment,
  ) async {
    final note = await _askNote('Đối soát thanh toán', 'Ghi chú đối soát');
    if (note == null) return;
    final success = await provider.reconcile(paymentId: payment.id, note: note);
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(context, 'Đã đối soát thanh toán');
    } else {
      AppSnackBar.error(context, provider.errorMessage ?? 'Đối soát thất bại');
    }
  }

  Future<String?> _askNote(String title, String hint) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return value;
  }

  Future<(double, String)?> _askRefund(double maxAmount) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<(double, String)>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hoàn tiền thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Số tiền <= ${maxAmount.toStringAsFixed(0)}',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Lý do hoàn tiền',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0 || amount > maxAmount) {
                  AppSnackBar.error(
                    context,
                    'Số tiền hoàn phải > 0 và <= số tiền thanh toán',
                  );
                  return;
                }
                Navigator.pop(context, (amount, noteController.text.trim()));
              },
              child: const Text('Hoàn tiền'),
            ),
          ],
        );
      },
    );
    amountController.dispose();
    noteController.dispose();
    return result;
  }

  Future<void> _exportCsvCurrent(PaymentProvider provider) async {
    final rows = await provider.exportCurrentFilter();
    if (rows.isEmpty) {
      if (!mounted) return;
      AppSnackBar.info(context, 'Không có dữ liệu để xuất');
      return;
    }
    CsvExport.download(
      filename: 'payments_filtered.csv',
      headers: const [
        'id',
        'orderCode',
        'customerName',
        'customerPhone',
        'amount',
        'method',
        'status',
        'source',
        'paidAt',
        'createdAt',
        'note',
      ],
      rows: rows
          .map(
            (p) => [
              p.id,
              p.orderCode,
              p.customerName,
              p.customerPhone,
              p.amount,
              p.method.name,
              p.status.name,
              p.source,
              p.paidAt?.toIso8601String() ?? '',
              p.createdAt.toIso8601String(),
              p.note,
            ],
          )
          .toList(),
    );
    if (!mounted) return;
    AppSnackBar.success(context, 'Đã xuất bộ lọc hiện tại ra CSV');
  }

  Future<void> _confirmExportAll(PaymentProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xuất tất cả thanh toán'),
          content: const Text(
            'Xuất toàn bộ dữ liệu có thể chậm nếu tập dữ liệu lớn. Tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xuất tất cả'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final rows = await provider.exportAll();
    if (rows.isEmpty) {
      if (!mounted) return;
      AppSnackBar.info(context, 'Không có dữ liệu để xuất');
      return;
    }
    CsvExport.download(
      filename: 'payments_all.csv',
      headers: const [
        'id',
        'orderCode',
        'customerName',
        'customerPhone',
        'amount',
        'method',
        'status',
        'source',
        'paidAt',
        'createdAt',
        'note',
      ],
      rows: rows
          .map(
            (p) => [
              p.id,
              p.orderCode,
              p.customerName,
              p.customerPhone,
              p.amount,
              p.method.name,
              p.status.name,
              p.source,
              p.paidAt?.toIso8601String() ?? '',
              p.createdAt.toIso8601String(),
              p.note,
            ],
          )
          .toList(),
    );
    if (!mounted) return;
    AppSnackBar.success(context, 'Đã xuất toàn bộ thanh toán ra CSV');
  }

  Color _statusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return const Color(0xFFF59E0B);
      case PaymentStatus.paid:
        return const Color(0xFF10B981);
      case PaymentStatus.failed:
        return const Color(0xFFEF4444);
      case PaymentStatus.refunded:
        return const Color(0xFF3B82F6);
      case PaymentStatus.partialRefunded:
        return const Color(0xFF06B6D4);
      case PaymentStatus.reconciled:
        return const Color(0xFF7C3AED);
    }
  }

  String _money(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }

  String _dateTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final mo = value.month.toString().padLeft(2, '0');
    return '$d/$mo/${value.year} $h:$m';
  }
}
