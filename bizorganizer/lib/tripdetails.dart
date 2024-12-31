import 'package:bizorganizer/models/imageCaching.dart';
import 'package:bizorganizer/providers/orders_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class TripDetails extends StatefulWidget {
  final Map<String, dynamic> trip;

  const TripDetails({super.key, required this.trip});

  @override
  State<TripDetails> createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails> {
  @override
  Widget build(BuildContext context) {
    final tripsModel = Provider.of<TripsProvider>(context);

    // Ensure 'orderStatus' and 'paymentStatus' are valid strings
    String orderStatus = widget.trip['orderStatus'];
    String paymentStatus = widget.trip['paymentStatus'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Details', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Sliver for Displaying Receipt Image if exists
            if (widget.trip['receipt'] != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Receipt:'),
                      SizedBox(height: 10),
                      InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => fullScreenImage(
                                      img: widget.trip['receipt']))),
                          child: Hero(
                              tag: widget.trip['receipt'],
                              child:
                                  CacheImage(imageUrl: widget.trip['receipt'])))
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Table(
                  border: TableBorder.all(
                      color: Colors.grey), // Adds borders to the table
                  columnWidths: const {
                    0: FixedColumnWidth(120), // Fixed width for the left column
                    1: FlexColumnWidth(), // The right column takes up the remaining space
                  },
                  children: [
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Client:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(widget.trip['clientName']),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Contact:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child:
                                Text(widget.trip['contactNumber'].toString()),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Date:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(widget.trip['date']),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Origin:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(widget.trip['origin']),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Destination:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(widget.trip['destination']),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Amount:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child:
                                Text('\$${widget.trip['amount'].toString()}'),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Description:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(widget.trip['description'] ?? 'N/A'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sliver for Order Status Choice Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Change Order Status:'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 10.0,
                  children: [
                    'pending',
                    'completed',
                    'cancelled',
                    'onhold',
                    'rejected'
                  ].map((status) {
                    return ChoiceChip(
                      label: Text(status.toUpperCase()),
                      selected: orderStatus == status,
                      onSelected: (selected) {
                        if (selected) {
                          tripsModel.updateOrderStatus(
                              widget.trip['id'], status);
                        }
                        setState(() {
                          if (selected) orderStatus = status;
                        });
                      },
                      selectedColor: Colors.black,
                    );
                  }).toList(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),

            // Sliver for Payment Status Choice Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Change Payment Status:'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    title: const Text("Change Payment Status",
                        style: TextStyle(fontSize: 16, color: Colors.black)),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['Paid', 'Pending', 'Overdue'].map((status) {
                        return ChoiceChip(
                          label: Text(status.toUpperCase()),
                          selected: paymentStatus == status.toLowerCase(),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) paymentStatus = status;
                            });
                            if (selected) {
                              tripsModel.updatePaymentStatus(
                                  widget.trip['id'], status);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    tileColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  )),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class fullScreenImage extends StatelessWidget {
  const fullScreenImage({super.key, required this.img});
  final img;
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: img,
      child: Stack(children: [
        GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 0) {
              // Swipe down detected
              Navigator.pop(context);
            } else if (details.primaryVelocity != null &&
                details.primaryVelocity! < 0) {
              // Swipe up detected
              Navigator.pop(context);
            }
          },
          child: PhotoView(
            backgroundDecoration: BoxDecoration(color: Colors.transparent),
            imageProvider: CachedNetworkImageProvider(img),
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? null
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 10,
          child: IconButton(
              iconSize: 50,
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close)),
        )
      ]),
    );
  }
}


//  Wrap(
//                   spacing: 10.0,
//                   children: ['pending', 'paid', 'overdue'].map((status) {
//                     return ChoiceChip(
//                       label: Text(status.toUpperCase()),
//                       selected: paymentStatus == status,
//                       onSelected: (selected) {
//                         setState(() {
//                           if (selected) paymentStatus = status;
//                         });

//                         if (selected) {
//                           tripsModel.updatePaymentStatus(
//                               widget.trip['id'], status);
//                         }
//                       },
//                       selectedColor: Colors.black,
//                     );
//                   }).toList(),
//                 ),