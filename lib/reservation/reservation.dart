import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationIndex extends StatefulWidget {
  const ReservationIndex({super.key});

  @override
  State<ReservationIndex> createState() => _reservation_calendarState();
}

class _reservation_calendarState extends State<ReservationIndex> {

  CollectionReference product = FirebaseFirestore.instance.collection('items');

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  Future<void> _update(DocumentSnapshot documentSnapshot)async{
  nameController.text = documentSnapshot['name'];
  priceController.text = documentSnapshot['price'];

  await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context){
        return SizedBox(
          child: Padding(
            padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom+20
          ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price',
                  ),
                  ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: ()async{
                      final String name = nameController.text;
                      final String price = priceController.text;
                      product
                          .doc(documentSnapshot.id)
                          .update({'name':name, 'price':price});
                      nameController.text = '';
                      priceController.text = '';
                      Navigator.of(context).pop();
                    },
                    child: Text("Update"))
              ],
            ),
        ),
        );
      }
      );
}

  Future<void> _create()async{

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context){
          return SizedBox(
            child: Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom+20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price',
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      onPressed: ()async{
                        final String name = nameController.text;
                        final String price = priceController.text;
                        await product.add({'name':name, 'price':price});
                        nameController.text = '';
                        priceController.text = '';
                        Navigator.of(context).pop();
                      },
                      child: Text("Update"))
                ],
              ),
            ),
          );
        }
    );
  }

  Future<void> _delete(String productId)async{
  await product.doc(productId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('청소일정목록'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body:
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: StreamBuilder(
            stream: product.snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot>streamSnapshot){
              if(streamSnapshot.hasData){
                return ListView.builder(
                  itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index){
                    final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
                    return Card(
                      margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                      child: ListTile(
                        title: Text(documentSnapshot['name']),
                        subtitle: Text(documentSnapshot['price']),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                  onPressed: (){
                                    _update(documentSnapshot);
                                  },
                                  icon: Icon(Icons.edit)
                              ),
                              IconButton(
                                  onPressed: (){
                                    _delete(documentSnapshot.id);
                                  },
                                  icon: Icon(Icons.delete)
                              )
                            ]
                          ),
                        ),
                      ),

                    );
                    },
                );
              }
              return CircularProgressIndicator();
            } ,
            ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){
        _create();
      },
      child: Icon(Icons.add),
      ),
    );
  }
}
