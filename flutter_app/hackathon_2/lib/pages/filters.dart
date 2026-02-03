import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hackathon_2/pages/designs.dart';

class SpecificationsPage extends StatefulWidget {
  final String imagePath;

  const SpecificationsPage({super.key, required this.imagePath});

  @override
  State<SpecificationsPage> createState() => _SpecificationsPageState();
}

class _SpecificationsPageState extends State<SpecificationsPage> {
  final supabase = Supabase.instance.client;

  // 1. Define Controllers
  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _variantsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  RangeValues _currentRange = const RangeValues(10000, 100000);
  bool _isSaving = false;
  String? _finalImageUrl;

  @override
  void dispose() {
    // Clean up controllers
    _styleController.dispose();
    _variantsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // 2. Database Insertion Logic
  Future<void> _saveToDatabase() async {
    setState(() => _isSaving = true);

    try {
      await supabase.from('design_requests').insert({
        'style': _styleController.text,
        'min_budget': _currentRange.start.round(),
        'max_budget': _currentRange.end.round(),
        'variants': int.tryParse(_variantsController.text) ?? 1,
        'notes': _notesController.text,
        'image_url': _finalImageUrl ?? widget.imagePath,
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Design specs saved!")));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DesignGalleryPage()),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String> _getLatestImageUrl() async {
    try {
      final List<FileObject> objects = await supabase.storage
          .from('designs')
          .list(
            path: 'user_designs',
            searchOptions: const SearchOptions(
              sortBy: SortBy(column: 'created_at', order: 'desc'),
              limit: 1,
            ),
          );

      if (objects.isNotEmpty) {
        final String path = 'user_designs/${objects.first.name}';
        _finalImageUrl = supabase.storage.from('designs').getPublicUrl(path);
        return _finalImageUrl!;
      }
    } catch (e) {
      debugPrint("Error fetching latest image: $e");
    }
    return widget.imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customize Design")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Choose your specifications",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Style"),
                  _buildTextField(_styleController, "Describe what you want"),

                  const SizedBox(height: 20),

                  _buildLabel(
                    "Budget Range: ₹${_currentRange.start.round()} - ₹${_currentRange.end.round()}",
                  ),
                  RangeSlider(
                    values: _currentRange,
                    min: 0,
                    max: 2000000,
                    divisions: 400,
                    labels: RangeLabels(
                      "₹${_currentRange.start.round()}",
                      "₹${_currentRange.end.round()}",
                    ),
                    activeColor: Colors.blueAccent,
                    onChanged:
                        (values) => setState(() => _currentRange = values),
                  ),

                  const SizedBox(height: 20),
                  _buildLabel("Variants"),
                  _buildTextField(
                    _variantsController,
                    "How many types?",
                    isNumber: true,
                  ),

                  const SizedBox(height: 20),
                  _buildLabel("Notes"),
                  _buildTextField(
                    _notesController,
                    "Extra details...",
                    maxLines: 3,
                  ),

                  const SizedBox(height: 30),

                  _buildOkButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return FutureBuilder<String>(
      future:
          widget.imagePath.startsWith('http')
              ? Future.value(widget.imagePath)
              : _getLatestImageUrl(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final displayUrl = snapshot.data ?? widget.imagePath;
        return Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            image: DecorationImage(
              image:
                  displayUrl.startsWith('http')
                      ? NetworkImage(displayUrl)
                      : FileImage(File(displayUrl)) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller, // Linked Controller
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildOkButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveToDatabase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
        ),
        child:
            _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  "OK",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
      ),
    );
  }
}
