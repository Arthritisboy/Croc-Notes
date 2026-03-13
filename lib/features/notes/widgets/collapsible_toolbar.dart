import 'package:flutter/material.dart';

class CollapsibleToolbar extends StatefulWidget {
  final Widget title;
  final Widget toolbar;
  final Color categoryColor;
  final bool initiallyExpanded;

  const CollapsibleToolbar({
    super.key,
    required this.title,
    required this.toolbar,
    required this.categoryColor,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleToolbar> createState() => _CollapsibleToolbarState();
}

class _CollapsibleToolbarState extends State<CollapsibleToolbar> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.categoryColor.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with hide/show toggle
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: widget.title),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Toolbar (collapsible)
          if (_isExpanded) widget.toolbar,
        ],
      ),
    );
  }
}
