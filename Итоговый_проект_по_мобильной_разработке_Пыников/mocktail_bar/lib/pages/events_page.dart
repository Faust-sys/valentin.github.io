import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';

// Drawer
import 'home_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<String>> _events = {};

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  // Загрузка событий из Supabase
  Future<void> _loadEventsFromDB() async {
    final data = await Supabase.instance.client
        .from("events")
        .select()
        .order("date", ascending: true);

    _events.clear();

    for (final e in data) {
      final date = DateTime.parse(e["date"]);
      final key = _normalize(date);
      final title = e["title"] as String;

      if (!_events.containsKey(key)) {
        _events[key] = [];
      }

      _events[key]!.add(title);
    }

    setState(() {});
  }

  // Добавление события в БД
  Future<void> _saveEventToDB(DateTime day, String title) async {
    final date = _normalize(day).toIso8601String();

    await Supabase.instance.client.from("events").insert({
      "title": title,
      "date": date,
    });
  }

  // Удаление события из БД
  Future<void> _deleteEventFromDB(DateTime day, String title) async {
    final date = _normalize(day).toIso8601String();

    await Supabase.instance.client
        .from("events")
        .delete()
        .match({"title": title, "date": date});
  }

  // Получение списка событий для дня
  List<String> _getEventsForDay(DateTime day) {
    final key = _normalize(day);
    return _events[key] ?? [];
  }

  // Добавление события локально и в БД
  Future<void> _addEvent(DateTime day, String title) async {
    final key = _normalize(day);

    _events[key] = (_events[key] ?? [])..add(title);

    await _saveEventToDB(day, title);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadEventsFromDB();
  }

  

  @override
  Widget build(BuildContext context) {
    final currentDay = _selectedDay ?? _focusedDay;
    final selectedEvents = _getEventsForDay(currentDay);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const ModernDrawer(),

      appBar: AppBar(
        title: const Text(
          'Календарь мероприятий',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Positioned(
            top: -80,
            left: -40,
            child: _blurCircle(260, Colors.pinkAccent.withOpacity(0.4)),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: _blurCircle(300, Colors.cyanAccent.withOpacity(0.35)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  const Text(
                    "Наши мероприятия",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Следите за событиями в нашем безалкогольном баре!",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),

                  const SizedBox(height: 25),

                  _glassCard(
                    padding: 0,
                    child: TableCalendar(
                      firstDay: DateTime.utc(2023, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      eventLoader: _getEventsForDay,
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },

                      calendarStyle: const CalendarStyle(
                        defaultTextStyle: TextStyle(color: Colors.white),
                        weekendTextStyle: TextStyle(color: Colors.white70),
                        selectedDecoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(color: Colors.black),
                        todayDecoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(color: Colors.white),
                        markerDecoration: BoxDecoration(
                          color: Colors.cyanAccent,
                          shape: BoxShape.circle,
                        ),
                      ),

                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        leftChevronIcon:
                            Icon(Icons.chevron_left, color: Colors.white),
                        rightChevronIcon:
                            Icon(Icons.chevron_right, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: _glassCard(
                      child: selectedEvents.isEmpty
                          ? const Center(
                              child: Text(
                                "Событий нет",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 18),
                              ),
                            )
                          : ListView.builder(
                              itemCount: selectedEvents.length,
                              itemBuilder: (_, i) {
                                final event = selectedEvents[i];

                                return ListTile(
                                  leading: const Icon(Icons.event,
                                      color: Colors.cyanAccent),

                                  title: Text(
                                    event,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),

                                  trailing: AppState.isAdmin
                                      ? IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.redAccent),
                                          onPressed: () async {
                                            await _deleteEventFromDB(
                                                currentDay, event);

                                            setState(() {
                                              _events[_normalize(currentDay)]
                                                  ?.remove(event);
                                            });
                                          },
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: AppState.isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurpleAccent,
              child: const Icon(Icons.add),
              onPressed: () async {
                if (_selectedDay == null) return;

                final controller = TextEditingController();

                final bool? result = await showDialog<bool>(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: const Text("Новое событие"),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: "Введите название",
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text("Отмена"),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text("Добавить"),
                        ),
                      ],
                    );
                  },
                );

                if (result == true &&
                    controller.text.trim().isNotEmpty) {
                  await _addEvent(
                      _selectedDay!, controller.text.trim());
                  setState(() {});
                }
              },
            )
          : null,
    );
  }

  Widget _glassCard({required Widget child, double padding = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 90,
              spreadRadius: 50),
        ],
      ),
    );
  }
}
