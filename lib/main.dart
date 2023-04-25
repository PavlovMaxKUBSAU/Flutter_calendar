library event_calendar;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
//import 'package:permission_handler/permission_handler.dart';

part 'meeting-editor.dart';
part 'color-picker.dart';

List<Color> _colorList = <Color>[];
List<String> _colorNames = <String>[];
int _selectedColorIndex = 0;
late DataSource event_list;
Meeting? _selectedAppointment;
late DateTime _startDate;
late TimeOfDay _startTime;
late DateTime _endDate;
late TimeOfDay _endTime;
bool _isAllDay = false;
String _subject = '';
String _notes = '';
File? file_json;


void main() {
  runApp(const MaterialApp(
      home: HomeApp(),
      debugShowCheckedModeBanner: false,
    ));
}

class HomeApp extends StatefulWidget {
  const HomeApp({Key? key}) : super(key: key);

  @override
  HomeAppState createState() => HomeAppState();
}

class HomeAppState extends State<HomeApp> {

  HomeAppState();
  late List<Meeting> appointments;
  CalendarController calendarController = CalendarController();

  @override
  void initState() {
    Get_localFile().then((value) => file_json=value);
    appointments = getMeetingDetails();
    event_list = DataSource(appointments);
    _selectedAppointment = null;
    _selectedColorIndex = 0;
    _subject = '';
    _notes = '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Padding(
            padding: const EdgeInsets.all(6),
            child: getEventCalendar(event_list, onCalendarTapped)));
  }

  SfCalendar getEventCalendar(CalendarDataSource _calendarDataSource, CalendarTapCallback calendarTapCallback) {
    return SfCalendar(
        view: CalendarView.month,
        controller: calendarController,
        allowedViews: const [CalendarView.month, CalendarView.schedule, CalendarView.day],
        dataSource: _calendarDataSource,
        onTap: calendarTapCallback,
        appointmentBuilder: (context, calendarAppointmentDetails) {
          final Meeting meeting = calendarAppointmentDetails.appointments.first;
          return Container(
            color: meeting.background.withOpacity(0.7),
            child: Text(meeting.eventName),
          );
        },
        initialDisplayDate: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 0, 0, 0),
        monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment),
        timeSlotViewSettings: const TimeSlotViewSettings(
            minimumAppointmentDuration: Duration(minutes: 60)));
  }

  void onCalendarTapped(CalendarTapDetails calendarTapDetails) {
    if (calendarTapDetails.targetElement != CalendarElement.calendarCell &&
        calendarTapDetails.targetElement != CalendarElement.appointment) {
      return;
    }

    setState(() {
      _selectedAppointment = null;
      _isAllDay = false;
      _selectedColorIndex = 0;
      _subject = '';
      _notes = '';

      if (calendarController.view == CalendarView.month) {
        calendarController.view = CalendarView.day;
      } else {
        if (calendarTapDetails.appointments != null && calendarTapDetails.appointments!.length == 1) {

          final Meeting meetingDetails = calendarTapDetails.appointments![0];

          _startDate = meetingDetails.from;
          _endDate = meetingDetails.to;
          _isAllDay = meetingDetails.isAllDay;
          _selectedColorIndex = _colorList.indexOf(meetingDetails.background);
          _subject = meetingDetails.eventName == '(No title)'
              ? ''
              : meetingDetails.eventName;
          _notes = meetingDetails.description;
          _selectedAppointment = meetingDetails;
        } else {
          final DateTime date = calendarTapDetails.date!;
          _startDate = date;
          _endDate = date.add(const Duration(hours: 1));
        }

        _startTime =
            TimeOfDay(hour: _startDate.hour, minute: _startDate.minute);
        _endTime = TimeOfDay(hour: _endDate.hour, minute: _endDate.minute);
        Navigator.push<Widget>(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => const MeetingEditor()),
        );
      }
    });
  }

  List<Meeting> getMeetingDetails() {
    List<Meeting> meetingCollection = <Meeting>[];

    _colorList = <Color>[];
    _colorList.add(Colors.green);
    _colorList.add(Colors.purple);
    _colorList.add(Colors.red);
    _colorList.add(Colors.orange);
    _colorList.add(Colors.cyanAccent);
    _colorList.add(Colors.pink);
    _colorList.add(Colors.blueAccent);
    _colorList.add(Colors.amberAccent);
    _colorList.add(Colors.grey);

    _colorNames = <String>[];
    _colorNames.add('Green');
    _colorNames.add('Purple');
    _colorNames.add('Red');
    _colorNames.add('Orange');
    _colorNames.add('Cyan');
    _colorNames.add('Magenta');
    _colorNames.add('Blue');
    _colorNames.add('Amber');
    _colorNames.add('Gray');

    final DateTime today = DateTime.now();
    final Random random = Random();

    // for (int month = -1; month < 2; month++) {
    //   for (int day = -5; day < 3; day++) {
    //     for (int hour = 9; hour < 16; hour += 5) {
    //       meetingCollection.add(Meeting(
    //         from: today
    //             .add(Duration(days: (month * 30) + day))
    //             .add(Duration(hours: hour)),
    //         to: today
    //             .add(Duration(days: (month * 30) + day))
    //             .add(Duration(hours: hour + 2)),
    //         background: _colorList[random.nextInt(9)],
    //         description: '',
    //         isAllDay: false,
    //         eventName: 'Событие ${random.nextInt(10000)}',
    //       ));
    //     }
    //   }
    // }

    final decoded = jsonDecode(file_json!.readAsStringSync()) as List<dynamic>;
    meetingCollection = decoded.map((d) => Meeting.fromJson(d as Map<String, dynamic>)).toList();

    return meetingCollection;
  }
}

Future<File> Get_localFile() async {
  var appDocDir = await getTemporaryDirectory();
  String appDocPath = appDocDir.path + '/event_list.json';


  File file = File(appDocPath);
  if (!file.existsSync()) {
    file.createSync();
  }

  return file;
}


class DataSource extends CalendarDataSource {
  DataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  bool isAllDay(int index) => appointments![index].isAllDay;

  @override
  String getSubject(int index) => appointments![index].eventName;

  @override
  String getNotes(int index) => appointments![index].description;

  @override
  Color getColor(int index) => appointments![index].background;

  @override
  DateTime getStartTime(int index) => appointments![index].from;

  @override
  DateTime getEndTime(int index) => appointments![index].to;
}

class Meeting {
  Meeting({
    required this.from,
    required this.to,
      this.background = Colors.green,
      this.isAllDay = false,
      this.eventName = '',
      this.description = ''});

  final String eventName;
  final DateTime from;
  final DateTime to;
  final Color background;
  final bool isAllDay;
  final String description;

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      eventName: json['eventName'] as String,
      from: DateTime.fromMicrosecondsSinceEpoch(json['from']),
      to: DateTime.fromMicrosecondsSinceEpoch(json['to']),
      background: json['background'] as Color,
      isAllDay: json['isAllDay'] as bool,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'eventName': eventName.toString(),
    'from': from.millisecondsSinceEpoch.toString(),
    'to': to.millisecondsSinceEpoch.toString(),
    'background': background.toString(),
    'isAllDay': isAllDay.toString(),
    'description': description.toString(),
  };
}
