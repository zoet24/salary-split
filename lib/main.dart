import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const SalarySplitApp());
}

class SalarySplitApp extends StatelessWidget {
  const SalarySplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SalarySplitAppState(),
      child: MaterialApp(
        title: 'Salary Split App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const SalarySplitHomePage(),
      ),
    );
  }
}

class SalarySplitAppState extends ChangeNotifier {}

class SalarySplitHomePage extends StatefulWidget {
  const SalarySplitHomePage({super.key});

  @override
  _SalarySplitHomePageState createState() => _SalarySplitHomePageState();
}

class _SalarySplitHomePageState extends State<SalarySplitHomePage> {
  final GlobalKey<MyCustomFormState> _myCustomFormKeyIn =
      GlobalKey<MyCustomFormState>();
  final GlobalKey<MyCustomFormState> _myCustomFormKeyOut =
      GlobalKey<MyCustomFormState>();
  double totalAmountIn = 0.0;
  double totalAmountOut = 0.0;

  void _updateTotalAmountIn() {
    if (_myCustomFormKeyIn.currentState != null) {
      setState(() {
        totalAmountIn = _myCustomFormKeyIn.currentState!.getTotalAmount();
      });
    }
  }

  void _updateTotalAmountOut() {
    if (_myCustomFormKeyOut.currentState != null) {
      setState(() {
        totalAmountOut = _myCustomFormKeyOut.currentState!.getTotalAmount();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Split App'),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Calculate the width based on screen size
            double width = MediaQuery.of(context).size.width;
            double cardWidth = width > 600 ? width * 0.6 : width * 0.9;
            cardWidth = cardWidth > 800 ? 800 : cardWidth; // Max width 800px

            return Container(
              width: cardWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text('Money In'),
                            subtitle: Text(
                                'Total: \£${_myCustomFormKeyIn.currentState?.getTotalAmount().toStringAsFixed(2) ?? '0.00'}'),
                          ),
                          Divider(),
                          MyCustomForm(
                              key: _myCustomFormKeyIn,
                              onUpdate: _updateTotalAmountIn),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text('Money Out'),
                            subtitle: Text(
                                'Total: \£${_myCustomFormKeyOut.currentState?.getTotalAmount().toStringAsFixed(2) ?? '0.00'}'),
                          ),
                          Divider(),
                          MyCustomForm(
                              key: _myCustomFormKeyOut,
                              onUpdate: _updateTotalAmountOut),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MyCustomForm extends StatefulWidget {
  final Function onUpdate;
  const MyCustomForm({super.key, required this.onUpdate});

  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

class MyCustomFormState extends State<MyCustomForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  List<Map<String, String>> _submittedData = [];

  double getTotalAmount() {
    return _submittedData.fold(0.0, (sum, item) {
      return sum + double.tryParse(item['amount'] ?? '0.0')!;
    });
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _submittedData.add({
          'name': _nameController.text,
          'amount': _amountController.text,
        });
      });

      widget.onUpdate();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data Submitted')),
      );

      // Clear the text fields after submission
      _nameController.clear();
      _amountController.clear();
    }
  }

  void _deleteData(int index) {
    setState(() {
      _submittedData.removeAt(index);
    });
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display the submitted data
        ..._submittedData.asMap().entries.map((entry) {
          int idx = entry.key;
          Map<String, String> data = entry.value;

          return InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Entry'),
                content: const Text('Do you want to delete this entry?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Delete'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _deleteData(idx);
                    },
                  ),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Name: ${data['name']}, Amount: ${data['amount']}'),
                ],
              ),
            ),
          );
        }).toList(),

        // Form fields
        Form(
          key: _formKey,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a name';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an amount';
                    }
                    return null;
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _submitData,
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
