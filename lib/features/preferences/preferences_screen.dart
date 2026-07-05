import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _cuisines = <String>{};
  final _dietary = <String>{};
  final _prices = <String>{};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final prefs = await context.read<UserService>().getPreferences(uid);
    setState(() {
      _cuisines.addAll(prefs.cuisines);
      _dietary.addAll(prefs.dietary);
      _prices.addAll(prefs.prices);
      _loading = false;
    });
  }

  Future<void> _save() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    await context.read<UserService>().savePreferences(
          uid,
          UserPreferences(
            cuisines: _cuisines.toList(),
            dietary: _dietary.toList(),
            prices: _prices.toList(),
          ),
        );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Preferences saved.')));
    }
  }

  Widget _chipGroup(String title, Map<String, String> options, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.entries.map((e) {
            final isSelected = selected.contains(e.value);
            return FilterChip(
              label: Text(e.key),
              selected: isSelected,
              onSelected: (v) => setState(() {
                v ? selected.add(e.value) : selected.remove(e.value);
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Preferences')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'These defaults are applied to searches and suggestions.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _chipGroup('Cuisines', UserPreferences.cuisineOptions, _cuisines),
                _chipGroup('Dietary', UserPreferences.dietaryOptions, _dietary),
                Text('Price', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var tier = 1; tier <= 4; tier++)
                      FilterChip(
                        label: Text('\$' * tier),
                        selected: _prices.contains('$tier'),
                        onSelected: (v) => setState(() {
                          v ? _prices.add('$tier') : _prices.remove('$tier');
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save preferences'),
                ),
              ],
            ),
    );
  }
}
