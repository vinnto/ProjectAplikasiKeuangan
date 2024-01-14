import 'package:flutter/material.dart';
import 'package:flutter_project/models/database.dart';
import 'package:flutter_project/models/transaction_with_category.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  final TransactionWithCategory? transactionWithCategory;
  const TransactionPage({Key? key, required this.transactionWithCategory})
      : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final AppDb database = AppDb();
  bool isExpense = true;
  late int type;
  List<String> list = [''];
  late String dropDownValue = list.first;
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  Category? selectedCategory;

  Future insert(
      int amount, DateTime date, String nameDetail, int categoryId) async {
    DateTime now = DateTime.now();
    final row = await database.into(database.transactions).insertReturning(
        TransactionsCompanion.insert(
            name: nameDetail,
            category_id: categoryId,
            transaction_date: date,
            amount: amount,
            createdAt: now,
            updatedAt: now));
    print('Apa ini' + row.toString());
    // ada insert ke database
  }

  Future<List<Category>> getAllCategory(int type) async {
    return await database.getAllCategoryRepo(type);
  }

  Future update(int transactionId, int amount, int categoryId,
      DateTime transactionDate, String nameDetail) async {
    return await database.updateTransactionRepo(
        transactionId, amount, categoryId, transactionDate, nameDetail);
  }

  @override
  void initState() {
    // TODO: implement initState
    if (widget.transactionWithCategory != null) {
      updateTransactionView(widget.transactionWithCategory!);
    } else {
      type = 2;
    }
    super.initState();
  }

  void updateTransactionView(TransactionWithCategory transactionWithCategory) {
    amountController.text =
        transactionWithCategory.transaction.amount.toString();
    detailController.text = transactionWithCategory.transaction.name;
    dateController.text = DateFormat("yyyy-MM-dd")
        .format(transactionWithCategory.transaction.transaction_date);
    type = transactionWithCategory.category.type;
    (type == 2) ? isExpense = true : isExpense = false;
    selectedCategory = transactionWithCategory.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Transaction"),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: isExpense,
                  onChanged: (bool value) {
                    setState(() {
                      isExpense = value;
                      type = (isExpense) ? 2 : 1;
                      selectedCategory = null;
                    });
                  },
                  inactiveTrackColor: Colors.green[200],
                  inactiveThumbColor: Colors.green,
                  activeColor: Colors.red,
                ),
                Text(
                  isExpense ? 'Expense' : 'Income',
                  style: GoogleFonts.montserrat(fontSize: 14),
                )
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    border: UnderlineInputBorder(), labelText: "Amount"),
              ),
            ),
            SizedBox(
              height: 25,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Category',
                style: GoogleFonts.montserrat(fontSize: 16),
              ),
            ),
            FutureBuilder<List<Category>>(
                future: getAllCategory(type),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    if (snapshot.hasData) {
                      if (snapshot.data!.length > 0) {
                        selectedCategory = (selectedCategory == null)
                            ? snapshot.data!.first
                            : selectedCategory;
                        print('Masuk' + snapshot.toString());
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButton<Category>(
                              value: (selectedCategory == null)
                                  ? snapshot.data!.first
                                  : selectedCategory,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_downward),
                              items: snapshot.data!.map((Category item) {
                                return DropdownMenuItem<Category>(
                                  value: item,
                                  child: Text(item.name),
                                );
                              }).toList(),
                              onChanged: (Category? value) {
                                setState(() {
                                  print('SELECTED CATEGORY' + value!.name);
                                  selectedCategory = value;
                                });
                              }),
                        );
                      } else {
                        return Center(
                          child: Text("Data kosong"),
                        );
                      }
                    } else {
                      return Center(
                        child: Text("Tidak ada data"),
                      );
                    }
                  }
                }),
            SizedBox(
              height: 25,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                readOnly: true,
                controller: dateController,
                decoration: InputDecoration(labelText: "Enter Date"),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2099));

                  if (pickedDate != null) {
                    String formattedDate =
                        DateFormat('yyyy-MM-dd').format(pickedDate);

                    dateController.text = formattedDate;
                  }
                },
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: detailController,
                decoration: InputDecoration(
                    border: UnderlineInputBorder(), labelText: "Detail"),
              ),
            ),
            SizedBox(
              height: 25,
            ),
            Center(
                child: ElevatedButton(
                    onPressed: () async {
                      (widget.transactionWithCategory == null)
                          ? insert(
                              int.parse(amountController.text),
                              DateTime.parse(dateController.text),
                              detailController.text,
                              selectedCategory!.id)
                          : await update(
                              widget.transactionWithCategory!.transaction.id,
                              int.parse(amountController.text),
                              selectedCategory!.id,
                              DateTime.parse(dateController.text),
                              detailController.text);
                              setState(() {
                                
                              });
                      Navigator.pop(context, true);
                    },
                    child: Text("Save")))
          ],
        )),
      ),
    );
  }
}
