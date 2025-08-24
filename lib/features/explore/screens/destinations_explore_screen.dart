import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../app/data/destinations_service.dart';
import '../widgets/destination_detail_card.dart';
import 'destination_detail_screen.dart';

class DestinationsExploreScreen extends StatefulWidget {
  const DestinationsExploreScreen({super.key});

  @override
  State<DestinationsExploreScreen> createState() => _DestinationsExploreScreenState();
}

class _DestinationsExploreScreenState extends State<DestinationsExploreScreen> {
  List<Map<String, dynamic>> _destinations = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String _searchQuery = '';
  int? _selectedCategoryId;
  final _searchController = TextEditingController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initLocation().whenComplete(_loadData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() => _currentPosition = pos);
    } catch (e) {
      // Silently handle location errors
    }
  }

  String _formatDistanceFor(Map<String, dynamic> dest) {
    try {
      if (_currentPosition == null) return '-';
      final lat = (dest['latitude'] ?? dest['lat'])?.toDouble();
      final lng = (dest['longitude'] ?? dest['lng'])?.toDouble();
      if (lat == null || lng == null) return '-';
      final meters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lng,
      );
      final km = meters / 1000.0;
      final showOneDecimal = km < 10;
      return '${km.toStringAsFixed(showOneDecimal ? 1 : 0)} km';
    } catch (_) {
      return '-';
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final futures = await Future.wait([
        DestinationsService.instance.getAllDestinations(),
        DestinationsService.instance.getCategories(),
      ]);
      
      if (!mounted) return;
      setState(() {
        _destinations = futures[0];
        _categories = futures[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  Future<void> _searchDestinations() async {
    setState(() => _loading = true);
    try {
      final results = await DestinationsService.instance.getAllDestinations(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _selectedCategoryId,
      );
      
      if (!mounted) return;
      setState(() {
        _destinations = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencari: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search Bar and Filter
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari destinasi wisata...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                        _searchDestinations();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            onSubmitted: (_) => _searchDestinations(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B73FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            _showFilterBottomSheet();
                          },
                          icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B73FF)))
                  : _destinations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada destinasi ditemukan',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 100),
                          itemCount: _destinations.length,
                          itemBuilder: (context, index) {
                            final destination = _destinations[index];
                            final rating = double.tryParse(destination['rating']?.toString() ?? '0') ?? 0.0;
                            final categoryName = destination['categories']?['name'] ?? 'Destinasi';
                            final distanceText = _formatDistanceFor(destination);
                            
                            return DestinationDetailCard(
                              name: destination['name'] ?? 'Destinasi',
                              address: destination['address'] ?? 'Alamat tidak tersedia',
                              imageUrl: destination['image_url'] ?? 'https://picsum.photos/600/400',
                              rating: rating,
                              distance: distanceText,
                              category: categoryName,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DestinationDetailScreen(
                                      destination: destination,
                                    ),
                                  ),
                                );
                              },
                              onFavorite: () {
                                // TODO: Toggle favorite
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Filter Kategori',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: _selectedCategoryId == null,
                  onSelected: (selected) {
                    setState(() => _selectedCategoryId = null);
                    _searchDestinations();
                    Navigator.pop(context);
                  },
                  selectedColor: const Color(0xFF6B73FF).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF6B73FF),
                ),
                ..._categories.map((category) => FilterChip(
                  label: Text(category['name']),
                  selected: _selectedCategoryId == category['id'],
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategoryId = selected ? category['id'] : null;
                    });
                    _searchDestinations();
                    Navigator.pop(context);
                  },
                  selectedColor: const Color(0xFF6B73FF).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF6B73FF),
                )),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
