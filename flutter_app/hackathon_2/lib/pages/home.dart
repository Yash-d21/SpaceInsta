import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hackathon_2/pages/filters.dart';
import 'package:hackathon_2/pages/login.dart';
import 'package:hackathon_2/pages/settings.dart';
import 'package:hackathon_2/pages/result_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  final supabase = Supabase.instance.client;
  bool _isUploading = false;
  String _loadingMessage = "Uploading...";

  final List<String> popularDesigns = [
    'https://picsum.photos/id/10/400/300',
    'https://picsum.photos/id/20/400/300',
    'https://picsum.photos/id/30/400/300',
    'https://picsum.photos/id/40/400/300',
    'https://picsum.photos/id/50/400/300',
    'https://picsum.photos/id/60/400/300',
  ];

  Future<void> _openCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Lower quality for faster processing
      );

      if (pickedFile != null) {
        await _analyzeWithBackend(pickedFile);
      }
    } catch (e) {
      _showSnackBar("Camera Error: $e", Colors.red);
    }
  }

  Future<void> _analyzeWithBackend(XFile image) async {
    setState(() {
      _isUploading = true;
      _loadingMessage = "AI analyzing room details...";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('api_base_url') ?? 'https://insta-space-seven.vercel.app';
      final customKey = prefs.getString('gemini_api_key') ?? '';

      final dio = dio_pkg.Dio();
      final formData = dio_pkg.FormData.fromMap({
        'file': await dio_pkg.MultipartFile.fromFile(image.path, filename: 'upload.jpg'),
      });

      final response = await dio.post(
        '$baseUrl/api/v1/full-analysis',
        data: formData,
        options: dio_pkg.Options(
          headers: {
            if (customKey.isNotEmpty) 'X-Gemini-API-Key': customKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _showSnackBar("Analysis complete!", Colors.green);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisResultPage(data: response.data),
            ),
          );
        }
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Error: $e");
      String errorMessage = "Failed to analyze image.";
      if (e.toString().contains("429")) {
        errorMessage = "Rate limit reached. Please add your own API key in Settings.";
      }
      _showSnackBar(errorMessage, Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("InstaSpace AI"), 
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const SettingsPage())
            ),
          )
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildCarousel(),
              const Spacer(),
              _buildCameraButton(),
              const SizedBox(height: 20),
            ],
          ),
          if (_isUploading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(_loadingMessage, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- UI Components ---
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Latest Trends",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: popularDesigns.length,
        controller: PageController(viewportFraction: 0.85),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(popularDesigns[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraButton() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: InkWell(
        onTap: _isUploading ? null : _openCamera,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent, width: 2),
          ),
          child: Column(
            children: [
              Icon(
                Icons.camera_alt_rounded,
                size: 60,
                color: _isUploading ? Colors.grey : Colors.blueAccent,
              ),
              const SizedBox(height: 15),
              const Text(
                "Scan Your Room",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const Text(
                "Get instant AI pricing & designs",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.3,
            color: Colors.blueAccent,
            child: const SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.blueAccent)),
                  SizedBox(height: 10),
                  Text("John Doe", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            text: 'API Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Logout',
            color: Colors.redAccent,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String text, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blueAccent),
      title: Text(text, style: TextStyle(fontSize: 16, color: color)),
      onTap: onTap,
    );
  }
}
