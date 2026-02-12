import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/admin_enums.dart';
import '../models/audit_log_model.dart';
import '../providers/audit_log_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../utils/csv_export.dart';
import 'app_state_widgets.dart';

class AuditLogContent extends StatefulWidget {
  const AuditLogContent({super.key});

  @override
  State<AuditLogContent> createState() => _AuditLogContentState();
}

class _AuditLogContentState extends State<AuditLogContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuditLogProvider>().loadInitial();
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
    return Consumer<AuditLogProvider>(
      builder: (context, provider, _) {
        final logs = provider.logs;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDarkMode, provider),
              const SizedBox(height: 16),
              _buildFilters(isDarkMode, provider),
              const SizedBox(height: 16),
              if (provider.isLoading && logs.isEmpty)
                const AppLoadingState(message: 'Đang tải nhật ký hệ thống...')
              else if (provider.errorMessage != null && logs.isEmpty)
                AppErrorState(
                  message: provider.errorMessage!,
                  onRetry: provider.loadInitial,
                )
              else if (logs.isEmpty)
                const AppEmptyState(
                  title: 'Chưa có nhật ký',
                  message:
                      'Các thao tác trong trang quản trị sẽ được ghi nhận tại đây.',
                  icon: Icons.history_toggle_off_rounded,
                )
              else ...[
                _buildTable(isDarkMode, logs),
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
                            : 'Tải thêm nhật ký',
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

  Widget _buildHeader(bool isDarkMode, AuditLogProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhật ký hệ thống',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Theo dõi lịch sử thao tác của quản trị viên',
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
              onPressed: provider.loadInitial,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Làm mới'),
            ),
            OutlinedButton.icon(
              onPressed: () => _exportCurrent(provider),
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

  Widget _buildFilters(bool isDarkMode, AuditLogProvider provider) {
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
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchController,
              onChanged: provider.setSearchQuery,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Tìm mô tả, mã đối tượng, người thực hiện...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<AuditEntity?>(
              key: ValueKey(provider.selectedEntity),
              initialValue: provider.selectedEntity,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Đối tượng',
              ),
              items: [
                const DropdownMenuItem<AuditEntity?>(
                  value: null,
                  child: Text('Tất cả đối tượng'),
                ),
                ...AuditEntity.values.map(
                  (entity) => DropdownMenuItem<AuditEntity?>(
                    value: entity,
                    child: Text(_entityLabel(entity)),
                  ),
                ),
              ],
              onChanged: (value) => provider.setEntityFilter(value),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<AuditAction?>(
              key: ValueKey(provider.selectedAction),
              initialValue: provider.selectedAction,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Hành động',
              ),
              items: [
                const DropdownMenuItem<AuditAction?>(
                  value: null,
                  child: Text('Tất cả hành động'),
                ),
                ...AuditAction.values.map(
                  (action) => DropdownMenuItem<AuditAction?>(
                    value: action,
                    child: Text(action.label),
                  ),
                ),
              ],
              onChanged: (value) => provider.setActionFilter(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(bool isDarkMode, List<AuditLogModel> logs) {
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
          ...logs.map((log) => _tableRow(isDarkMode, log)),
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
          _headerText('Thời gian', 2, isDarkMode),
          _headerText('Người thực hiện', 2, isDarkMode),
          _headerText('Hành động', 1, isDarkMode),
          _headerText('Đối tượng', 1, isDarkMode),
          _headerText('Mã đối tượng', 2, isDarkMode),
          _headerText('Mô tả', 3, isDarkMode),
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

  Widget _tableRow(bool isDarkMode, AuditLogModel log) {
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
              _dateTime(log.createdAt),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.actorEmail.isNotEmpty ? log.actorEmail : log.actorUid,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              log.action.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _actionColor(log.action),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _entityLabel(log.entity),
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
            child: Text(
              log.entityId,
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
            flex: 3,
            child: Text(
              _summaryLabel(log.summary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCurrent(AuditLogProvider provider) async {
    final rows = await provider.exportCurrentFilter();
    if (rows.isEmpty) {
      if (!mounted) return;
      AppSnackBar.info(context, 'Không có nhật ký để xuất');
      return;
    }
    CsvExport.download(
      filename: 'audit_logs_filtered.csv',
      headers: const [
        'id',
        'createdAt',
        'action',
        'entity',
        'entityId',
        'summary',
        'oldSummary',
        'newSummary',
        'actorUid',
        'actorEmail',
        'ipAddress',
      ],
      rows: rows
          .map(
            (log) => [
              log.id,
              log.createdAt.toIso8601String(),
              log.action.name,
              log.entity.name,
              log.entityId,
              log.summary,
              log.oldSummary,
              log.newSummary,
              log.actorUid,
              log.actorEmail,
              log.ipAddress,
            ],
          )
          .toList(),
    );
    if (!mounted) return;
    AppSnackBar.success(context, 'Đã xuất bộ lọc nhật ký hiện tại');
  }

  Future<void> _confirmExportAll(AuditLogProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xuất toàn bộ nhật ký'),
          content: const Text(
            'Xuất toàn bộ nhật ký có thể mất thời gian nếu dữ liệu lớn. Tiếp tục?',
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
      AppSnackBar.info(context, 'Không có nhật ký để xuất');
      return;
    }
    CsvExport.download(
      filename: 'audit_logs_all.csv',
      headers: const [
        'id',
        'createdAt',
        'action',
        'entity',
        'entityId',
        'summary',
        'oldSummary',
        'newSummary',
        'actorUid',
        'actorEmail',
        'ipAddress',
      ],
      rows: rows
          .map(
            (log) => [
              log.id,
              log.createdAt.toIso8601String(),
              log.action.name,
              log.entity.name,
              log.entityId,
              log.summary,
              log.oldSummary,
              log.newSummary,
              log.actorUid,
              log.actorEmail,
              log.ipAddress,
            ],
          )
          .toList(),
    );
    if (!mounted) return;
    AppSnackBar.success(context, 'Đã xuất toàn bộ nhật ký');
  }

  Color _actionColor(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return const Color(0xFF10B981);
      case AuditAction.update:
        return const Color(0xFF3B82F6);
      case AuditAction.delete:
      case AuditAction.softDelete:
        return const Color(0xFFEF4444);
      case AuditAction.login:
      case AuditAction.logout:
        return const Color(0xFF7C3AED);
      case AuditAction.reconcile:
        return const Color(0xFF06B6D4);
      case AuditAction.refund:
        return const Color(0xFFF59E0B);
      case AuditAction.restore:
      case AuditAction.statusChange:
      case AuditAction.exportCsv:
        return const Color(0xFF8B5CF6);
    }
  }

  String _dateTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final mo = value.month.toString().padLeft(2, '0');
    return '$d/$mo/${value.year} $h:$m';
  }

  String _entityLabel(AuditEntity entity) {
    switch (entity) {
      case AuditEntity.category:
        return 'Danh mục';
      case AuditEntity.product:
        return 'Sản phẩm';
      case AuditEntity.order:
        return 'Đơn hàng';
      case AuditEntity.shipment:
        return 'Vận chuyển';
      case AuditEntity.promotion:
        return 'Khuyến mãi';
      case AuditEntity.payment:
        return 'Thanh toán';
      case AuditEntity.customer:
        return 'Khách hàng';
      case AuditEntity.cms:
        return 'CMS';
      case AuditEntity.report:
        return 'Báo cáo';
      case AuditEntity.warehouseReceipt:
        return 'Phiếu kho';
      case AuditEntity.rma:
        return 'Đổi trả';
      case AuditEntity.setting:
        return 'Cài đặt';
      case AuditEntity.auth:
        return 'Xác thực';
    }
  }

  String _summaryLabel(String summary) {
    final text = summary.trim();
    if (text.isEmpty) return '-';

    final syncedMatch = RegExp(
      r'^Synced (\d+) payments from orders$',
      caseSensitive: false,
    ).firstMatch(text);
    if (syncedMatch != null) {
      return 'Đã đồng bộ ${syncedMatch.group(1)} thanh toán từ đơn hàng';
    }

    if (RegExp(r'^Admin login$', caseSensitive: false).hasMatch(text)) {
      return 'Quản trị viên đăng nhập';
    }
    if (RegExp(r'^Admin logout$', caseSensitive: false).hasMatch(text)) {
      return 'Quản trị viên đăng xuất';
    }
    if (RegExp(
      r'^Update order status to ',
      caseSensitive: false,
    ).hasMatch(text)) {
      return text.replaceFirst(
        RegExp(r'^Update order status to ', caseSensitive: false),
        'Cập nhật trạng thái đơn hàng thành ',
      );
    }
    if (RegExp(r'^Update product ', caseSensitive: false).hasMatch(text)) {
      return text.replaceFirst(
        RegExp(r'^Update product ', caseSensitive: false),
        'Cập nhật sản phẩm ',
      );
    }

    return text;
  }
}
