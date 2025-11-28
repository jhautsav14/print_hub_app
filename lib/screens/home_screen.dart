import 'package:flutter/material.dart';
import 'package:print_app/screens/orders_list_screen.dart';
import '../models/print_document.dart';
import '../services/pdf_service.dart';
import 'cart_summary_screen.dart';

class PrintHomeScreen extends StatefulWidget {
  const PrintHomeScreen({super.key});

  @override
  State<PrintHomeScreen> createState() => _PrintHomeScreenState();
}

class _PrintHomeScreenState extends State<PrintHomeScreen> {
  // Logic State
  List<PrintDocument> _documents = [];
  int _selectedIndex = 0; // Tracks which document is currently being edited
  bool _isUploading = false;

  // Pricing Constants
  final int _bwPrice = 3;
  final int _colorPrice = 10;

  // --- LOGIC ---

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);
    try {
      final doc = await PdfService.pickAndProcessDocument();
      if (doc != null) {
        setState(() {
          _documents.add(doc);
          _selectedIndex = _documents.length - 1; // Auto-select new doc
        });
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
      if (_selectedIndex >= _documents.length) {
        _selectedIndex = _documents.isNotEmpty ? _documents.length - 1 : 0;
      }
    });
  }

  int get _totalDocs => _documents.length;

  int get _totalPages =>
      _documents.fold(0, (sum, doc) => sum + (doc.pageCount * doc.copies));

  int get _totalPrice {
    if (_documents.isEmpty) return 0;
    int total = 0;
    for (var doc in _documents) {
      int pricePerPage = doc.colorType == 'Color' ? _colorPrice : _bwPrice;
      total += (pricePerPage * doc.pageCount * doc.copies);
    }
    return total;
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    // Current active document to display settings for
    final activeDoc = _documents.isNotEmpty ? _documents[_selectedIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          "Print Preview",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.black),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrdersListScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8), // Small padding for right alignment
        ],
      ),
      body: Column(
        children: [
          // --- TOP AREA: Document Preview List ---
          Expanded(
            flex: 5,
            child: _isUploading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                ? Center(child: _buildUploadPlaceholder())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _documents.length + 1, // +1 for Add Button
                    separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      if (index == _documents.length) {
                        return Center(child: _buildUploadPlaceholder());
                      }
                      return _buildDocumentPreview(
                        _documents[index],
                        index,
                        isActive: index == _selectedIndex,
                      );
                    },
                  ),
          ),

          // --- SETTINGS PANEL ---
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: Opacity(
                  opacity: activeDoc == null ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: activeDoc == null,
                    child: Column(
                      children: [
                        // Settings Header to indicate which doc is being edited
                        if (activeDoc != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            alignment: Alignment.center,
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Total Copies
                                _buildSectionHeader("Total Copies"),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Number of sets",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () {
                                              if (activeDoc!.copies > 1) {
                                                setState(
                                                  () => activeDoc.copies--,
                                                );
                                              }
                                            },
                                          ),
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              "${activeDoc?.copies ?? 1}",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              setState(
                                                () => activeDoc!.copies++,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 40),

                                // 2. Double Sided
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Print on both sides",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Switch(
                                      value: activeDoc?.isDoubleSided ?? false,
                                      activeColor: Colors.blue,
                                      onChanged: (val) {
                                        setState(
                                          () => activeDoc!.isDoubleSided = val,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const Divider(height: 40),

                                // 3. Orientation
                                _buildSectionHeader("Orientation"),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSelectableCard(
                                        title: "Portrait",
                                        icon: Icons.portrait,
                                        isSelected:
                                            activeDoc?.orientation ==
                                            'Portrait',
                                        onTap: () => setState(
                                          () => activeDoc!.orientation =
                                              'Portrait',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSelectableCard(
                                        title: "Landscape",
                                        icon: Icons.landscape,
                                        isSelected:
                                            activeDoc?.orientation ==
                                            'Landscape',
                                        onTap: () => setState(
                                          () => activeDoc!.orientation =
                                              'Landscape',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // 4. Color
                                _buildSectionHeader("Color"),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSelectableCard(
                                        title: "B&W",
                                        subtitle: "₹$_bwPrice/Page",
                                        icon: Icons.format_color_reset,
                                        isSelected:
                                            activeDoc?.colorType == 'B&W',
                                        onTap: () => setState(
                                          () => activeDoc!.colorType = 'B&W',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSelectableCard(
                                        title: "Color",
                                        subtitle: "₹$_colorPrice/Page",
                                        icon: Icons.color_lens,
                                        isSelected:
                                            activeDoc?.colorType == 'Color',
                                        onTap: () => setState(
                                          () => activeDoc!.colorType = 'Color',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // --- BOTTOM BAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$_totalDocs Docs | $_totalPages Pages",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Total: ₹$_totalPrice",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 50,
                width: 140,
                child: ElevatedButton(
                  onPressed: _documents.isEmpty
                      ? null
                      : () async {
                          // Navigate to Cart Summary
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartSummaryScreen(
                                documents: _documents,
                                bwPrice: _bwPrice,
                                colorPrice: _colorPrice,
                              ),
                            ),
                          );

                          // If order placed (result == true), clear cart
                          if (result == true) {
                            setState(() {
                              _documents.clear();
                              _selectedIndex = 0;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Order Uploaded Successfully!",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Add to Cart",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildUploadPlaceholder() {
    return GestureDetector(
      onTap: _handleUpload,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 32, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            const Text(
              "Add PDF",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(
    PrintDocument doc,
    int index, {
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(
          top: isActive ? 10 : 30,
          bottom: isActive ? 30 : 50,
        ),
        // The bottom margin ensures space for the badge so it doesn't get hidden
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Colors.blue, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isActive ? 0.2 : 0.1),
              blurRadius: isActive ? 20 : 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: doc.thumbnail != null
                  ? RawImage(
                      image: doc.thumbnail,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : const Center(
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
            ),

            // Delete Button (Top Right)
            if (isActive)
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  onTap: () => _removeDocument(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                ),
              ),

            // Badge (Bottom - moved up slightly to prevent clipping)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${doc.pageCount} Pages",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSelectableCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.8)
                      : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
