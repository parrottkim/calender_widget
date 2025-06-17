import 'package:calender_widget/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ko', '')],
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DateTime? start;
  DateTime? end;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: start.toString()),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: TextEditingController(text: end.toString()),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  final selectedDates = await showDialog<List<DateTime?>>(
                    context: context,
                    builder: (_) => DateRangeDialog(start: start, end: end),
                  );

                  if (selectedDates != null && selectedDates.length == 2) {
                    setState(() {
                      start = selectedDates[0];
                      end = selectedDates[1];
                    });
                  }
                },

                child: Text('Selecte Date'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
