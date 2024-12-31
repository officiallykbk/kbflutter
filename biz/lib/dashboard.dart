import 'package:biz/addnew.dart';
import 'package:biz/providers/orders_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final OrdersModel = Provider.of<OrdersProviders>(context);
    return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverList(delegate: SliverChildListDelegate([Card()])),
            SliverList.builder(
                itemCount: OrdersModel.allOrders.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {},
                    title: Text(OrdersModel.allOrders[index]['clientName']),
                    subtitle: Text(OrdersModel.allOrders[index]['Date']),
                  );
                })
          ],
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => MyHomePage()));
            },
            child: const Icon(Icons.add)));
  }
}
