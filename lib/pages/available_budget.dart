import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AvailableBudget extends StatefulWidget {
  AvailableBudget({Key key}) : super(key: key);

  @override
  _AvailableBudgetState createState() => _AvailableBudgetState();
}

class _AvailableBudgetState extends State<AvailableBudget> {
  Database database;
  String activeSign = '+';
  List<Map<String, dynamic>> income = [];
  List<Map<String, dynamic>> expence = [];
  static double incomeTotal = 0;
  static double expenceTotal = 0;
  static double available = 0;
  String year = getYear();
  TextEditingController valueControler = new TextEditingController();
  TextEditingController descriptionControler = new TextEditingController();
  static getYear() {
    switch (new DateTime.now().month) {
      case 1:
        return 'Jan ${new DateTime.now().year}';
      case 2:
        return 'Fen ${new DateTime.now().year}';
      case 3:
        return 'MAr ${new DateTime.now().year}';
      case 4:
        return 'Apr ${new DateTime.now().year}';
      case 5:
        return 'May ${new DateTime.now().year}';
      case 6:
        return 'Jun ${new DateTime.now().year}';
      case 7:
        return 'Jul ${new DateTime.now().year}';
      case 8:
        return 'Aug ${new DateTime.now().year}';
      case 9:
        return 'Sep ${new DateTime.now().year}';
      case 10:
        return 'Oct ${new DateTime.now().year}';
      case 11:
        return 'Nov ${new DateTime.now().year}';
      case 12:
        return 'Dec ${new DateTime.now().year}';
    }
  }

  Future<void> _initDb() async {
    final dbFolder = await getDatabasesPath();
    if (!await Directory(dbFolder).exists()) {
      await Directory(dbFolder).create(recursive: true);
    }
    final dbPath = join(dbFolder, 'budget.db');
    this.database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE income(
          id INTEGER PRIMARY KEY, 
          value REAL NOT NULL,
          description TEXT NOT NULL,
          month TEXT NOT NULL)
        ''');
        await db.execute('''
        CREATE TABLE expence(
          id INTEGER PRIMARY KEY, 
          value REAL NOT NULL,
          description TEXT NOT NULL,
          month TEXT NOT NULL)
        ''');
        await db.execute('''
        CREATE TABLE budjet_total(
          id INTEGER PRIMARY KEY, 
          income REAL NOT NULL,
          expence REAL NOT NULL,
          month TEXT NOT NULL ,
          UNIQUE(month))
        ''');
        await db.rawInsert(
            'INSERT INTO budjet_total(income, expence, month) VALUES(?, ?, ?)',
            [0, 0, year]);
      },
    );
  }

  Future<void> _getBudget() async {
    await _initDb();
    List<Map<String, dynamic>> _income = await this
        .database
        .rawQuery('SELECT * FROM income WHERE month=\'$year\'');
    setState(() {
      income = _income != null ? _income : [];
    });
    List<Map<String, dynamic>> _expence = await this
        .database
        .rawQuery('SELECT * FROM expence WHERE month=\'$year\'');
    setState(() {
      expence = _expence != null ? _expence : [];
    });
    List<Map<String, dynamic>> jsons = await this
        .database
        .rawQuery('SELECT * FROM budjet_total WHERE month=\'$year\'');
    setState(() {
      incomeTotal = jsons[0]['income'];
      expenceTotal = jsons[0]['expence'];
      available = incomeTotal - expenceTotal;
    });
    print('${jsons.length} rows retrieved from db!');
    print(jsons);
  }

  Future<void> _insertBudget(value, description) async {
    activeSign == '+'
        ? await database.transaction((txn) async {
            int id2 = await txn.rawInsert(
                'INSERT INTO income(value, description,month) VALUES(?, ?, ?)',
                [value, description, year]);
            print('inserted2: $id2');
            int count = await txn.rawUpdate(
                'UPDATE budjet_total SET income = ?  WHERE month=\'$year\'',
                [incomeTotal + value]);
            print('updated: $count');
          })
        : await database.transaction((txn) async {
            int id2 = await txn.rawInsert(
                'INSERT INTO expence(value, description,month) VALUES(?, ?, ?)',
                [value, description, year]);
            print('inserted2: $id2');
            int count = await txn.rawUpdate(
                'UPDATE budjet_total SET expence = ?  WHERE month=\'$year\'',
                [expenceTotal + value]);
            print('updated: $count');
          });
  }

  @override
  void initState() {
    _getBudget();
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  String validate(String value) {
    if (value.isEmpty) {
      return 'can\'t be empty';
    }
    return null;
  }

  String validateValue(String value) {
    String message = validate(value);
    if (message == null) {
      RegExp re = new RegExp(r'^[+-]?([0-9]+([.][0-9]*)?|[.][0-9])$');
      if (re.hasMatch(value)) {
        return null;
      }
      return 'This is an invalid format';
    }
    return message;
  }

  static calulatePersentage(double value) {
    var x = (((value / incomeTotal) * 100).toStringAsFixed(1));
    return x == 'NaN' ? '0' : x;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  image: DecorationImage(
                image: AssetImage('asset/31.jpg'),
                fit: BoxFit.cover,
              )),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Available Budget in $year:',
                      style: TextStyle(fontSize: 25, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      ' ${available > 0 ? '+' : ''}$available',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w300,
                          color: Colors.white),
                    ),
                  ),
                  buildLable(true, '$incomeTotal', '', Colors.green[400]),
                  buildLable(false, '$expenceTotal',
                      '${calulatePersentage(expenceTotal)}', Colors.red[500]),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Container(
                      color: Colors.grey[200],
                      padding: EdgeInsets.only(top: 10),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(left: 10),
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey)),
                                    width: 50,
                                    height: 50,
                                    child: DropdownButton(
                                        underline: SizedBox(),
                                        value: activeSign,
                                        items: [
                                          DropdownMenuItem<String>(
                                            child: Text('+'),
                                            value: '+',
                                          ),
                                          DropdownMenuItem<String>(
                                            child: Text('-'),
                                            value: '-',
                                          )
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            activeSign = value;
                                          });
                                        }),
                                  ),
                                  Expanded(
                                    child: Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: TextFormField(
                                          validator: validate,
                                          controller: descriptionControler,
                                          decoration: InputDecoration(
                                            labelText: 'Add description',
                                            border: OutlineInputBorder(),
                                          ),
                                        )),
                                  ),
                                ]),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 130,
                                  margin: EdgeInsets.all(10),
                                  child: TextFormField(
                                    validator: validateValue,
                                    controller: valueControler,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        labelText: 'Value',
                                        border: OutlineInputBorder()),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.check_circle_outline,
                                      size: 50,
                                      color: Colors.red[300],
                                    ),
                                    onPressed: () async {
                                      if (_formKey.currentState.validate()) {
                                        await _insertBudget(
                                            double.parse(valueControler.text),
                                            descriptionControler.text);
                                        descriptionControler.clear();
                                        valueControler.clear();
                                        _getBudget();
                                      }
                                    },
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Stack(
                      children: <Widget>[
                        Container(
                          color: Colors.white,
                          child: Column(
                            children: <Widget>[
                              buildTable(true),
                              buildTable(false)
                            ],
                          ),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height,
                          color: Colors.transparent,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildLable(income, value, persent, color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: EdgeInsets.all(5),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            income ? 'INCOME' : 'EXPENSES',
            style: TextStyle(fontSize: 16),
          ),
          Row(
            children: <Widget>[
              Text(
                '${income ? '+' : '-'} $value',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              income
                  ? Container(
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.all(5),
                      width: 30,
                      height: 25,
                    )
                  : Container(
                      margin: EdgeInsets.all(5),
                      color: Colors.red[200],
                      height: 25,
                      padding: EdgeInsets.all(5),
                      child: Text(
                        '$persent%',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  buildTable(_income) {
    var cal = _income ? income : expence;
    return Container(
        child: Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          padding: EdgeInsets.all(5),
          width: double.infinity,
          child: Text(
            _income ? 'INCOME' : 'Expence',
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 23,
                color: _income ? Colors.green[400] : Colors.red[500]),
          ),
        ),
        cal.length == 0
            ? SizedBox(
                child: Text('No Data yet'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: cal.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: index % 2 != 0 ? Colors.grey[200] : null,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]),
                        top: BorderSide(color: Colors.grey[200]),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          cal[index]['description'],
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w300),
                        ),
                        Row(
                          children: <Widget>[
                            Text(
                              '${_income ? '+' : '-'} ${cal[index]['value']}',
                              style: TextStyle(
                                  color: _income
                                      ? Colors.green[400]
                                      : Colors.red[500]),
                            ),
                            _income
                                ? SizedBox()
                                : Container(
                                    margin: EdgeInsets.all(5),
                                    color: Colors.red[100],
                                    height: 25,
                                    padding: EdgeInsets.all(5),
                                    child: Text(
                                      '${calulatePersentage(cal[index]['value'])}%',
                                      style: TextStyle(color: Colors.red[500]),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  );
                })
      ],
    ));
  }
}
