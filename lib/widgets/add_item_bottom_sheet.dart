import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Add Item to Order Bottom Sheet
/// Shows when user wants to add an item with customization
class AddItemBottomSheet extends StatefulWidget {
  final MenuItem item;
  final int currentQuantity;
  final Function(int quantity, String? notes) onAdd;

  const AddItemBottomSheet({
    Key? key,
    required this.item,
    required this.currentQuantity,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  late int _quantity;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity = widget.currentQuantity > 0 ? widget.currentQuantity : 1;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalPrice => widget.item.price * _quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppConstants.paddingLarge,
            right: AppConstants.paddingLarge,
            top: AppConstants.paddingLarge,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.paddingLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: AppConstants.headingMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),

              // Description
              Text(
                widget.item.description,
                style: AppConstants.bodyMedium.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              // Price
              Text(
                Formatters.formatCurrency(widget.item.price),
                style: AppConstants.headingSmall.copyWith(
                  color: AppConstants.primaryOrange,
                ),
              ),
              const Divider(height: AppConstants.paddingLarge),

              // Quantity selector
              const Text('Quantity', style: AppConstants.headingSmall),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildQuantitySelector(),
              const SizedBox(height: AppConstants.paddingMedium),

              // Notes
              const Text('Special Instructions', style: AppConstants.headingSmall),
              const SizedBox(height: AppConstants.paddingSmall),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: AppConstants.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'E.g., No onions, extra sauce...',
                  hintStyle: AppConstants.bodyMedium.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppConstants.darkSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLarge),

              // Add button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onAdd(_quantity, _notesController.text.isNotEmpty ? _notesController.text : null);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_shopping_cart),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        'Add ${_quantity > 1 ? '$_quantity items' : 'item'} - ${Formatters.formatCurrency(_totalPrice)}',
                        style: AppConstants.headingSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.darkSecondary,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _quantity > 1
                ? () {
                    setState(() {
                      _quantity--;
                    });
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: _quantity > 1 ? AppConstants.primaryOrange : AppConstants.textSecondary,
            iconSize: 32,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.paddingSmall,
            ),
            child: Text(
              _quantity.toString(),
              style: AppConstants.headingLarge.copyWith(
                color: AppConstants.primaryOrange,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _quantity++;
              });
            },
            icon: const Icon(Icons.add_circle_outline),
            color: AppConstants.primaryOrange,
            iconSize: 32,
          ),
        ],
      ),
    );
  }
}
