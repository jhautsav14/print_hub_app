// import 'package:flutter/material.dart';
// import 'package:printing/printing.dart'; // For PdfPreview
// import '../models/print_document.dart';

// class DocumentCard extends StatefulWidget {
//   final PrintDocument doc;
//   final VoidCallback onRemove;
//   final VoidCallback onUpdate; // Triggers parent rebuild to update totals

//   const DocumentCard({
//     super.key,
//     required this.doc,
//     required this.onRemove,
//     required this.onUpdate,
//   });

//   @override
//   State<DocumentCard> createState() => _DocumentCardState();
// }

// class _DocumentCardState extends State<DocumentCard> {
//   void _openFullPreview(BuildContext context) {
//     if (widget.doc.fileBytes == null) return;

//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => Scaffold(
//           appBar: AppBar(title: Text(widget.doc.name)),
//           body: PdfPreview(
//             build: (format) => Future.value(widget.doc.fileBytes!),
//             allowSharing: true,
//             allowPrinting: true,
//             canChangeOrientation: false,
//             canChangePageFormat: false,
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // --- Header: Thumbnail & Info ---
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Thumbnail
//                 GestureDetector(
//                   onTap: () => _openFullPreview(context),
//                   child: Container(
//                     width: 60,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       border: Border.all(color: Colors.grey[300]!),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     clipBehavior: Clip.antiAlias,
//                     child: widget.doc.thumbnail != null
//                         ? RawImage(
//                             image: widget.doc.thumbnail,
//                             fit: BoxFit.cover,
//                           )
//                         : const Icon(Icons.picture_as_pdf, color: Colors.red),
//                   ),
//                 ),
//                 const SizedBox(width: 16),

//                 // Details
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         widget.doc.name,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         "${widget.doc.pageCount} Pages",
//                         style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         "Rs ${widget.doc.totalCost.toStringAsFixed(0)}",
//                         style: const TextStyle(
//                           color: Colors.blue,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Actions
//                 Column(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Colors.grey),
//                       onPressed: widget.onRemove,
//                     ),
//                   ],
//                 ),
//               ],
//             ),

//             const Divider(height: 24),

//             // --- Copies ---
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   "Total Copies",
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//                 Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey[300]!),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.remove, size: 18),
//                         onPressed: () {
//                           if (widget.doc.copies > 1) {
//                             setState(() => widget.doc.copies--);
//                             widget.onUpdate();
//                           }
//                         },
//                       ),
//                       Text(
//                         "${widget.doc.copies}",
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.add, size: 18),
//                         onPressed: () {
//                           setState(() => widget.doc.copies++);
//                           widget.onUpdate();
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 12),

//             // --- Double Sided ---
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   "Print on both sides",
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//                 Switch(
//                   value: widget.doc.isDoubleSided,
//                   activeColor: Colors.blue,
//                   onChanged: (val) {
//                     setState(() => widget.doc.isDoubleSided = val);
//                     widget.onUpdate();
//                   },
//                 ),
//               ],
//             ),

//             const SizedBox(height: 12),

//             // --- Orientation ---
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   "Orientation",
//                   style: TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildOptionChip(
//                       label: "Portrait",
//                       icon: Icons.portrait,
//                       isSelected: widget.doc.orientation == 'Portrait',
//                       onTap: () {
//                         setState(() => widget.doc.orientation = 'Portrait');
//                         widget.onUpdate();
//                       },
//                     ),
//                     const SizedBox(width: 12),
//                     _buildOptionChip(
//                       label: "Landscape",
//                       icon: Icons.landscape,
//                       isSelected: widget.doc.orientation == 'Landscape',
//                       onTap: () {
//                         setState(() => widget.doc.orientation = 'Landscape');
//                         widget.onUpdate();
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),

//             const SizedBox(height: 16),

//             // --- Color Type ---
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   "Color Type",
//                   style: TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildOptionChip(
//                       label: "B&W",
//                       icon: Icons.format_color_reset,
//                       isSelected: widget.doc.colorType == 'B&W',
//                       onTap: () {
//                         setState(() => widget.doc.colorType = 'B&W');
//                         widget.onUpdate();
//                       },
//                     ),
//                     const SizedBox(width: 12),
//                     _buildOptionChip(
//                       label: "Color",
//                       icon: Icons.color_lens,
//                       isSelected: widget.doc.colorType == 'Color',
//                       onTap: () {
//                         setState(() => widget.doc.colorType = 'Color');
//                         widget.onUpdate();
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOptionChip({
//     required String label,
//     required IconData icon,
//     required bool isSelected,
//     required VoidCallback onTap,
//   }) {
//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 10),
//           decoration: BoxDecoration(
//             color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
//             border: Border.all(
//               color: isSelected ? Colors.blue : Colors.grey[300]!,
//               width: isSelected ? 2 : 1,
//             ),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 18,
//                 color: isSelected ? Colors.blue : Colors.grey[600],
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: isSelected ? Colors.blue : Colors.grey[600],
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
