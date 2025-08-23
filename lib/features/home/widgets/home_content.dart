import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../app/data/destinations_service.dart';
import '../../explore/screens/destinations_explore_screen.dart';
import 'place_card.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _fullName;
  bool _loadingName = true;
  List<Map<String, dynamic>> _popularDestinations = [];
  bool _loadingDestinations = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initLocation().whenComplete(_loadPopularDestinations);
  }


  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
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

  Future<void> _loadPopularDestinations() async {
    try {
      final destinations = await DestinationsService.instance.getPopularDestinations(limit: 4);
      if (!mounted) return;
      setState(() {
        _popularDestinations = destinations;
        _loadingDestinations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDestinations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B73FF), Color(0xFF9B59B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${_loadingName ? 'Pengguna' : (_fullName ?? 'Azerus Ezhar')}',
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Jelajahi Keindahan Malang hari ini',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wb_sunny_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '28°C',
                                      style: textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Malang',
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Cerah berawan',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Jawa Timur',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Destinasi Populer Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF6B73FF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Destinasi Populer',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DestinationsExploreScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Semua',
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B73FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: _loadingDestinations
                    ? const Center(child: CircularProgressIndicator())
                    : _popularDestinations.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada destinasi populer',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: _popularDestinations.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final destination = _popularDestinations[index];
                              final rating = double.tryParse(destination['rating']?.toString() ?? '0') ?? 0.0;
                              final distanceText = _formatDistanceFor(destination);
                              
                              return PlaceCard(
                                title: destination['name'] ?? 'Destinasi',
                                subtitle: destination['address'] ?? 'Alamat tidak tersedia',
                                priceLabel: 'Gratis',
                                distanceLabel: distanceText,
                                rating: rating,
                                imageUrl: destination['image_url'] ?? 'https://picsum.photos/600/400',
                              );
                            },
                          ),
              ),

              const SizedBox(height: 32),

              // Rekomendasi Untukmu Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.thumb_up,
                      color: Color(0xFF6B73FF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rekomendasi Untukmu',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final recommendations = [
                      {
                        'title': 'Wisata Agro Petik Jeruk',
                        'subtitle': 'Kota Batu, Jawa Timur',
                        'rating': 4.4,
                        'image': 'https://picsum.photos/seed/rec$index/600/400',
                      },
                      {
                        'title': 'Brawijaya Edupark',
                        'subtitle': 'Kota Malang, Jawa Timur',
                        'rating': 4.2,
                        'image': 'https://picsum.photos/seed/rec${index + 1}/600/400',
                      },
                      {
                        'title': 'Museum Angkut',
                        'subtitle': 'Kota Batu, Jawa Timur',
                        'rating': 4.6,
                        'image': 'https://picsum.photos/seed/rec${index + 2}/600/400',
                      },
                      {
                        'title': 'Jatim Park 2',
                        'subtitle': 'Kota Batu, Jawa Timur',
                        'rating': 4.5,
                        'image': 'https://picsum.photos/seed/rec${index + 3}/600/400',
                      },
                    ];
                    final rec = recommendations[index];
                    return PlaceCard(
                      title: rec['title'] as String,
                      subtitle: rec['subtitle'] as String,
                      priceLabel: 'Mulai Rp 25.000',
                      distanceLabel: '${(index + 2) * 2} km',
                      rating: rec['rating'] as double,
                      imageUrl: rec['image'] as String,
                    );
                  },
                ),
              ),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }
}
