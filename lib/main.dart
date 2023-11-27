import 'package:fl_chart/fl_chart.dart';
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

class DailyAmount {
  final int day;
  double amount;

  DailyAmount({required this.day, this.amount = 0.0});

  void addAmount(double value) {
    amount += value;
  }
}

class _SalarySplitHomePageState extends State<SalarySplitHomePage> {
  final GlobalKey<MyCustomFormState> _myCustomFormKeyIn =
      GlobalKey<MyCustomFormState>();
  final GlobalKey<MyCustomFormState> _myCustomFormKeyOut =
      GlobalKey<MyCustomFormState>();

  // Graph config
  List<Map<String, String>> getMoneyInData() {
    return _myCustomFormKeyIn.currentState?._submittedData
            .where((entry) => entry['type'] == 'in')
            .toList() ??
        []; // Provide an empty list as a fallback
  }

  List<Map<String, String>> getMoneyOutData() {
    return _myCustomFormKeyOut.currentState?._submittedData
            .where((entry) => entry['type'] == 'out')
            .toList() ??
        []; // Provide an empty list as a fallback
  }

  Map<int, DailyAmount> aggregateData(
      List<Map<String, String>> submittedData, bool isMoneyIn) {
    Map<int, DailyAmount> aggregatedData = {};

    for (var entry in submittedData) {
      int day = int.tryParse(entry['date'] ?? '0') ?? 0;
      double amount = double.tryParse(entry['amount'] ?? '0.0') ?? 0.0;

      if (day >= 1 && day <= 30) {
        aggregatedData.putIfAbsent(day, () => DailyAmount(day: day));
        if (isMoneyIn) {
          aggregatedData[day]!.addAmount(amount);
        } else {
          aggregatedData[day]!.addAmount(-amount);
        }
      }
    }

    return aggregatedData;
  }

  Map<int, double> calculateDailyNet(List<Map<String, String>> moneyInData,
      List<Map<String, String>> moneyOutData) {
    Map<int, double> dailyNet = {};

    // Aggregate Money In
    Map<int, DailyAmount> aggregatedMoneyIn = aggregateData(moneyInData, true);
    aggregatedMoneyIn.forEach((day, amount) {
      dailyNet[day] = (dailyNet[day] ?? 0) + amount.amount;
    });

    // Aggregate Money Out
    Map<int, DailyAmount> aggregatedMoneyOut =
        aggregateData(moneyOutData, false);
    aggregatedMoneyOut.forEach((day, amount) {
      dailyNet[day] = (dailyNet[day] ?? 0) - amount.amount;
    });

    return dailyNet;
  }

  List<FlSpot> calculateMonthlyBalance(
      Map<int, double> dailyNet, double initialBalance) {
    List<FlSpot> balanceData = [];
    double runningBalance = initialBalance;

    for (int day = 1; day <= 30; day++) {
      runningBalance += dailyNet[day] ?? 0;
      balanceData.add(FlSpot(day.toDouble(), runningBalance));
    }

    return balanceData;
  }

  Widget buildGraph() {
    // Get Money In and Money Out data (update these methods according to your data structure)
    List<Map<String, String>> moneyInData = getMoneyInData();
    List<Map<String, String>> moneyOutData =
        getMoneyOutData(); // Similar to getMoneyInData

    // Calculate daily net change
    Map<int, double> dailyNet = calculateDailyNet(moneyInData, moneyOutData);

    // Calculate monthly balance starting from the initial balance
    List<FlSpot> monthlyBalance = calculateMonthlyBalance(dailyNet, 1000);

    return LineChart(
      LineChartData(
        // ... configuration for the chart ...
        lineBarsData: [
          LineChartBarData(
            spots: monthlyBalance,
            // ... additional styling for the line chart ...
          ),
        ],
      ),
    );
  }

  double totalAmountIn = 0.0;
  double totalAmountOut = 0.0;
  double get _netTotal => totalAmountIn - totalAmountOut;

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
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            double width = MediaQuery.of(context).size.width;
            double cardWidth = width > 600 ? width * 0.6 : width * 0.9;
            cardWidth = cardWidth > 600 ? 600 : cardWidth;

            return Container(
              width: cardWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'November 2023',
                      style: TextStyle(
                        fontSize: 24.0, // Choose a size that fits your design
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: 200, // Set an appropriate height for the graph
                    child: buildGraph(),
                  ),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text('Money Net'),
                            subtitle: Text(
                              '${_netTotal > 0 ? '+' : ''}£${_netTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                color:
                                    _netTotal >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
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
                            title: Text('Money In'),
                            subtitle: Text(
                                'Total: \£${_myCustomFormKeyIn.currentState?.getTotalAmount().toStringAsFixed(2) ?? '0.00'}'),
                          ),
                          Divider(),
                          MyCustomForm(
                            key: _myCustomFormKeyIn,
                            onUpdate: _updateTotalAmountIn,
                            nameHintText: "Zoe",
                            amountHintText: "650",
                            dateHintText: "27",
                            transactionType: "in",
                          ),
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
                            onUpdate: _updateTotalAmountOut,
                            nameHintText: "Mortage",
                            amountHintText: "550",
                            dateHintText: "2",
                            transactionType: "out",
                          ),
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
  final String nameHintText;
  final String amountHintText;
  final String dateHintText;
  final String transactionType;

  const MyCustomForm({
    super.key,
    required this.onUpdate,
    required this.nameHintText,
    required this.amountHintText,
    required this.dateHintText,
    required this.transactionType,
  });

  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

class MyCustomFormState extends State<MyCustomForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

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
          'date': _dateController.text,
          'type': widget.transactionType,
        });
        _submittedData.sort((a, b) {
          int dateA = int.tryParse(a['date'] ?? '0') ?? 0;
          int dateB = int.tryParse(b['date'] ?? '0') ?? 0;
          return dateA.compareTo(dateB);
        });
      });

      widget.onUpdate();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data Submitted')),
      );

      // Clear the text fields after submission
      _nameController.clear();
      _amountController.clear();
      _dateController.clear();
    }
  }

  void _deleteData(int index) {
    setState(() {
      _submittedData.removeAt(index);
      _submittedData.sort((a, b) {
        int dateA = int.tryParse(a['date'] ?? '0') ?? 0;
        int dateB = int.tryParse(b['date'] ?? '0') ?? 0;
        return dateA.compareTo(dateB);
      });
    });
    widget.onUpdate();
  }

  String formatDateWithSuffix(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    int date = int.tryParse(dateString) ?? 0;
    if (date < 1 || date > 30) return dateString; // Safety check

    if (date >= 11 && date <= 13) {
      return '${date}th';
    }
    switch (date % 10) {
      case 1:
        return '${date}st';
      case 2:
        return '${date}nd';
      case 3:
        return '${date}rd';
      default:
        return '${date}th';
    }
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
                  Text(
                    '${data['name']}: £${data['amount']} on the ${formatDateWithSuffix(data['date'])}',
                  ),
                ],
              ),
            ),
          );
        }).toList(),

        if (_submittedData.isNotEmpty) Divider(),

        // Form fields
        Form(
          key: _formKey,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: widget.nameHintText,
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
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: widget.amountHintText,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Enter a valid number';
                    }
                    if (amount < 0) {
                      return 'Amount cannot be negative';
                    }
                    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(value)) {
                      return 'Up to two decimal places allowed';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: widget.dateHintText,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a date';
                    }
                    final date = int.tryParse(value);
                    if (date == null || date < 1 || date > 30) {
                      return 'Enter a valid date (1-30)';
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
