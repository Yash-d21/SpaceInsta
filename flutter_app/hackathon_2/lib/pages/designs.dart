import 'package:flutter/material.dart';
import 'package:hackathon_2/pages/finalOP.dart';

class DesignGalleryPage extends StatefulWidget {
  const DesignGalleryPage({super.key});

  @override
  State<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends State<DesignGalleryPage> {
  // 1. Add a PageController to track the swipe position
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> designs = [
    {
      'image': 'https://picsum.photos/id/237/800/1200',
      'title': 'The Golden Retriever',
      'details': 'A classic and friendly design approach.',
    },
    {
      'image': 'https://picsum.photos/id/238/800/1200',
      'title': 'Urban Jungle',
      'details': 'Incorporating natural elements into city living.',
    },
    {
      'image': 'https://picsum.photos/id/239/800/1200',
      'title': 'Midnight Sky',
      'details': 'Deep blues and stellar highlights for a calm vibe.',
    },
  ];

  // 2. This function now takes the specific index of the current page
  void _showDetails(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Allows for custom rounding
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle for better UX
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                designs[index]['title']!,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                designs[index]['details']!,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Horizontal PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index; // Update the index as the user swipes
              });
            },
            itemCount: designs.length,
            itemBuilder: (context, index) {
              return Image.network(
                designs[index]['image']!,
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),

          // Control Overlay
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // INFO (Left) - Uses the tracked _currentPage
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 38,
                  ),
                  onPressed: () => _showDetails(_currentPage),
                ),

                // SELECT (Center)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BudgetBreakdownPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 45,
                      vertical: 15,
                    ),
                    // shape: BorderRadius.circular(12),
                    elevation: 8,
                  ),
                  child: const Text(
                    "SELECT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // LIKE (Right)
                IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 38,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
