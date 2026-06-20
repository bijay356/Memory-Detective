import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NodeStatus { locked, current, completed }

class MapNode extends StatefulWidget {
  final int level;
  final NodeStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;

  const MapNode({
    Key? key,
    required this.level,
    required this.status,
    this.onTap,
    this.onLockedTap,
  }) : super(key: key);

  @override
  State<MapNode> createState() => _MapNodeState();
}

class _MapNodeState extends State<MapNode> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status == NodeStatus.current) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MapNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == NodeStatus.current &&
        oldWidget.status != NodeStatus.current) {
      _pulseController.repeat(reverse: true);
    } else if (widget.status != NodeStatus.current &&
        oldWidget.status == NodeStatus.current) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color nodeColor;
    Color iconColor;
    IconData icon;

    switch (widget.status) {
      case NodeStatus.locked:
        nodeColor = AppTheme.surfaceLight;
        iconColor = Colors.white24;
        icon = Icons.lock;
        break;
      case NodeStatus.current:
        nodeColor = AppTheme.gold;
        iconColor = Colors.black;
        icon = Icons.play_arrow;
        break;
      case NodeStatus.completed:
        nodeColor = AppTheme.green;
        iconColor = Colors.white;
        icon = Icons.star;
        break;
    }

    Widget nodeWidget = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: nodeColor,
        boxShadow: widget.status == NodeStatus.current ||
                widget.status == NodeStatus.completed
            ? [
                BoxShadow(
                  color: nodeColor.withOpacity(0.6),
                  blurRadius: widget.status == NodeStatus.current ? 20 : 10,
                  spreadRadius: 2,
                )
              ]
            : [],
        border: Border.all(
          color: widget.status == NodeStatus.locked
              ? Colors.white10
              : Colors.white70,
          width: 2,
        ),
      ),
      child: Icon(icon, color: iconColor, size: 32),
    );

    if (widget.status == NodeStatus.current) {
      nodeWidget = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: nodeWidget,
      );
    }

    return GestureDetector(
      onTap: widget.status == NodeStatus.locked
          ? widget.onLockedTap
          : widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          nodeWidget,
          const SizedBox(height: 8),
          Text(
            '${widget.level}',
            style: TextStyle(
              color: widget.status == NodeStatus.locked
                  ? Colors.white30
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
