import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../favorite/services/favorites_service.dart';

class DestinationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
  });

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen>
    with TickerProviderStateMixin {
  bool _isScrolled = false;
  bool _isFavorite = false;
  String _distanceText = '-';
  late AnimationController _animationController;
  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _elevationAnimation;
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
    _checkFavoriteStatus();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Background color animation
    _backgroundAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.white,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Elevation animation
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _addMarker();
  }

  void _addMarker() {
    final lat = (widget.destination['latitude'] ?? widget.destination['lat'])?.toDouble();
    final lng = (widget.destination['longitude'] ?? widget.destination['lng'])?.toDouble();
    
    if (lat != null && lng != null) {
      final marker = Marker(
        markerId: MarkerId(widget.destination['id']?.toString() ?? 'destination'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: widget.destination['name'] ?? 'Destinasi',
          snippet: widget.destination['address'] ?? 'Alamat tidak tersedia',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      
      setState(() {
        _markers = {marker};
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      if (!mounted) return;
      
      _calculateDistance(currentPosition);
    } catch (e) {
      // Handle error silently
    }
  }

  void _calculateDistance(Position currentPosition) {
    try {
      final lat = (widget.destination['latitude'] ?? widget.destination['lat'])?.toDouble();
      final lng = (widget.destination['longitude'] ?? widget.destination['lng'])?.toDouble();
      
      if (lat == null || lng == null) return;
      
      final meters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        lng,
      );
      
      final km = meters / 1000.0;
      final showOneDecimal = km < 10;
      
      setState(() {
        _distanceText = '${km.toStringAsFixed(showOneDecimal ? 1 : 0)} km';
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final destinationId = widget.destination['id'];
      if (!mounted || destinationId == null) return;
      
      final isFav = await FavoritesService.instance.isFavorite(destinationId);
      
      if (!mounted) return;
      setState(() {
        _isFavorite = isFav;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      bool success;
      if (_isFavorite) {
        success = await FavoritesService.instance.removeFromFavorites(widget.destination['id']);
      } else {
        success = await FavoritesService.instance.addToFavorites(widget.destination);
      }
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit'),
            backgroundColor: _isFavorite ? Colors.green : Colors.grey[600],
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengubah status favorit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah favorit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGoogleMap() {
    final lat = (widget.destination['latitude'] ?? widget.destination['lat'])?.toDouble();
    final lng = (widget.destination['longitude'] ?? widget.destination['lng'])?.toDouble();
    
    if (lat == null || lng == null) {
      // Fallback to placeholder if no coordinates
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text(
                'Lokasi tidak tersedia',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: LatLng(lat, lng),
        zoom: 15.0,
      ),
      markers: _markers,
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      compassEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.destination['name'] ?? 'Destinasi';
    final address = widget.destination['address'] ?? 'Alamat tidak tersedia';
    final imageUrl = widget.destination['image_url'] ?? 'https://picsum.photos/800/600';
    final rating = double.tryParse(widget.destination['rating']?.toString() ?? '0') ?? 0.0;
    final description = widget.destination['description'] ?? 'Deskripsi tidak tersedia untuk destinasi ini. Ini adalah tempat yang menarik untuk dikunjungi dan memberikan pengalaman yang tak terlupakan bagi para wisatawan. Tempat ini menawarkan berbagai aktivitas menarik dan fasilitas yang memadai untuk kenyamanan pengunjung.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo is ScrollUpdateNotification) {
              final isScrolled = scrollInfo.metrics.pixels > 0;
              if (isScrolled != _isScrolled) {
                setState(() => _isScrolled = isScrolled);
                
                // Animate based on scroll state
                if (isScrolled) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              }
              return false;
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SliverAppBar(
                    backgroundColor: _backgroundAnimation.value,
                    surfaceTintColor: Colors.white,
                    elevation: _elevationAnimation.value,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    pinned: true,
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                    title: Text(
                      'Detail Destinasi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF6B73FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: _toggleFavorite,
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                    centerTitle: true,
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image
                    SizedBox(
                      width: double.infinity,
                      height: 300,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey, size: 64),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  address,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Rating Row
                          Row(
                            children: [
                              // Google Rating
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD), // Light blue highlight
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/logo-google.png',
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star, color: Color(0xFF1976D2), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${(rating * 1000).toInt()})',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // App Rating
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1), // Light yellow/amber highlight
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFF57C00), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(1)',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Distance
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E8), // Light green highlight
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.directions_walk, color: Color(0xFF4CAF50), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      _distanceText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Overview Section
                          const Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Location Section
                          const Text(
                            'Lokasi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Google Maps
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: double.infinity,
                              height: 200,
                              child: _buildGoogleMap(),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 