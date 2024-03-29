import 'package:dbms_project/database_helpers/database_helper.dart';
import 'package:dbms_project/global/constants.dart';
import 'package:dbms_project/global/strings.dart';
import 'package:dbms_project/models/budget_item.dart';
import 'package:flutter/material.dart';

class BudgetHelper extends ChangeNotifier {
  BudgetHelper() {
    getBudgetItemsFromTable();
  }
  DatabaseHelper _databaseHelper = DatabaseHelper();
  List<BudgetItem> _budgetItems = [];
  double _totalAmount = 0;

  double get totalAmount => _totalAmount;
  List<BudgetItem> get budgetItems => _budgetItems;

  void insertBudgetItem(BudgetItem budgetItem) async {
    var db = await _databaseHelper.database;
    var result = await db.rawInsert(
      '''
      insert into $budgetTable 
      (
        $budgetEventNameColumn, 
        $budgetAmountColumn, 
        $budgetDateTimeColumn, 
        $budgetDescriptionColumn
      ) 
      values 
      (
        '${budgetItem.eventName}', 
        ${budgetItem.amount}, 
        '${budgetItem.dateTime.toIso8601String()}', 
        '${budgetItem.description}'
      )
      ''',
    );
    getBudgetItemsFromTable();
    print('Budget insertion result : $result');
  }

  void deleteBudgetItem(String eventName) async {
    var db = await _databaseHelper.database;
    var result = await db.rawDelete(
      '''
      delete from $budgetTable 
      where $budgetEventNameColumn = '$eventName'
      ''',
    );
    getBudgetItemsFromTable();
    print('Deletion result : $result');
  }

  void getBudgetItemsFromTable() async {
    _budgetItems = [];
    var db = await _databaseHelper.database;
    var result = await db
        .rawQuery('select * from $budgetTable order by $budgetDateTimeColumn');
    result.forEach(
      (element) => _budgetItems.add(
        BudgetItem.fromMap(element),
      ),
    );
    if (_budgetItems.length == 1)
      _budgetItems.add(
        BudgetItem(
          dateTime: DateTime.now(),
          amount: 0.0,
          eventName: 'Sample Event',
          description: 'Add more events!',
        ),
      );
    result = await db.rawQuery(
      '''
         select ifnull (
           (
             select sum($budgetAmountColumn) from $budgetTable
           ), 0
         ) as $budgetAmountColumn
      ''',
    );
    _totalAmount = convertToDouble(result[0][budgetAmountColumn]);

    notifyListeners();
  }
}
