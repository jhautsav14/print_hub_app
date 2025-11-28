import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;

  // Lists to hold orders
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _printedOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = []; // New List

  @override
  void initState() {
    super.initState();
    // CHANGED: Length is now 3
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }

  // Fetch orders and their items
  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      // Fetch orders sorted by newest first for Delivered, oldest first for Pending
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> allOrders =
          List<Map<String, dynamic>>.from(response);

      setState(() {
        // 1. Pending (New Orders)
        _pendingOrders = allOrders
            .where((o) => o['status'] == 'pending')
            .toList();
        // Sort Pending: Oldest first (to print FIFO)
        _pendingOrders.sort(
          (a, b) => a['created_at'].compareTo(b['created_at']),
        );

        // 2. Printed (Ready for Pickup)
        _printedOrders = allOrders
            .where((o) => o['status'] == 'printed')
            .toList();

        // 3. Delivered (History)
        _deliveredOrders = allOrders
            .where((o) => o['status'] == 'delivered')
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching vendor data: $e");
      setState(() => _isLoading = false);
    }
  }

  // Update Status Logic
  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order marked as ${newStatus.toUpperCase()}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      _fetchOrders(); // Refresh lists
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Open PDF Logic (Public URL)
  Future<void> _downloadFile(String filePath) async {
    try {
      final url = _supabase.storage.from('print_files').getPublicUrl(filePath);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not open file: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Vendor Dashboard"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true, // Allows tabs to scroll if text is long
          tabs: [
            Tab(text: "New (${_pendingOrders.length})"),
            Tab(text: "Ready (${_printedOrders.length})"),
            Tab(text: "Delivered (${_deliveredOrders.length})"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Pending
                _buildOrderList(_pendingOrders, statusCategory: 'pending'),
                // TAB 2: Printed
                _buildOrderList(_printedOrders, statusCategory: 'printed'),
                // TAB 3: Delivered
                _buildOrderList(_deliveredOrders, statusCategory: 'delivered'),
              ],
            ),
    );
  }

  Widget _buildOrderList(
    List<Map<String, dynamic>> orders, {
    required String statusCategory,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No orders in '$statusCategory'",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final items = List<Map<String, dynamic>>.from(
          order['order_items'] ?? [],
        );
        final date = DateTime.parse(order['created_at']).toLocal();
        final formattedDate = DateFormat('d MMM • h:mm a').format(date);

        // Determine Button Config based on status
        String btnText = "";
        Color btnColor = Colors.grey;
        VoidCallback? btnAction;

        if (statusCategory == 'pending') {
          btnText = "MARK AS COMPLETED";
          btnColor = Colors.blue;
          btnAction = () => _updateStatus(order['id'], 'printed');
        } else if (statusCategory == 'printed') {
          btnText = "MARK AS DELIVERED";
          btnColor = Colors.green;
          btnAction = () => _updateStatus(order['id'], 'delivered');
        } else {
          // Delivered
          btnText = "DELIVERED";
          btnColor = Colors.grey;
          btnAction = null; // No action (Disabled button)
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order #${order['id'].toString().substring(0, 6)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(),

                // File List
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['file_name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "${item['page_count']}pgs • ${item['copies']}cp • ${item['color_type']} • ${item['orientation']}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.download_rounded,
                            color: Colors.blue,
                          ),
                          constraints:
                              const BoxConstraints(), // Removes default padding
                          padding: const EdgeInsets.all(8),
                          onPressed: () => _downloadFile(item['file_path']),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: btnAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      disabledBackgroundColor:
                          Colors.grey[300], // For Delivered tab
                      disabledForegroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      btnText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
