import 'package:flutter/material.dart';

/// Reusable slide-in panel from the right side.
///
/// When [isOpen] is true the main [child] shrinks and the panel slides in
/// from the right. When closed, [child] expands back smoothly.
///
/// The panel does NOT overlay the content — it pushes the content to the
/// left so nothing is hidden.
class AdminSlidePanel extends StatelessWidget {
  const AdminSlidePanel({
    super.key,
    required this.isOpen,
    required this.child,
    this.panelWidth = 480,
    this.title = '',
    this.panelBody,
    this.panelFooter,
    this.onClose,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  });

  /// Whether the panel is currently visible.
  final bool isOpen;

  /// Fixed width of the slide panel (default 480).
  final double panelWidth;

  /// Title shown in the panel header.
  final String title;

  /// Scrollable body of the panel.
  final Widget? panelBody;

  /// Fixed footer (buttons) at the bottom of the panel.
  final Widget? panelFooter;

  /// Called when the user taps the close button or the scrim.
  final VoidCallback? onClose;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Main page content — will shrink when panel opens.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Clamp panel width so it never exceeds 85% of available width
        final effectivePanelWidth =
            panelWidth.clamp(320.0, constraints.maxWidth * 0.85);

        return Stack(
          children: [
            // ─── Main content ───
            AnimatedPositioned(
              duration: duration,
              curve: curve,
              top: 0,
              bottom: 0,
              left: 0,
              right: isOpen ? effectivePanelWidth : 0,
              child: child,
            ),

            // ─── Panel ───
            AnimatedPositioned(
              duration: duration,
              curve: curve,
              top: 0,
              bottom: 0,
              right: isOpen ? 0 : -effectivePanelWidth,
              width: effectivePanelWidth,
              child: _PanelContent(
                isDarkMode: isDarkMode,
                title: title,
                body: panelBody,
                footer: panelFooter,
                onClose: onClose,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Panel internal content
// ─────────────────────────────────────────────
class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.isDarkMode,
    required this.title,
    this.body,
    this.footer,
    this.onClose,
  });

  final bool isDarkMode;
  final String title;
  final Widget? body;
  final Widget? footer;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(left: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── Header ───
          _buildHeader(),

          // ─── Divider ───
          Divider(height: 1, color: borderColor),

          // ─── Body ───
          if (body != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: body!,
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),

          // ─── Footer ───
          if (footer != null) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(20),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _CloseButton(isDarkMode: isDarkMode, onTap: onClose),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated close button
// ─────────────────────────────────────────────
class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.isDarkMode, this.onTap});
  final bool isDarkMode;
  final VoidCallback? onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFF3F4F6))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.6)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
