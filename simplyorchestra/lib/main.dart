import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await EventStore.load();
  runApp(EventOpsApp(store: store));
}

class EventOpsApp extends StatelessWidget {
  const EventOpsApp({super.key, required this.store});

  final EventStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EventOps',
      theme: EventTheme.dark(),
      home: EventOpsHome(store: store),
    );
  }
}

class EventOpsHome extends StatefulWidget {
  const EventOpsHome({super.key, required this.store});

  final EventStore store;

  @override
  State<EventOpsHome> createState() => _EventOpsHomeState();
}

class _EventOpsHomeState extends State<EventOpsHome> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(store: widget.store, goTo: _goTo),
      TasksScreen(store: widget.store),
      IssuesScreen(store: widget.store),
      ShiftsScreen(store: widget.store),
      TimelineScreen(store: widget.store),
      SettingsScreen(store: widget.store),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF071018), Color(0xFF0B111D), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(child: screens[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Issues',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Shifts',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class EventTheme {
  static const background = Color(0xFF071018);
  static const surface = Color(0xFF101927);
  static const surfaceHigh = Color(0xFF172235);
  static const border = Color(0xFF26364D);
  static const textMuted = Color(0xFF9CA8BA);
  static const accent = Color(0xFF38BDF8);
  static const good = Color(0xFF34D399);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFFB7185);
  static const violet = Color(0xFFA78BFA);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: scheme.copyWith(
        primary: accent,
        secondary: good,
        surface: surface,
        error: danger,
      ),
      fontFamily: 'Avenir',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF08111C),
        indicatorColor: accent.withValues(alpha: 0.18),
        height: 64,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF041018),
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

bool isCompactWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 390;

double screenPadding(BuildContext context) => isCompactWidth(context) ? 12 : 18;

enum EventRole {
  eventLead,
  areaLead,
  helper,
  entryTeam,
  barCashier,
  tech,
  security,
  firstAid,
  runner,
}

enum Area {
  entry,
  bar,
  cashDesk,
  tech,
  security,
  firstAid,
  setup,
  cleanup,
  runner,
  eventLead,
}

enum TaskStatus { open, inProgress, waiting, done }

enum IssueStatus { open, inProgress, resolved }

enum Priority { low, normal, important, critical }

enum TimelineStatus { planned, running, done, delayed, cancelled }

extension EventRoleLabel on EventRole {
  String get label => switch (this) {
    EventRole.eventLead => 'Event Lead',
    EventRole.areaLead => 'Area Lead',
    EventRole.helper => 'Helper',
    EventRole.entryTeam => 'Entry Team',
    EventRole.barCashier => 'Bar / Cashier',
    EventRole.tech => 'Tech',
    EventRole.security => 'Security / Supervision',
    EventRole.firstAid => 'First Aid',
    EventRole.runner => 'Runner',
  };
}

extension AreaLabel on Area {
  String get label => switch (this) {
    Area.entry => 'Entry',
    Area.bar => 'Bar',
    Area.cashDesk => 'Cash Desk',
    Area.tech => 'Tech',
    Area.security => 'Security',
    Area.firstAid => 'First Aid',
    Area.setup => 'Setup',
    Area.cleanup => 'Cleanup',
    Area.runner => 'Runner',
    Area.eventLead => 'Event Lead',
  };
}

extension TaskStatusLabel on TaskStatus {
  String get label => switch (this) {
    TaskStatus.open => 'Open',
    TaskStatus.inProgress => 'In Progress',
    TaskStatus.waiting => 'Waiting',
    TaskStatus.done => 'Done',
  };
}

extension IssueStatusLabel on IssueStatus {
  String get label => switch (this) {
    IssueStatus.open => 'Open',
    IssueStatus.inProgress => 'In Progress',
    IssueStatus.resolved => 'Resolved',
  };
}

extension PriorityLabel on Priority {
  String get label => switch (this) {
    Priority.low => 'Low',
    Priority.normal => 'Normal',
    Priority.important => 'Important',
    Priority.critical => 'Critical',
  };
}

extension TimelineStatusLabel on TimelineStatus {
  String get label => switch (this) {
    TimelineStatus.planned => 'Planned',
    TimelineStatus.running => 'Running',
    TimelineStatus.done => 'Done',
    TimelineStatus.delayed => 'Delayed',
    TimelineStatus.cancelled => 'Cancelled',
  };
}

T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class EventTask {
  const EventTask({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.assignedTo,
    required this.priority,
    required this.status,
    required this.dueTime,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final Area area;
  final String assignedTo;
  final Priority priority;
  final TaskStatus status;
  final String dueTime;
  final DateTime createdAt;

  EventTask copyWith({TaskStatus? status}) => EventTask(
    id: id,
    title: title,
    description: description,
    area: area,
    assignedTo: assignedTo,
    priority: priority,
    status: status ?? this.status,
    dueTime: dueTime,
    createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'area': area.name,
    'assignedTo': assignedTo,
    'priority': priority.name,
    'status': status.name,
    'dueTime': dueTime,
    'createdAt': createdAt.toIso8601String(),
  };

  factory EventTask.fromJson(Map<String, Object?> json) => EventTask(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    area: enumByName(Area.values, json['area'] as String?, Area.eventLead),
    assignedTo: json['assignedTo'] as String,
    priority: enumByName(
      Priority.values,
      json['priority'] as String?,
      Priority.normal,
    ),
    status: enumByName(
      TaskStatus.values,
      json['status'] as String?,
      TaskStatus.open,
    ),
    dueTime: json['dueTime'] as String,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class EventIssue {
  const EventIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.priority,
    required this.status,
    required this.reportedBy,
    required this.assignedTo,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String title;
  final String description;
  final Area area;
  final Priority priority;
  final IssueStatus status;
  final String reportedBy;
  final String assignedTo;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  EventIssue copyWith({IssueStatus? status, DateTime? resolvedAt}) =>
      EventIssue(
        id: id,
        title: title,
        description: description,
        area: area,
        priority: priority,
        status: status ?? this.status,
        reportedBy: reportedBy,
        assignedTo: assignedTo,
        createdAt: createdAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'area': area.name,
    'priority': priority.name,
    'status': status.name,
    'reportedBy': reportedBy,
    'assignedTo': assignedTo,
    'createdAt': createdAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  factory EventIssue.fromJson(Map<String, Object?> json) => EventIssue(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    area: enumByName(Area.values, json['area'] as String?, Area.eventLead),
    priority: enumByName(
      Priority.values,
      json['priority'] as String?,
      Priority.normal,
    ),
    status: enumByName(
      IssueStatus.values,
      json['status'] as String?,
      IssueStatus.open,
    ),
    reportedBy: json['reportedBy'] as String,
    assignedTo: json['assignedTo'] as String,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    resolvedAt: DateTime.tryParse(json['resolvedAt'] as String? ?? ''),
  );
}

class Shift {
  const Shift({
    required this.id,
    required this.personName,
    required this.area,
    required this.startTime,
    required this.endTime,
    required this.roleDuringShift,
  });

  final String id;
  final String personName;
  final Area area;
  final String startTime;
  final String endTime;
  final String roleDuringShift;
}

class TimelineItem {
  const TimelineItem({
    required this.id,
    required this.title,
    required this.time,
    required this.description,
    required this.status,
  });

  final String id;
  final String title;
  final String time;
  final String description;
  final TimelineStatus status;
}

class EventStore extends ChangeNotifier {
  EventStore._(this._prefs);

  static const _roleKey = 'eventops.role';
  static const _guestsKey = 'eventops.guests';
  static const _revenueKey = 'eventops.revenue';
  static const _tasksKey = 'eventops.tasks';
  static const _issuesKey = 'eventops.issues';
  static const maxGuests = 300;

  final SharedPreferences _prefs;

  EventRole role = EventRole.eventLead;
  int guestCount = 184;
  int revenue = 1840;
  List<EventTask> tasks = [];
  List<EventIssue> issues = [];

  static Future<EventStore> load() async {
    final store = EventStore._(await SharedPreferences.getInstance());
    store._restore();
    return store;
  }

  void _restore() {
    role = enumByName(
      EventRole.values,
      _prefs.getString(_roleKey),
      EventRole.eventLead,
    );
    guestCount = _prefs.getInt(_guestsKey) ?? 184;
    revenue = _prefs.getInt(_revenueKey) ?? 1840;
    tasks = _readTasks() ?? seedTasks();
    issues = _readIssues() ?? seedIssues();
  }

  List<EventTask>? _readTasks() {
    final raw = _prefs.getString(_tasksKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, Object?>>()
        .map(EventTask.fromJson)
        .toList();
  }

  List<EventIssue>? _readIssues() {
    final raw = _prefs.getString(_issuesKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, Object?>>()
        .map(EventIssue.fromJson)
        .toList();
  }

  Future<void> _persist() async {
    await _prefs.setString(_roleKey, role.name);
    await _prefs.setInt(_guestsKey, guestCount);
    await _prefs.setInt(_revenueKey, revenue);
    await _prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
    await _prefs.setString(
      _issuesKey,
      jsonEncode(issues.map((issue) => issue.toJson()).toList()),
    );
  }

  Future<void> _saveAndNotify() async {
    await _persist();
    notifyListeners();
  }

  Future<void> setRole(EventRole nextRole) async {
    role = nextRole;
    await _saveAndNotify();
  }

  Future<void> changeGuests(int delta) async {
    guestCount = (guestCount + delta).clamp(0, maxGuests);
    await _saveAndNotify();
  }

  Future<void> addRevenue(int amount) async {
    if (amount <= 0) return;
    revenue += amount;
    await _saveAndNotify();
  }

  Future<void> addTask(EventTask task) async {
    tasks = [task, ...tasks];
    await _saveAndNotify();
  }

  Future<void> updateTaskStatus(String id, TaskStatus status) async {
    tasks = [
      for (final task in tasks)
        task.id == id ? task.copyWith(status: status) : task,
    ];
    await _saveAndNotify();
  }

  Future<void> addIssue(EventIssue issue) async {
    issues = [issue, ...issues];
    await _saveAndNotify();
  }

  Future<void> updateIssueStatus(String id, IssueStatus status) async {
    issues = [
      for (final issue in issues)
        issue.id == id
            ? issue.copyWith(
                status: status,
                resolvedAt: status == IssueStatus.resolved
                    ? DateTime.now()
                    : issue.resolvedAt,
              )
            : issue,
    ];
    await _saveAndNotify();
  }

  Future<void> resetDemoData() async {
    role = EventRole.eventLead;
    guestCount = 184;
    revenue = 1840;
    tasks = seedTasks();
    issues = seedIssues();
    await _saveAndNotify();
  }

  List<EventTask> get visibleTasks =>
      tasks.where((task) => _areaVisible(task.area, task.assignedTo)).toList();

  List<EventIssue> get visibleIssues => issues
      .where((issue) => _areaVisible(issue.area, issue.assignedTo))
      .toList();

  List<Shift> get visibleShifts => seedShifts()
      .where((shift) => _areaVisible(shift.area, shift.roleDuringShift))
      .toList();

  bool _areaVisible(Area area, String assignedTo) {
    if (role == EventRole.eventLead || role == EventRole.areaLead) return true;
    final label = assignedTo.toLowerCase();
    return switch (role) {
      EventRole.helper =>
        !label.contains('lead') ||
            area == Area.setup ||
            area == Area.cleanup ||
            area == Area.runner,
      EventRole.entryTeam => area == Area.entry || area == Area.cashDesk,
      EventRole.barCashier => area == Area.bar || area == Area.cashDesk,
      EventRole.tech => area == Area.tech,
      EventRole.security => area == Area.security,
      EventRole.firstAid => area == Area.firstAid,
      EventRole.runner => area == Area.runner,
      EventRole.eventLead || EventRole.areaLead => true,
    };
  }

  int get openTaskCount =>
      visibleTasks.where((task) => task.status != TaskStatus.done).length;

  int get criticalIssueCount => visibleIssues
      .where(
        (issue) =>
            issue.priority == Priority.critical &&
            issue.status != IssueStatus.resolved,
      )
      .length;

  int get activeHelpers => 6;

  TimelineItem get currentTimeline => seedTimeline().firstWhere(
    (item) => item.status == TimelineStatus.running,
  );

  TimelineItem get nextTimeline => seedTimeline().firstWhere(
    (item) => item.status == TimelineStatus.planned,
    orElse: () => seedTimeline().last,
  );

  static List<EventTask> seedTasks() {
    final now = DateTime.now();
    return [
      EventTask(
        id: 'task-cash-desk',
        title: 'Prepare cash desk',
        description: 'Count starter cash, check receipt roll and card reader.',
        area: Area.cashDesk,
        assignedTo: 'Bar / Cashier',
        priority: Priority.important,
        status: TaskStatus.inProgress,
        dueTime: '18:30',
        createdAt: now,
      ),
      EventTask(
        id: 'task-exits',
        title: 'Check emergency exits',
        description: 'Walk all routes and confirm signs are visible.',
        area: Area.security,
        assignedTo: 'Security / Supervision',
        priority: Priority.critical,
        status: TaskStatus.open,
        dueTime: '18:45',
        createdAt: now,
      ),
      EventTask(
        id: 'task-drinks',
        title: 'Refill drinks',
        description: 'Move cold bottles from storage into the bar fridge.',
        area: Area.bar,
        assignedTo: 'Bar / Cashier',
        priority: Priority.normal,
        status: TaskStatus.open,
        dueTime: '21:00',
        createdAt: now,
      ),
      EventTask(
        id: 'task-cola',
        title: 'Bring Cola crates to bar',
        description: 'Take two crates from storage to bar station 1.',
        area: Area.runner,
        assignedTo: 'Runner',
        priority: Priority.important,
        status: TaskStatus.waiting,
        dueTime: '20:45',
        createdAt: now,
      ),
      EventTask(
        id: 'task-mic',
        title: 'Test microphone 2',
        description: 'Check noise level and battery before program point.',
        area: Area.tech,
        assignedTo: 'Tech',
        priority: Priority.important,
        status: TaskStatus.open,
        dueTime: '20:10',
        createdAt: now,
      ),
      EventTask(
        id: 'task-toilets',
        title: 'Check toilet supplies',
        description: 'Restock paper towels and toilet paper in both areas.',
        area: Area.cleanup,
        assignedTo: 'Helper',
        priority: Priority.normal,
        status: TaskStatus.open,
        dueTime: '21:30',
        createdAt: now,
      ),
      EventTask(
        id: 'task-wristbands',
        title: 'Prepare wristbands',
        description: 'Sort age bands and entry bands at the front desk.',
        area: Area.entry,
        assignedTo: 'Entry Team',
        priority: Priority.low,
        status: TaskStatus.done,
        dueTime: '18:20',
        createdAt: now,
      ),
    ];
  }

  static List<EventIssue> seedIssues() {
    final now = DateTime.now();
    return [
      EventIssue(
        id: 'issue-toilet-paper',
        title: 'Toilet paper empty',
        description: 'Guest toilet left side needs immediate restock.',
        area: Area.cleanup,
        priority: Priority.important,
        status: IssueStatus.open,
        reportedBy: 'Helper',
        assignedTo: 'Runner',
        createdAt: now,
      ),
      EventIssue(
        id: 'issue-change-money',
        title: 'Cash desk needs change money',
        description: 'Low on coins for 20 euro notes.',
        area: Area.cashDesk,
        priority: Priority.critical,
        status: IssueStatus.open,
        reportedBy: 'Cash Desk',
        assignedTo: 'Event Lead',
        createdAt: now,
      ),
      EventIssue(
        id: 'issue-mic-noisy',
        title: 'Microphone noisy',
        description: 'Mic 2 has crackling noise on channel 4.',
        area: Area.tech,
        priority: Priority.important,
        status: IssueStatus.inProgress,
        reportedBy: 'Stage',
        assignedTo: 'Tech',
        createdAt: now,
      ),
      EventIssue(
        id: 'issue-entry-line',
        title: 'Entry line too long',
        description: 'Queue is outside the main door.',
        area: Area.entry,
        priority: Priority.important,
        status: IssueStatus.open,
        reportedBy: 'Entry Team',
        assignedTo: 'Area Lead',
        createdAt: now,
      ),
      EventIssue(
        id: 'issue-cola-low',
        title: 'Cola almost empty',
        description: 'Only one crate left at the bar.',
        area: Area.bar,
        priority: Priority.normal,
        status: IssueStatus.open,
        reportedBy: 'Bar',
        assignedTo: 'Runner',
        createdAt: now,
      ),
      EventIssue(
        id: 'issue-assistance',
        title: 'Person needs assistance',
        description: 'First aid should check a guest near entry.',
        area: Area.firstAid,
        priority: Priority.critical,
        status: IssueStatus.inProgress,
        reportedBy: 'Security',
        assignedTo: 'First Aid',
        createdAt: now,
      ),
    ];
  }
}

List<Shift> seedShifts() => const [
  Shift(
    id: 'shift-theo',
    personName: 'Theo',
    area: Area.entry,
    startTime: '18:00',
    endTime: '20:00',
    roleDuringShift: 'Entry',
  ),
  Shift(
    id: 'shift-erik',
    personName: 'Erik',
    area: Area.entry,
    startTime: '18:00',
    endTime: '20:00',
    roleDuringShift: 'Entry Lead',
  ),
  Shift(
    id: 'shift-anna',
    personName: 'Anna',
    area: Area.bar,
    startTime: '20:00',
    endTime: '22:00',
    roleDuringShift: 'Bar',
  ),
  Shift(
    id: 'shift-max',
    personName: 'Max',
    area: Area.runner,
    startTime: '22:00',
    endTime: '00:00',
    roleDuringShift: 'Runner',
  ),
  Shift(
    id: 'shift-jonas',
    personName: 'Jonas',
    area: Area.tech,
    startTime: '20:00',
    endTime: '23:00',
    roleDuringShift: 'Tech',
  ),
  Shift(
    id: 'shift-clara',
    personName: 'Clara',
    area: Area.firstAid,
    startTime: '19:00',
    endTime: '23:00',
    roleDuringShift: 'First Aid',
  ),
];

List<TimelineItem> seedTimeline() => const [
  TimelineItem(
    id: 'setup',
    title: 'Setup',
    time: '17:00',
    description: 'Stations, signs and backstage desk ready.',
    status: TimelineStatus.done,
  ),
  TimelineItem(
    id: 'briefing',
    title: 'Helper briefing',
    time: '18:30',
    description: 'Roles, emergency routes and escalation process.',
    status: TimelineStatus.done,
  ),
  TimelineItem(
    id: 'entry',
    title: 'Entry starts',
    time: '19:00',
    description: 'Open doors, start guest counter and cash desk.',
    status: TimelineStatus.running,
  ),
  TimelineItem(
    id: 'program',
    title: 'Program point',
    time: '20:30',
    description: 'Short announcement from the stage.',
    status: TimelineStatus.planned,
  ),
  TimelineItem(
    id: 'bar-change',
    title: 'Bar shift change',
    time: '21:00',
    description: 'Anna takes over bar responsibility.',
    status: TimelineStatus.planned,
  ),
  TimelineItem(
    id: 'dj-change',
    title: 'DJ change',
    time: '22:30',
    description: 'Tech checks transition and channel levels.',
    status: TimelineStatus.planned,
  ),
  TimelineItem(
    id: 'last-entry',
    title: 'Last entry',
    time: '01:30',
    description: 'Close guest entry and reconcile wristbands.',
    status: TimelineStatus.planned,
  ),
  TimelineItem(
    id: 'event-end',
    title: 'Event end',
    time: '03:00',
    description: 'Music off, guests out, safety walk.',
    status: TimelineStatus.planned,
  ),
  TimelineItem(
    id: 'cleanup',
    title: 'Cleanup',
    time: '03:15',
    description: 'Pack stations and hand over venue.',
    status: TimelineStatus.planned,
  ),
];

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store, required this.goTo});

  final EventStore store;
  final ValueChanged<int> goTo;

  @override
  Widget build(BuildContext context) {
    final criticalIssues = store.visibleIssues
        .where(
          (issue) =>
              issue.priority == Priority.critical &&
              issue.status != IssueStatus.resolved,
        )
        .toList();

    return AppScroll(
      children: [
        AppHeader(
          eyebrow: 'LIVE EVENT DASHBOARD',
          title: 'EventOps',
          trailing: StatusChip(
            label: store.role.label,
            color: EventTheme.accent,
          ),
        ),
        EventHero(store: store),
        ResponsiveCardGrid(
          children: [
            MetricCard(
              title: 'Visitors',
              value: '${store.guestCount} / ${EventStore.maxGuests}',
              icon: Icons.confirmation_number_outlined,
              color: EventTheme.accent,
              footer:
                  'Capacity ${((store.guestCount / EventStore.maxGuests) * 100).round()}%',
            ),
            MetricCard(
              title: 'Revenue',
              value: '${formatCurrency(store.revenue)} €',
              icon: Icons.payments_outlined,
              color: EventTheme.good,
              footer: 'Local counter',
            ),
            MetricCard(
              title: 'Open Tasks',
              value: '${store.openTaskCount}',
              icon: Icons.playlist_add_check_circle_outlined,
              color: EventTheme.warning,
              footer: 'Visible for role',
            ),
            MetricCard(
              title: 'Critical Issues',
              value: '${store.criticalIssueCount}',
              icon: Icons.warning_amber_rounded,
              color: EventTheme.danger,
              footer: 'Needs escalation',
            ),
            MetricCard(
              title: 'Active Helpers',
              value: '${store.activeHelpers}',
              icon: Icons.groups_2_outlined,
              color: EventTheme.violet,
              footer: 'On shift now/upcoming',
            ),
            MetricCard(
              title: 'Next Event',
              value: store.nextTimeline.time,
              icon: Icons.schedule_outlined,
              color: EventTheme.accent,
              footer: store.nextTimeline.title,
            ),
          ],
        ),
        SectionCard(
          title: 'Overall Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusChip(label: 'Running', color: EventTheme.good),
              const SizedBox(height: 16),
              TimelineSummaryRow(
                label: 'Current',
                item: store.currentTimeline,
                color: EventTheme.good,
              ),
              const Divider(height: 28),
              TimelineSummaryRow(
                label: 'Next',
                item: store.nextTimeline,
                color: EventTheme.accent,
              ),
            ],
          ),
        ),
        SectionHeader(
          title: 'Quick Actions',
          action: store.role == EventRole.eventLead
              ? 'Lead view'
              : store.role.label,
        ),
        QuickActionGrid(
          actions: [
            QuickActionData(
              label: 'Report Problem',
              icon: Icons.report_problem_outlined,
              onTap: () => showIssueSheet(context, store),
            ),
            QuickActionData(
              label: 'Create Task',
              icon: Icons.add_task_outlined,
              onTap: () => showTaskSheet(context, store),
            ),
            QuickActionData(
              label: 'Add Guest',
              icon: Icons.person_add_alt_1_outlined,
              onTap: () => store.changeGuests(1),
            ),
            QuickActionData(
              label: 'Remove Guest',
              icon: Icons.person_remove_alt_1_outlined,
              onTap: () => store.changeGuests(-1),
            ),
            QuickActionData(
              label: 'Add Revenue',
              icon: Icons.euro_outlined,
              onTap: () => showRevenueSheet(context, store),
            ),
            QuickActionData(
              label: 'View Timeline',
              icon: Icons.timeline_outlined,
              onTap: () => goTo(4),
            ),
            QuickActionData(
              label: 'View Shifts',
              icon: Icons.groups_outlined,
              onTap: () => goTo(3),
            ),
          ],
        ),
        if (criticalIssues.isNotEmpty) ...[
          const SectionHeader(title: 'Critical Issues', action: 'Escalate now'),
          for (final issue in criticalIssues.take(3))
            IssueRow(issue: issue, store: store),
        ],
      ],
    );
  }
}

class EventHero extends StatelessWidget {
  const EventHero({super.key, required this.store});

  final EventStore store;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        gradient: const LinearGradient(
          colors: [Color(0xFF123047), Color(0xFF102033), Color(0xFF151B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: EventTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusChip(label: 'Running', color: EventTheme.good),
              const Spacer(),
              Text(
                'Stadthalle',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: EventTheme.textMuted),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 18),
          Text(
            'Abiparty März',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: compact ? 27 : null),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            'Backstage command center for organizers, helpers and area leads.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: EventTheme.textMuted),
          ),
          SizedBox(height: compact ? 16 : 20),
          LinearProgressIndicator(
            value: store.guestCount / EventStore.maxGuests,
            minHeight: compact ? 8 : 10,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.store});

  final EventStore store;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskStatus? _status;

  @override
  Widget build(BuildContext context) {
    final tasks = widget.store.visibleTasks
        .where((task) => _status == null || task.status == _status)
        .toList();

    return AppScroll(
      children: [
        AppHeader(
          eyebrow: 'WORK QUEUE',
          title: 'Tasks',
          trailing: IconButton.filled(
            tooltip: 'Create task',
            onPressed: () => showTaskSheet(context, widget.store),
            icon: const Icon(Icons.add),
          ),
        ),
        FilterChips<TaskStatus>(
          values: TaskStatus.values,
          selected: _status,
          labelFor: (status) => status.label,
          onSelected: (status) => setState(() => _status = status),
          onClear: () => setState(() => _status = null),
        ),
        if (tasks.isEmpty)
          const EmptyState(message: 'No tasks match this role/filter.')
        else
          for (final task in tasks) TaskRow(task: task, store: widget.store),
      ],
    );
  }
}

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key, required this.store});

  final EventStore store;

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  IssueStatus? _status;

  @override
  Widget build(BuildContext context) {
    final issues = widget.store.visibleIssues
        .where((issue) => _status == null || issue.status == _status)
        .toList();

    return AppScroll(
      children: [
        AppHeader(
          eyebrow: 'PROBLEM REPORTS',
          title: 'Issues',
          trailing: IconButton.filled(
            tooltip: 'Create issue',
            onPressed: () => showIssueSheet(context, widget.store),
            icon: const Icon(Icons.add),
          ),
        ),
        FilterChips<IssueStatus>(
          values: IssueStatus.values,
          selected: _status,
          labelFor: (status) => status.label,
          onSelected: (status) => setState(() => _status = status),
          onClear: () => setState(() => _status = null),
        ),
        if (issues.isEmpty)
          const EmptyState(message: 'No issues match this role/filter.')
        else
          for (final issue in issues)
            IssueRow(issue: issue, store: widget.store),
      ],
    );
  }
}

class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key, required this.store});

  final EventStore store;

  @override
  Widget build(BuildContext context) {
    final shifts = [...store.visibleShifts]
      ..sort((a, b) {
        final currentA = isCurrentShift(a);
        final currentB = isCurrentShift(b);
        if (currentA != currentB) return currentA ? -1 : 1;
        return a.startTime.compareTo(b.startTime);
      });

    return AppScroll(
      children: [
        const AppHeader(eyebrow: 'RESPONSIBILITIES', title: 'Shifts'),
        const SectionHeader(
          title: 'Current First',
          action: 'Local demo roster',
        ),
        for (final shift in shifts)
          ListCard(
            leading: Icon(
              isCurrentShift(shift)
                  ? Icons.radio_button_checked
                  : Icons.schedule,
              color: isCurrentShift(shift)
                  ? EventTheme.good
                  : EventTheme.accent,
            ),
            title: '${shift.personName} · ${shift.roleDuringShift}',
            subtitle:
                '${shift.startTime}-${shift.endTime} · ${shift.area.label}',
            trailing: isCurrentShift(shift)
                ? const StatusChip(label: 'Current', color: EventTheme.good)
                : const StatusChip(label: 'Upcoming', color: EventTheme.accent),
          ),
      ],
    );
  }
}

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key, required this.store});

  final EventStore store;

  @override
  Widget build(BuildContext context) {
    final timeline = seedTimeline();
    return AppScroll(
      children: [
        const AppHeader(eyebrow: 'RUN OF SHOW', title: 'Timeline'),
        SectionCard(
          title: 'Now / Next',
          child: Column(
            children: [
              TimelineSummaryRow(
                label: 'Current',
                item: store.currentTimeline,
                color: EventTheme.good,
              ),
              const Divider(height: 28),
              TimelineSummaryRow(
                label: 'Next',
                item: store.nextTimeline,
                color: EventTheme.accent,
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Full Timeline'),
        for (final item in timeline)
          ListCard(
            leading: Text(
              item.time,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            title: item.title,
            subtitle: item.description,
            trailing: StatusChip(
              label: item.status.label,
              color: timelineColor(item.status),
            ),
          ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});

  final EventStore store;

  @override
  Widget build(BuildContext context) {
    return AppScroll(
      children: [
        const AppHeader(eyebrow: 'LOCAL APP SETTINGS', title: 'Settings'),
        SectionCard(
          title: 'Role Selection',
          child: Column(
            children: [
              for (final role in EventRole.values)
                RoleOption(
                  role: role,
                  selected: role == store.role,
                  onTap: () => store.setRole(role),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Demo Data',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local-only MVP. No accounts, backend, cloud sync or guest-facing views.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: EventTheme.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('reset-demo-data'),
                onPressed: store.resetDemoData,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset demo data'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RoleOption extends StatelessWidget {
  const RoleOption({
    super.key,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final EventRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? EventTheme.accent.withValues(alpha: 0.12)
            : EventTheme.surfaceHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? EventTheme.accent : EventTheme.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roleHelp(role),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: EventTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppScroll extends StatelessWidget {
  const AppScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final padding = screenPadding(context);
    final gap = isCompactWidth(context) ? 12.0 : 16.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, 22),
      children: [
        for (final child in children) ...[child, SizedBox(height: gap)],
      ],
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: EventTheme.accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: compact ? 26 : null,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: compact ? 8 : 12),
          Flexible(
            child: Align(alignment: Alignment.topRight, child: trailing),
          ),
        ],
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: EventTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 720
            ? 3
            : constraints.maxWidth < 380
            ? 1
            : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.footer,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const Spacer(),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 18),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: compact ? 22 : null,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: compact ? 4 : 6),
          Text(
            footer,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: EventTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: compact ? 12 : 16),
          child,
        ],
      ),
    );
  }
}

class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.children = const [],
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 10 : 12),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: compact ? 42 : 50, child: leading),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: compact ? 4 : 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: EventTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (children.isNotEmpty) ...[
            SizedBox(height: compact ? 12 : 14),
            ...children,
          ],
        ],
      ),
    );
  }
}

class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, required this.store});

  final EventTask task;
  final EventStore store;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    return ListCard(
      leading: PriorityPill(priority: task.priority),
      title: task.title,
      subtitle:
          '${task.description}\n${task.area.label} · ${task.assignedTo} · due ${task.dueTime}',
      trailing: StatusChip(
        label: task.status.label,
        color: task.status == TaskStatus.done
            ? EventTheme.good
            : EventTheme.accent,
      ),
      children: [
        Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: compact
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: compact ? 0 : 1,
              child: DropdownButtonFormField<TaskStatus>(
                initialValue: task.status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final status in TaskStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (status) {
                  if (status != null) store.updateTaskStatus(task.id, status);
                },
              ),
            ),
            SizedBox(width: compact ? 0 : 10, height: compact ? 10 : 0),
            FilledButton(
              key: Key('mark-done-${task.id}'),
              onPressed: task.status == TaskStatus.done
                  ? null
                  : () => store.updateTaskStatus(task.id, TaskStatus.done),
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );
  }
}

class IssueRow extends StatelessWidget {
  const IssueRow({super.key, required this.issue, required this.store});

  final EventIssue issue;
  final EventStore store;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    return ListCard(
      leading: PriorityPill(priority: issue.priority),
      title: issue.title,
      subtitle:
          '${issue.description}\n${issue.area.label} · reported by ${issue.reportedBy} · assigned ${issue.assignedTo}',
      trailing: StatusChip(
        label: issue.status.label,
        color: issue.status == IssueStatus.resolved
            ? EventTheme.good
            : priorityColor(issue.priority),
      ),
      children: [
        Flex(
          direction: compact ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: compact
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: compact ? 0 : 1,
              child: DropdownButtonFormField<IssueStatus>(
                initialValue: issue.status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final status in IssueStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (status) {
                  if (status != null) store.updateIssueStatus(issue.id, status);
                },
              ),
            ),
            SizedBox(width: compact ? 0 : 10, height: compact ? 10 : 0),
            FilledButton(
              key: Key('resolve-${issue.id}'),
              onPressed: issue.status == IssueStatus.resolved
                  ? null
                  : () =>
                        store.updateIssueStatus(issue.id, IssueStatus.resolved),
              child: const Text('Resolve'),
            ),
          ],
        ),
      ],
    );
  }
}

class TimelineSummaryRow extends StatelessWidget {
  const TimelineSummaryRow({
    super.key,
    required this.label,
    required this.item,
    required this.color,
  });

  final String label;
  final TimelineItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatusChip(label: label, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.time} · ${item.title}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                item.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: EventTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class PriorityPill extends StatelessWidget {
  const PriorityPill({super.key, required this.priority});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    final color = priorityColor(priority);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        priority.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class QuickActionData {
  const QuickActionData({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.actions});

  final List<QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 340 ? 1 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: QuickActionButton(
                  label: action.label,
                  icon: action.icon,
                  onTap: action.onTap,
                ),
              ),
          ],
        );
      },
    );
  }
}

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactWidth(context);
    return Material(
      color: EventTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(compact ? 16 : 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 12 : 14,
          ),
          child: Row(
            children: [
              Icon(icon, color: EventTheme.accent, size: compact ? 20 : 24),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
    required this.onClear,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: selected == null,
          onSelected: (_) => onClear(),
        ),
        for (final value in values)
          ChoiceChip(
            label: Text(labelFor(value)),
            selected: selected == value,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Nothing here',
      child: Text(message, style: const TextStyle(color: EventTheme.textMuted)),
    );
  }
}

Future<void> showRevenueSheet(BuildContext context, EventStore store) async {
  final controller = TextEditingController(text: '50');
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SheetFrame(
      title: 'Add Revenue',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('revenue-amount'),
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount in euro',
              prefixIcon: Icon(Icons.euro),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              store.addRevenue(int.tryParse(controller.text.trim()) ?? 0);
              Navigator.pop(context);
            },
            child: const Text('Add revenue'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showTaskSheet(BuildContext context, EventStore store) async {
  final title = TextEditingController();
  final description = TextEditingController();
  final assignedTo = TextEditingController(text: store.role.label);
  Area area = roleDefaultArea(store.role);
  Priority priority = Priority.normal;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SheetFrame(
        title: 'Create Task',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('task-title'),
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Area>(
                    initialValue: area,
                    decoration: const InputDecoration(labelText: 'Area'),
                    items: [
                      for (final value in Area.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => area = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<Priority>(
                    initialValue: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: [
                      for (final value in Priority.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => priority = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: assignedTo,
              decoration: const InputDecoration(labelText: 'Assigned to'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final taskTitle = title.text.trim();
                if (taskTitle.isEmpty) return;
                store.addTask(
                  EventTask(
                    id: 'task-${DateTime.now().microsecondsSinceEpoch}',
                    title: taskTitle,
                    description: description.text.trim().isEmpty
                        ? 'Created from EventOps.'
                        : description.text.trim(),
                    area: area,
                    assignedTo: assignedTo.text.trim().isEmpty
                        ? store.role.label
                        : assignedTo.text.trim(),
                    priority: priority,
                    status: TaskStatus.open,
                    dueTime: 'Now',
                    createdAt: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Create task'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showIssueSheet(BuildContext context, EventStore store) async {
  final title = TextEditingController();
  final description = TextEditingController();
  Area area = roleDefaultArea(store.role);
  Priority priority = Priority.important;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SheetFrame(
        title: 'Report Problem',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('issue-title'),
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Area>(
                    initialValue: area,
                    decoration: const InputDecoration(labelText: 'Area'),
                    items: [
                      for (final value in Area.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => area = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<Priority>(
                    initialValue: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: [
                      for (final value in Priority.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => priority = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final issueTitle = title.text.trim();
                if (issueTitle.isEmpty) return;
                store.addIssue(
                  EventIssue(
                    id: 'issue-${DateTime.now().microsecondsSinceEpoch}',
                    title: issueTitle,
                    description: description.text.trim().isEmpty
                        ? 'Created from EventOps.'
                        : description.text.trim(),
                    area: area,
                    priority: priority,
                    status: IssueStatus.open,
                    reportedBy: store.role.label,
                    assignedTo: area.label,
                    createdAt: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Create issue'),
            ),
          ],
        ),
      ),
    ),
  );
}

class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

BoxDecoration cardDecoration() => BoxDecoration(
  color: EventTheme.surface.withValues(alpha: 0.92),
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: EventTheme.border),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.24),
      blurRadius: 24,
      offset: const Offset(0, 14),
    ),
  ],
);

Color priorityColor(Priority priority) => switch (priority) {
  Priority.low => EventTheme.textMuted,
  Priority.normal => EventTheme.accent,
  Priority.important => EventTheme.warning,
  Priority.critical => EventTheme.danger,
};

Color timelineColor(TimelineStatus status) => switch (status) {
  TimelineStatus.planned => EventTheme.accent,
  TimelineStatus.running => EventTheme.good,
  TimelineStatus.done => EventTheme.textMuted,
  TimelineStatus.delayed => EventTheme.warning,
  TimelineStatus.cancelled => EventTheme.danger,
};

Area roleDefaultArea(EventRole role) => switch (role) {
  EventRole.entryTeam => Area.entry,
  EventRole.barCashier => Area.bar,
  EventRole.tech => Area.tech,
  EventRole.security => Area.security,
  EventRole.firstAid => Area.firstAid,
  EventRole.runner => Area.runner,
  EventRole.areaLead ||
  EventRole.eventLead ||
  EventRole.helper => Area.eventLead,
};

String roleHelp(EventRole role) => switch (role) {
  EventRole.eventLead => 'Full event overview and all actions.',
  EventRole.areaLead => 'Area-level view across all responsibilities.',
  EventRole.helper => 'Generic helper tasks, setup, cleanup and runner work.',
  EventRole.entryTeam =>
    'Entry queue, guests, wristbands and cash desk signals.',
  EventRole.barCashier => 'Revenue, bar stock and cash desk issues.',
  EventRole.tech => 'Audio, stage and technical problem reports.',
  EventRole.security => 'Supervision and safety-related tasks.',
  EventRole.firstAid => 'First aid responsibilities and assistance reports.',
  EventRole.runner => 'Transport, supply and urgent errand tasks.',
};

String formatCurrency(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

bool isCurrentShift(Shift shift) =>
    shift.startTime == '18:00' || shift.personName == 'Clara';
