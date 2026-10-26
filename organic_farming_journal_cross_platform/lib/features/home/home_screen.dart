import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app.dart';
import '../../core/database.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.accountId});
  final int accountId;
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;
  Future<Map<String, dynamic>> _load() async {
    return ref.read(databaseProvider).dashboardData(widget.accountId);
  }

  Future<void> _addEntry() async {
    final activity = TextEditingController(), notes = TextEditingController();
    String selected = 'Irrigation';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('New journal entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Activity'),
                  items:
                      const [
                            'Sowing',
                            'Transplanting',
                            'Irrigation',
                            'Weeding',
                            'Composting',
                            'Mulching',
                            'Pest or disease control',
                            'Pruning',
                            'Harvesting',
                            'Soil testing',
                            'Other',
                          ]
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: (v) => setDialog(() => selected = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: activity,
                  decoration: const InputDecoration(
                    labelText: 'Crop or activity name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      await ref
          .read(databaseProvider)
          .addJournalEntry(
            accountId: widget.accountId,
            activity: selected,
            notes: [
              activity.text.trim(),
              notes.text.trim(),
            ].where((e) => e.isNotEmpty).join(' — '),
          );
      if (mounted) setState(() {});
    }
    activity.dispose();
    notes.dispose();
  }

  Future<void> _addCrop() async {
    final name = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add crop'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Crop name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true && name.text.trim().isNotEmpty) {
      await ref
          .read(databaseProvider)
          .addCrop(accountId: widget.accountId, name: name.text.trim());
      if (mounted) setState(() {});
    }
    name.dispose();
  }

  Future<void> _addTask() async {
    final title = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add task'),
        content: TextField(
          controller: title,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Task'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true && title.text.trim().isNotEmpty) {
      await ref
          .read(databaseProvider)
          .addTask(accountId: widget.accountId, title: title.text.trim());
      if (mounted) setState(() {});
    }
    title.dispose();
  }

  Future<void> _addPlot() async {
    final name = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add plot'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Plot name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true && name.text.trim().isNotEmpty) {
      await ref
          .read(databaseProvider)
          .addPlot(accountId: widget.accountId, name: name.text.trim());
      if (mounted) setState(() {});
    }
    name.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    key: ValueKey(_tab),
    future: _load(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load farm records: ${snapshot.error}'),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final data = snapshot.data!,
          account = data['account'] as Map<String, dynamic>;
      final pages = [
        _dashboard(data, account),
        _listPage(
          'Journal',
          (data['entries'] as List)
              .map<Widget>((e) => _entryTile(e as Map<String, dynamic>))
              .toList(),
          'Add your first journal entry to keep a daily record.',
        ),
        _listPage(
          'Crops',
          (data['crops'] as List)
              .map<Widget>(
                (e) => ListTile(
                  leading: const Icon(Icons.grass),
                  title: Text(e['name'] as String),
                  subtitle: Text(e['status'] as String),
                ),
              )
              .toList(),
          'Add crops to track what is growing on your farm.',
        ),
        _listPage(
          'Plots',
          (data['plots'] as List)
              .map<Widget>(
                (e) => ListTile(
                  leading: const Icon(Icons.landscape_outlined),
                  title: Text(e['name'] as String),
                  subtitle: e['area'] == null
                      ? null
                      : Text('${e['area']} acres'),
                ),
              )
              .toList(),
          'Add a plot to organize crops and farm activities.',
        ),
        _listPage(
          'Tasks',
          (data['tasks'] as List)
              .map<Widget>(
                (e) => CheckboxListTile(
                  value: false,
                  title: Text(e['title'] as String),
                  onChanged: (v) async {
                    await ref
                        .read(databaseProvider)
                        .completeTask(widget.accountId, e['id'] as int);
                    if (mounted) setState(() {});
                  },
                ),
              )
              .toList(),
          'No open tasks. Use the + button to add one.',
        ),
      ];
      final actions = [_addEntry, _addEntry, _addCrop, _addPlot, _addTask];
      return Scaffold(
        appBar: AppBar(
          title: Text(['Home', 'Journal', 'Crops', 'Plots', 'Tasks'][_tab]),
          actions: [
            IconButton(
              tooltip: 'Log out',
              onPressed: () => ref.read(sessionProvider.notifier).state = null,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await _load();
          },
          child: pages[_tab],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: actions[_tab],
          icon: const Icon(Icons.add),
          label: Text(['Quick add', 'Entry', 'Crop', 'Plot', 'Task'][_tab]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (v) => setState(() => _tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Journal',
            ),
            NavigationDestination(icon: Icon(Icons.grass), label: 'Crops'),
            NavigationDestination(
              icon: Icon(Icons.landscape_outlined),
              label: 'Plots',
            ),
            NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          ],
        ),
      );
    },
  );

  Widget _dashboard(
    Map<String, dynamic> data,
    Map<String, dynamic> account,
  ) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Hello, ${account['name']}',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(DateFormat.yMMMMEEEEd().format(DateTime.now())),
      const SizedBox(height: 20),
      _farmCard(data['farm'] as Map<String, dynamic>?),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _metric(
              'Active crops',
              '${(data['crops'] as List).length}',
              Icons.grass,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metric(
              'Plots',
              '${(data['plots'] as List).length}',
              Icons.landscape_outlined,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _sectionTitle('Today’s tasks'),
      if ((data['tasks'] as List).isEmpty)
        const _EmptyCard(
          text:
              'No open tasks. Add a reminder when you plan your next activity.',
        )
      else
        ...(data['tasks'] as List)
            .take(4)
            .map(
              (e) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: false,
                title: Text(e['title'] as String),
                onChanged: (v) async {
                  await ref
                      .read(databaseProvider)
                      .completeTask(widget.accountId, e['id'] as int);
                  if (mounted) setState(() {});
                },
              ),
            ),
      const SizedBox(height: 12),
      _sectionTitle('Recent journal'),
      if ((data['entries'] as List).isEmpty)
        const _EmptyCard(
          text:
              'Your farm story starts here. Record an activity, observation, or harvest.',
        )
      else
        ...(data['entries'] as List)
            .take(4)
            .map((e) => _entryTile(e as Map<String, dynamic>)),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => _editFarm(data['farm'] as Map<String, dynamic>?),
        icon: const Icon(Icons.agriculture),
        label: Text(
          (data['farm'] as Map<String, dynamic>?)?['name'] == ''
              ? 'Set up farm profile'
              : 'Edit farm profile',
        ),
      ),
    ],
  );

  Widget _farmCard(Map<String, dynamic>? farm) => Card(
    color: const Color(0xFFE7F0E1),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.agriculture, color: Color(0xFF386641)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm?['name'] as String? ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(farm?['location'] as String? ?? 'Add your farm details'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _metric(String label, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF386641)),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      ),
    ),
  );
  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
  Widget _entryTile(Map<String, dynamic> e) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE7F0E1),
        child: const Icon(Icons.eco, color: Color(0xFF386641)),
      ),
      title: Text(e['activity'] as String),
      subtitle: Text(
        '${DateFormat.yMMMd().add_jm().format(DateTime.parse(e['occurred_at'] as String))}\n${e['notes']}',
      ),
      isThreeLine: true,
    ),
  );
  Widget _listPage(String title, List<Widget> children, String empty) =>
      ListView(
        padding: const EdgeInsets.all(16),
        children: children.isEmpty ? [_EmptyCard(text: empty)] : children,
      );

  Future<void> _editFarm(Map<String, dynamic>? farm) async {
    final db = ref.read(databaseProvider);
    final name = TextEditingController(text: farm?['name'] as String? ?? ''),
        location = TextEditingController(
          text: farm?['location'] as String? ?? '',
        ),
        area = TextEditingController(text: farm?['area']?.toString() ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farm profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Farm name'),
              ),
              TextField(
                controller: location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: area,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Farm area (acres)',
                ),
              ),
              const SizedBox(height: 8),
              const Text('Records are stored locally on this device.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      await db.updateFarm(
        accountId: widget.accountId,
        name: name.text.trim(),
        location: location.text.trim(),
        area: double.tryParse(area.text),
      );
      if (mounted) setState(() {});
    }
    name.dispose();
    location.dispose();
    area.dispose();
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.spa_outlined, color: Color(0xFF386641)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}
