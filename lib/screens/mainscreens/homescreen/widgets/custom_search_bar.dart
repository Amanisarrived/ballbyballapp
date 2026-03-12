import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final bool readOnly;
  final String hintText;
  final bool showFilterIcon;

  const SearchBarWidget({
    super.key,
    this.onTap,
    this.onChanged,
    this.controller,
    this.readOnly = false,
    this.hintText = 'Search matches, teams, players...',
    this.showFilterIcon = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.readOnly ? widget.onTap : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isFocused
                ? const Color(0xFFFF6B6B).withOpacity(0.5)
                : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),


            Icon(
              Icons.search,
              color: _isFocused
                  ? const Color(0xFFFF6B6B)
                  : Colors.grey.shade600,
              size: 20,
            ),

            const SizedBox(width: 12),


            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  setState(() {
                    _isFocused = hasFocus;
                  });
                },
                child: TextField(
                  controller: widget.controller,
                  readOnly: widget.readOnly,
                  onChanged: widget.onChanged,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ),


            if ((widget.controller?.text.isNotEmpty ?? false) && !widget.readOnly)
              GestureDetector(
                onTap: () {
                  widget.controller?.clear();
                  if (widget.onChanged != null) widget.onChanged!('');
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ),
              ),


            if (widget.showFilterIcon)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Colors.white,
                  size: 16,
                ),
              ),

            if (!widget.showFilterIcon && widget.readOnly)
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}