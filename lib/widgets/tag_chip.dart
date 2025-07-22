import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool showDelete;
  final Color? backgroundColor;
  final Color? selectedColor;

  const TagChip({
    super.key,
    required this.tag,
    this.isSelected = false,
    this.onTap,
    this.onDeleted,
    this.showDelete = false,
    this.backgroundColor,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Text(tag),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      deleteIcon: showDelete ? const Icon(Icons.close, size: 18) : null,
      onDeleted: showDelete ? onDeleted : null,
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest,
      selectedColor: selectedColor ?? colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
      side: isSelected 
        ? BorderSide(color: colorScheme.primary, width: 1)
        : BorderSide(color: colorScheme.outline.withOpacity(0.5)),
    );
  }
}

class TagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final String? hintText;

  const TagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.hintText,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !widget.tags.contains(trimmedTag)) {
      widget.onTagsChanged([...widget.tags, trimmedTag]);
      _controller.clear();
    }
  }

  void _removeTag(String tag) {
    final newTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.tags.map((tag) => TagChip(
              tag: tag,
              showDelete: true,
              onDeleted: () => _removeTag(tag),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Ajouter un tag...',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_controller.text),
            ),
          ),
          onSubmitted: _addTag,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
