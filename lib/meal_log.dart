import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

class Meal {
  Meal({required this.type, required this.name, required this.kcal, this.notes = '', this.photo})
      : time = DateTime.now();
  final String type, name, notes;
  final int kcal;
  final Uint8List? photo;
  final DateTime time;
}

class MealLogPage extends StatefulWidget {
  const MealLogPage({super.key, required this.meals, required this.onAdd});
  final List<Meal> meals;
  final void Function(Meal) onAdd;

  @override
  State<MealLogPage> createState() => _MealLogPageState();
}

class _MealLogPageState extends State<MealLogPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _notes = TextEditingController();
  String _type = mealTypes.first;
  Uint8List? _photo;

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes(); // works on mobile and web
    if (mounted) setState(() => _photo = bytes);
  }

  void _chooseSource() => showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () { Navigator.pop(context); _pick(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); },
            ),
          ]),
        ),
      );

  void _submit() {
    if (!_form.currentState!.validate()) return;
    widget.onAdd(Meal(
      type: _type,
      name: _name.text.trim(),
      kcal: int.parse(_kcal.text.trim()),
      notes: _notes.text.trim(),
      photo: _photo,
    ));
    _form.currentState!.reset();
    setState(() { _photo = null; _type = mealTypes.first; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal saved')));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600), // keeps the form readable on tablets/web
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Log a meal', style: t.headlineSmall),
          const SizedBox(height: 16),
          Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, children: [
                for (final m in mealTypes)
                  ChoiceChip(label: Text(m), selected: _type == m, onSelected: (_) => setState(() => _type = m)),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'What did you eat?', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a meal name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kcal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories (kcal)', border: OutlineInputBorder()),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Enter a number';
                  if (n <= 0 || n > 5000) return 'Enter a value between 1 and 5000';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _chooseSource,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueGrey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _photo == null
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_outlined, size: 32),
                          SizedBox(height: 8),
                          Text('Add a photo of your plate'),
                        ])
                      : Image.memory(_photo!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _submit, child: const Text('Save meal'))),
            ]),
          ),
          const SizedBox(height: 28),
          Text("Today's meals", style: t.titleMedium),
          const SizedBox(height: 8),
          if (widget.meals.isEmpty)
            const Text('Nothing logged yet. Save your first meal above.')
          else
            for (final m in widget.meals.reversed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52, height: 52,
                    child: m.photo != null
                        ? Image.memory(m.photo!, fit: BoxFit.cover)
                        : Container(color: Colors.blueGrey.shade50, child: const Icon(Icons.restaurant)),
                  ),
                ),
                title: Text(m.name),
                subtitle: Text('${m.type} at ${TimeOfDay.fromDateTime(m.time).format(context)}'),
                trailing: Text('${m.kcal} kcal', style: t.titleSmall),
              ),
        ]),
      ),
    );
  }
}
