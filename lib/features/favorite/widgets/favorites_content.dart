import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../app/data/destinations_service.dart';
import '../../home/widgets/place_card.dart';
import '../services/favorites_service.dart';

class FavoritesContent extends StatefulWidget {
  const FavoritesContent({super.key});

  @override
  State<FavoritesContent> createState() => _FavoritesContentState();
}

class _FavoritesContentState extends State<FavoritesContent> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _favoriteDestinations = [];
  List<Map<String, dynamic>> _filteredDestinations = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Position? _currentPosition;

  // Filter state variables
  Set<String> _selectedCategoryIds = {};
  double? _minRating;
  String _sortBy = 'newest';
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadData() async {
    try {
      // Load favorites and categories in parallel
      await Future.wait([
        _loadFavorites(),
        _loadCategories(),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      // Load real favorites from service
      final favorites = await FavoritesService.instance.getFavorites();
      
      // If no favorites, show some sample data for demo
      List<Map<String, dynamic>> destinations = favorites;
      if (favorites.isEmpty) {
        destinations = await DestinationsService.instance.getPopularDestinations(limit: 6);
        // Add sample favorites for demo purposes
        for (final dest in destinations) {
          await FavoritesService.instance.addToFavorites(dest);
        }
        destinations = await FavoritesService.instance.getFavorites();
      }
      
      if (!mounted) return;
      setState(() {
        _favoriteDestinations = destinations;
        _filteredDestinations = destinations;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DestinationsService.instance.getCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (e) {
      // Handle error silently
    }
  }

  double _calculateDistance(Map<String, dynamic> destination) {
    if (_currentPosition == null) return 0.0;
    
    final lat = (destination['latitude'] ?? destination['lat'])?.toDouble();
    final lng = (destination['longitude'] ?? destination['lng'])?.toDouble();
    
    if (lat == null || lng == null) return 0.0;
    
    try {
      final meters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lng,
      );
      return meters / 1000.0; // Convert to kilometers
    } catch (e) {
      return 0.0;
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredDestinations = _favoriteDestinations.where((dest) {
        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final name = dest['name']?.toString().toLowerCase() ?? '';
          final address = dest['address']?.toString().toLowerCase() ?? '';
          if (!name.contains(_searchQuery.toLowerCase()) && 
              !address.contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }

        // Category filter (multiple selection)
        if (_selectedCategoryIds.isNotEmpty) {
          final destCategoryId = dest['category_id']?.toString();
          if (destCategoryId == null || !_selectedCategoryIds.contains(destCategoryId)) {
            return false;
          }
        }
        
        // Rating filter
        if (_minRating != null) {
          final rating = double.tryParse(dest['rating']?.toString() ?? '0') ?? 0.0;
          if (rating < _minRating!) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      // Apply sorting
      _sortDestinations();
      
      // Update active filters indicator
      _hasActiveFilters = _selectedCategoryIds.isNotEmpty || 
                         _minRating != null || 
                         _sortBy != 'newest';
    });
  }

  void _sortDestinations() {
    switch (_sortBy) {
      case 'newest':
        // Keep original order (newest first)
        break;
      case 'oldest':
        _filteredDestinations = _filteredDestinations.reversed.toList();
        break;
      case 'rating_high':
        _filteredDestinations.sort((a, b) {
          final ratingA = double.tryParse(a['rating']?.toString() ?? '0') ?? 0.0;
          final ratingB = double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'distance':
        if (_currentPosition != null) {
          _filteredDestinations.sort((a, b) {
            final distA = _calculateDistance(a);
            final distB = _calculateDistance(b);
            return distA.compareTo(distB);
          });
        }
        break;
      case 'name_asc':
        _filteredDestinations.sort((a, b) {
          final nameA = a['name']?.toString() ?? '';
          final nameB = b['name']?.toString() ?? '';
          return nameA.compareTo(nameB);
        });
        break;
    }
  }

  void _filterDestinations(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryIds.clear();
      _minRating = null;
      _sortBy = 'newest';
      _hasActiveFilters = false;
    });
    _applyFilters();
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategoryIds.isNotEmpty) count += _selectedCategoryIds.length;
    if (_minRating != null) count++;
    if (_sortBy != 'newest') count++;
    return count;
  }

  String _getSortDisplayName(String sortBy) {
    switch (sortBy) {
      case 'oldest':
        return 'Terlama';
      case 'rating_high':
        return 'Rating ↓';
      case 'distance':
        return 'Terdekat';
      case 'name_asc':
        return 'A-Z';
      default:
        return 'Terbaru';
    }
  }

  String _getCategoryName(String categoryId) {
    try {
      final category = _categories.firstWhere(
        (cat) => cat['id'].toString() == categoryId,
      );
      return category['name'] ?? 'Kategori';
    } catch (e) {
      return 'Kategori';
    }
  }

  Future<void> _removeFavorite(int index) async {
    final removedItem = _filteredDestinations[index];
    
    // Remove from service
    final success = await FavoritesService.instance.removeFromFavorites(removedItem['id']);
    
    if (success) {
      setState(() {
        _favoriteDestinations.removeWhere((item) => item['id'] == removedItem['id']);
        _filteredDestinations.removeAt(index);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dihapus dari favorit'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Urungkan',
            textColor: Colors.white,
            onPressed: () async {
              await FavoritesService.instance.addToFavorites(removedItem);
              _loadFavorites(); // Reload favorites
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredDestinations.isEmpty
                ? _buildEmptyStateWithHeader(textTheme)
                : _buildScrollableContent(textTheme),
      ),
    );
  }

  Widget _buildScrollableContent(TextTheme textTheme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section - Now scrollable
          _buildHeader(textTheme),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: const Color(0xFF6B73FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_filteredDestinations.length} Favorit',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Active Filters Display
          if (_hasActiveFilters) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_searchQuery.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B73FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search, size: 12, color: Color(0xFF6B73FF)),
                          const SizedBox(width: 4),
                          Text(
                            '"$_searchQuery"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B73FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedCategoryIds.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B73FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category, size: 12, color: Color(0xFF6B73FF)),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCategoryIds.length == 1 
                              ? _getCategoryName(_selectedCategoryIds.first)
                              : '${_selectedCategoryIds.length} kategori',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B73FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_minRating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B73FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Color(0xFF6B73FF)),
                          const SizedBox(width: 4),
                          Text(
                            '${_minRating!.toStringAsFixed(1)}+',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B73FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_sortBy != 'newest')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B73FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort, size: 12, color: Color(0xFF6B73FF)),
                          const SizedBox(width: 4),
                          Text(
                            _getSortDisplayName(_sortBy),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B73FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Favorites Grid
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
              itemCount: _filteredDestinations.length,
              itemBuilder: (context, index) {
                final destination = _filteredDestinations[index];
                final rating = double.tryParse(destination['rating']?.toString() ?? '0') ?? 0.0;
                
                return Stack(
                  children: [
                    PlaceCard(
                      title: destination['name'] ?? 'Destinasi',
                      subtitle: destination['address'] ?? 'Alamat tidak tersedia',
                      priceLabel: 'Gratis',
                      distanceLabel: '${(index + 1) * 2} km',
                      rating: rating,
                      imageUrl: destination['image_url'] ?? 'https://picsum.photos/seed/fav$index/600/400',
                    ),
                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeFavorite(index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithHeader(TextTheme textTheme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section - Now scrollable
          _buildHeader(textTheme),
          
          // Empty State Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B73FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 40,
                    color: Color(0xFF6B73FF),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _searchQuery.isEmpty
                      ? 'Belum Ada Favorit'
                      : 'Tidak Ditemukan',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'Mulai jelajahi dan simpan tempat-tempat favorit Anda'
                      : 'Coba kata kunci lain untuk pencarian',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to explore page - you can implement this navigation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B73FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Jelajahi Sekarang',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
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
                      'Favorit Saya',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tempat-tempat yang Anda sukai',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar with Filter Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterDestinations,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cari favorit...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Stack(
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: _showFilterBottomSheet,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Icon(
                            Icons.tune,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    if (_hasActiveFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterHeader(),
                        const SizedBox(height: 20),
                        _buildCategoryFilter(setModalState),
                        _buildRatingFilter(setModalState),
                        _buildSortFilter(setModalState),
                        const SizedBox(height: 20),
                        _buildFilterActions(),
                        const SizedBox(height: 20), // Extra bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Row(
      children: [
        Text(
          'Filter & Urutkan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (_hasActiveFilters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6B73FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_getActiveFilterCount()} filter aktif',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B73FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(StateSetter setModalState) {
    if (_categories.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // "Semua" chip - selected when no categories are selected
            FilterChip(
              label: const Text('Semua'),
              selected: _selectedCategoryIds.isEmpty,
              onSelected: (selected) => setModalState(() {
                if (selected) {
                  _selectedCategoryIds.clear();
                }
              }),
              selectedColor: const Color(0xFF6B73FF).withOpacity(0.2),
              checkmarkColor: const Color(0xFF6B73FF),
              backgroundColor: Colors.grey[100],
              side: BorderSide(
                color: _selectedCategoryIds.isEmpty 
                  ? const Color(0xFF6B73FF) 
                  : Colors.grey.withOpacity(0.3),
                width: _selectedCategoryIds.isEmpty ? 1.5 : 1,
              ),
            ),
            // Category chips
            ..._categories.map((category) {
              final categoryId = category['id'].toString();
              final isSelected = _selectedCategoryIds.contains(categoryId);
              
              return FilterChip(
                label: Text(category['name'] ?? 'Kategori'),
                selected: isSelected,
                onSelected: (selected) => setModalState(() {
                  if (selected) {
                    _selectedCategoryIds.add(categoryId);
                  } else {
                    _selectedCategoryIds.remove(categoryId);
                  }
                }),
                selectedColor: const Color(0xFF6B73FF).withOpacity(0.2),
                checkmarkColor: const Color(0xFF6B73FF),
                backgroundColor: Colors.grey[100],
                side: BorderSide(
                  color: isSelected 
                    ? const Color(0xFF6B73FF) 
                    : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 1.5 : 1,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRatingFilter(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Minimum',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRatingChip('Semua', null, setModalState),
            _buildRatingChip('⭐⭐⭐⭐⭐ 4.5+', 4.5, setModalState),
            _buildRatingChip('⭐⭐⭐⭐ 4.0+', 4.0, setModalState),
            _buildRatingChip('⭐⭐⭐ 3.0+', 3.0, setModalState),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRatingChip(String label, double? rating, StateSetter setModalState) {
    return FilterChip(
      label: Text(label),
      selected: _minRating == rating,
      onSelected: (selected) => setModalState(() {
        _minRating = selected ? rating : null;
      }),
      selectedColor: const Color(0xFF6B73FF).withOpacity(0.2),
      checkmarkColor: const Color(0xFF6B73FF),
    );
  }

  Widget _buildSortFilter(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urutkan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            _buildSortOption('Terbaru Ditambahkan', 'newest', setModalState),
            _buildSortOption('Terlama Ditambahkan', 'oldest', setModalState),
            _buildSortOption('Rating Tertinggi', 'rating_high', setModalState),
            if (_currentPosition != null)
              _buildSortOption('Terdekat', 'distance', setModalState),
            _buildSortOption('Nama A-Z', 'name_asc', setModalState),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOption(String label, String value, StateSetter setModalState) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _sortBy,
      onChanged: (newValue) => setModalState(() {
        _sortBy = newValue ?? 'newest';
      }),
      activeColor: const Color(0xFF6B73FF),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildFilterActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _resetFilters();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6B73FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFF6B73FF)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B73FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Terapkan Filter'),
          ),
        ),
      ],
    );
  }

}
