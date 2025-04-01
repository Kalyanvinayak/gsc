import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryUpdatePage extends StatefulWidget {
  final String itemId; // Item's Firestore document ID
  final String initialName;
  final int initialQuantity;

  const InventoryUpdatePage({
    required this.itemId,
    required this.initialName,
    required this.initialQuantity,
    Key? key,
  }) : super(key: key);

  @override
  _InventoryUpdatePageState createState() => _InventoryUpdatePageState();
}

class _InventoryUpdatePageState extends State<InventoryUpdatePage> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  final CollectionReference inventoryCollection =
  FirebaseFirestore.instance.collection('inventory');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _quantityController = TextEditingController(text: widget.initialQuantity.toString());
  }

  Future<void> updateItem() async {
    String updatedName = _nameController.text;
    int updatedQuantity = int.tryParse(_quantityController.text) ?? widget.initialQuantity;
    DocumentReference itemRef = inventoryCollection.doc(widget.itemId);

    try {
      final docSnapshot = await itemRef.get();

      if (docSnapshot.exists) {
        // If the document exists, update it
        await itemRef.update({
          'name': updatedName,
          'quantity': updatedQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // If the document does not exist, create it
        await itemRef.set({
          'name': updatedName,
          'quantity': updatedQuantity,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Item updated successfully!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error updating item: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Inventory & View Stock")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Item Name"),
                ),
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: updateItem,
                  child: const Text("Update Item"),
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Current Inventory Stock",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: inventoryCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No inventory items available."));
                }

                var inventoryList = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: inventoryList.length,
                  itemBuilder: (context, index) {
                    var item = inventoryList[index];
                    return ListTile(
                      title: Text(item['name']),
                      subtitle: Text("Stock: ${item['quantity']}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
