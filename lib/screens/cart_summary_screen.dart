import 'package:flutter/material.dart';
import 'package:print_app/screens/orders_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../models/print_document.dart';

class CartSummaryScreen extends StatefulWidget {
  final List<PrintDocument> documents;
  final int bwPrice;
  final int colorPrice;

  const CartSummaryScreen({
    super.key,
    required this.documents,
    required this.bwPrice,
    required this.colorPrice,
  });

  @override
  State<CartSummaryScreen> createState() => _CartSummaryScreenState();
}

class _CartSummaryScreenState extends State<CartSummaryScreen> {
  bool _isProcessing = false;

  int _calculateItemCost(PrintDocument doc) {
    int pricePerPage = doc.colorType == 'Color'
        ? widget.colorPrice
        : widget.bwPrice;
    return pricePerPage * doc.pageCount * doc.copies;
  }

  int get _totalCartPrice {
    int total = 0;
    for (var doc in widget.documents) {
      total += _calculateItemCost(doc);
    }
    return total;
  }

  Future<void> _handlePlaceOrder() async {
    setState(() => _isProcessing = true);
    final supabase = Supabase.instance.client;

    try {
      // 1. Create the Main Order Entry
      final orderResponse = await supabase
          .from('orders')
          .insert({'total_price': _totalCartPrice, 'status': 'pending'})
          .select()
          .single();

      final String orderId = orderResponse['id'];

      // 2. Loop through documents to Upload & Save Metadata
      for (var doc in widget.documents) {
        if (doc.fileBytes == null) continue;

        // A. Upload File to Supabase Storage
        // Create a unique file path: order_id/timestamp_filename.pdf
        final String filePath =
            '$orderId/${DateTime.now().millisecondsSinceEpoch}_${doc.name}';

        await supabase.storage
            .from('print_files')
            .uploadBinary(
              filePath,
              doc.fileBytes!,
              fileOptions: const FileOptions(contentType: 'application/pdf'),
            );

        // B. Insert Item Record into Database
        await supabase.from('order_items').insert({
          'order_id': orderId,
          'file_name': doc.name,
          'file_path': filePath,
          'page_count': doc.pageCount,
          'copies': doc.copies,
          'color_type': doc.colorType,
          'orientation': doc.orientation,
          'is_double_sided': doc.isDoubleSided,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order uploaded successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);

        // Push the Orders List Screen so the user sees their new order
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrdersListScreen()),
        );
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error uploading order: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Keep your existing UI code exactly as it was)
    // Just ensure the ElevatedButton calls the updated _handlePlaceOrder
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Order Summary"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.documents.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final doc = widget.documents[i];
                final cost = _calculateItemCost(doc);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Mini Thumbnail
                      Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: doc.thumbnail != null
                            ? RawImage(image: doc.thumbnail, fit: BoxFit.cover)
                            : const Icon(
                                Icons.picture_as_pdf,
                                size: 30,
                                color: Colors.grey,
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${doc.pageCount} pages • ${doc.copies} cop${doc.copies > 1 ? 'ies' : 'y'}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildTag(
                                  doc.colorType,
                                  doc.colorType == 'Color'
                                      ? Colors.purple
                                      : Colors.grey,
                                ),
                                _buildTag(doc.orientation, Colors.blue),
                                if (doc.isDoubleSided)
                                  _buildTag("2-Sided", Colors.orange),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹$cost",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Total & Done Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Payable",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "₹$_totalCartPrice",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handlePlaceOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Done & Upload",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
