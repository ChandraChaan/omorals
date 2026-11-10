import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets.dart';

/// Kanban board with drag-and-drop between columns.
///
/// Uses [Draggable] on wide (mouse) layouts and [LongPressDraggable] on
/// narrow (touch) layouts so that scrolling still works on phones. While a
/// card is dragged near the left or right edge the board scrolls sideways.
class Board<K, T extends Object> extends StatefulWidget {
  const Board({
    super.key,
    required this.columns,
    required this.titleOf,
    required this.colorOf,
    required this.itemsOf,
    required this.cardBuilder,
    required this.onMove,
    this.canDrag,
    this.onAdd,
    this.minColumnWidth = 272,
  });

  final List<K> columns;
  final String Function(K column) titleOf;
  final Color Function(K column) colorOf;
  final List<T> Function(K column) itemsOf;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final void Function(T item, K to) onMove;
  final bool Function(T item)? canDrag;
  final void Function(K column)? onAdd;

  /// Columns stretch beyond this to use the available width when they fit.
  final double minColumnWidth;

  @override
  State<Board<K, T>> createState() => _BoardState<K, T>();
}

class _BoardState<K, T extends Object> extends State<Board<K, T>> {
  static const _gap = 12.0;
  final _scroll = ScrollController();
  Timer? _edgeTimer;
  double? _pointerX;

  @override
  void dispose() {
    _edgeTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _dragStarted() {
    _edgeTimer?.cancel();
    _edgeTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _edgeScroll());
  }

  void _dragEnded() {
    _edgeTimer?.cancel();
    _edgeTimer = null;
    _pointerX = null;
  }

  void _edgeScroll() {
    final x = _pointerX;
    final box = context.findRenderObject();
    if (x == null || box is! RenderBox || !_scroll.hasClients) return;
    final left = box.localToGlobal(Offset.zero).dx;
    final right = left + box.size.width;
    const zone = 72.0;
    var delta = 0.0;
    if (x < left + zone) {
      delta = -14;
    } else if (x > right - zone) {
      delta = 14;
    }
    if (delta == 0) return;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo((_scroll.offset + delta).clamp(0.0, max));
  }

  Widget _card(T item, double width) {
    final card = widget.cardBuilder(context, item);
    if (!(widget.canDrag?.call(item) ?? true)) return card;
    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: width,
        child: Transform.rotate(
          angle: 0.02,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusSm + 2),
              boxShadow: [
                BoxShadow(
                  color: C.ink.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: card,
          ),
        ),
      ),
    );
    final ghost = Opacity(opacity: 0.35, child: card);
    if (isWide(context)) {
      return Draggable<T>(
        data: item,
        feedback: feedback,
        childWhenDragging: ghost,
        onDragStarted: _dragStarted,
        onDragUpdate: (d) => _pointerX = d.globalPosition.dx,
        onDragEnd: (_) => _dragEnded(),
        child: card,
      );
    }
    return LongPressDraggable<T>(
      data: item,
      delay: const Duration(milliseconds: 280),
      feedback: feedback,
      childWhenDragging: ghost,
      onDragStarted: _dragStarted,
      onDragUpdate: (d) => _pointerX = d.globalPosition.dx,
      onDragEnd: (_) => _dragEnded(),
      child: card,
    );
  }

  Widget _column(K column, double width) {
    final color = widget.colorOf(column);
    final items = widget.itemsOf(column);
    return DragTarget<T>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => widget.onMove(d.data, column),
      builder: (context, candidates, _) {
        final hot = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: kMotion,
          width: width,
          decoration: BoxDecoration(
            color: hot ? tint(color, 0.1) : C.sunken,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(
              color: hot ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Dot(color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.titleOf(column),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tx(13.5, w: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${items.length}',
                                style: tx(13,
                                    w: FontWeight.w700, color: C.muted)),
                          ],
                        ),
                      ),
                      if (widget.onAdd != null)
                        IconButton(
                          tooltip: 'Add to ${widget.titleOf(column)}',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => widget.onAdd!(column),
                          icon: const Icon(Icons.add_rounded, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                          child: Text(
                            hot ? 'Drop here' : 'Nothing here',
                            style: tx(12.5, color: C.faint),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _card(items[i], width - 16),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = gutter(context);
    return LayoutBuilder(builder: (context, c) {
      final n = widget.columns.length;
      final fit = (c.maxWidth - g * 2 - _gap * (n - 1)) / n;
      final width = math.max(widget.minColumnWidth, fit);
      return Scrollbar(
        controller: _scroll,
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(g, 0, g, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                _column(widget.columns[i], width.floorToDouble()),
              ],
            ],
          ),
        ),
      );
    });
  }
}
