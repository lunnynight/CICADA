import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../services/update_service.dart';

/// Builds the update risk confirmation dialog.
/// Returns true if user confirms, false if cancelled.
Widget buildUpdateRiskDialog(BuildContext ctx) {
  return AlertDialog(
    backgroundColor: CicadaColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: CicadaColors.alert),
    ),
    icon: const Icon(
      Icons.warning_amber,
      color: CicadaColors.alert,
      size: 48,
    ),
    title: const Text('更新风险提示'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '软件更新存在以下风险，请谨慎操作：',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildRiskItem('更新过程中可能出现意外中断，导致软件无法启动'),
        _buildRiskItem('新版本可能与现有配置不兼容'),
        _buildRiskItem('网络问题可能导致更新文件损坏'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CicadaColors.alert.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CicadaColors.alert.withAlpha(100)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: CicadaColors.alert, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '建议：更新前创建备份，以便在出现问题时回滚',
                  style: TextStyle(color: CicadaColors.alert, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx, false),
        child: const Text('取消更新'),
      ),
      FilledButton.icon(
        onPressed: () => Navigator.pop(ctx, true),
        icon: const Icon(Icons.warning, size: 16),
        label: const Text('我已了解风险，继续更新'),
        style: FilledButton.styleFrom(backgroundColor: CicadaColors.alert),
      ),
    ],
  );
}

Widget _buildRiskItem(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: CicadaColors.alert)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}

/// Builds the backup confirmation dialog.
/// Returns true if user wants backup, false if no backup, null if cancelled.
Widget buildBackupConfirmDialog(BuildContext ctx) {
  return AlertDialog(
    backgroundColor: CicadaColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: CicadaColors.border),
    ),
    title: const Text('备份确认'),
    content: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('是否在更新前创建备份？'),
        SizedBox(height: 8),
        Text(
          '备份后可以在更新失败时恢复到当前版本。',
          style: TextStyle(fontSize: 12, color: CicadaColors.textSecondary),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx, false),
        child: const Text('不备份'),
      ),
      FilledButton.icon(
        onPressed: () => Navigator.pop(ctx, true),
        icon: const Icon(Icons.backup, size: 16),
        label: const Text('创建备份并更新'),
        style: FilledButton.styleFrom(backgroundColor: CicadaColors.ok),
      ),
    ],
  );
}

/// Builds the update available banner widget.
Widget buildUpdateBanner({
  required UpdateInfo info,
  required bool downloadingUpdate,
  required double downloadProgress,
  required void Function(String url) onDownload,
}) {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CicadaColors.ok.withAlpha(20),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: CicadaColors.ok),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.new_releases_outlined,
              color: CicadaColors.ok,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '发现新版本 v${info.latestVersion}',
              style: const TextStyle(
                color: CicadaColors.ok,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (info.releaseNotes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            info.releaseNotes,
            style: const TextStyle(
              fontSize: 12,
              color: CicadaColors.textSecondary,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (downloadingUpdate) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: downloadProgress > 0 ? downloadProgress : null,
            backgroundColor: CicadaColors.border,
            valueColor: const AlwaysStoppedAnimation(CicadaColors.ok),
          ),
          const SizedBox(height: 4),
          Text(
            downloadProgress > 0
                ? '下载中... ${(downloadProgress * 100).toStringAsFixed(1)}%'
                : '正在准备备份和下载...',
            style: const TextStyle(
              fontSize: 12,
              color: CicadaColors.textSecondary,
            ),
          ),
        ] else ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (info.downloadUrl.isNotEmpty)
                FilledButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('更新（有风险）'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CicadaColors.ok,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => onDownload(info.downloadUrl),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('前往下载'),
                  onPressed: () {},
                ),
            ],
          ),
        ],
      ],
    ),
  );
}
