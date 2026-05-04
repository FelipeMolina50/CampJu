import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../services/auth_provider.dart';

// Modelo temporal para la vista (imita la interfaz solicitada)
class ViewCourse {
  final int id;
  final String title;
  final String description;
  final String image;
  final String duration;
  final int lessons;
  final int progress;
  final String status; // 'in-progress', 'completed', 'not-started'

  ViewCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.duration,
    required this.lessons,
    required this.progress,
    required this.status,
  });
}

class CursosScreen extends StatefulWidget {
  const CursosScreen({super.key});

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  String _activeFilter = 'all';

  final List<ViewCourse> _courses = [
    ViewCourse(
      id: 1,
      title: 'Fundamentos de Liderazgo',
      description: 'Aprende los principios básicos del liderazgo efectivo',
      image: 'https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&q=80&w=400',
      duration: '4 semanas',
      lessons: 12,
      progress: 75,
      status: 'in-progress',
    ),
    ViewCourse(
      id: 2,
      title: 'Primeros Auxilios Básicos',
      description: 'Conocimientos esenciales para situaciones de emergencia',
      image: 'https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?auto=format&fit=crop&q=80&w=400',
      duration: '3 semanas',
      lessons: 10,
      progress: 100,
      status: 'completed',
    ),
    ViewCourse(
      id: 3,
      title: 'Trabajo en Equipo',
      description: 'Desarrolla habilidades de colaboración efectiva',
      image: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&q=80&w=400',
      duration: '2 semanas',
      lessons: 8,
      progress: 0,
      status: 'not-started',
    ),
    ViewCourse(
      id: 4,
      title: 'Supervivencia en Naturaleza',
      description: 'Técnicas básicas para acampar de forma segura',
      image: 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?auto=format&fit=crop&q=80&w=400',
      duration: '6 semanas',
      lessons: 15,
      progress: 0,
      status: 'not-started',
    ),
  ];

  String _getButtonText(ViewCourse course) {
    if (course.status == 'completed') return 'Revisar Curso';
    if (course.status == 'in-progress') return 'Continuar Curso';
    return 'Comenzar Curso';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _courses.where((c) {
      if (_activeFilter == 'all') return true;
      return c.status == _activeFilter;
    }).toList();

    final stats = {
      'total': _courses.length,
      'inProgress': _courses.where((c) => c.status == 'in-progress').length,
      'completed': _courses.where((c) => c.status == 'completed').length,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatsCards(stats),
                _buildFilterTabs(),
                _buildCoursesList(filteredCourses),
                const SizedBox(height: 80), // Padding inferior
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CustomSliverAppBarDelegate(
        minHeight: 120,
        maxHeight: 180,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.coursePrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 4),
                blurRadius: 10,
              )
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (Navigator.canPop(context))
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chevron_left, color: Colors.white, size: 24),
                              SizedBox(width: 4),
                              Text('Volver',
                                  style: TextStyle(color: Colors.white, fontSize: 15)),
                            ],
                          ),
                        ),
                      const Spacer(),
                      const Text(
                        'Cursos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Desarrolla tus habilidades',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => _handleLogout(context),
                    tooltip: 'Cerrar Sesión',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(Map<String, int> stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Row(
        children: [
          _buildStatCard(Icons.menu_book_outlined, stats['total']!, 'Total'),
          const SizedBox(width: 12),
          _buildStatCard(Icons.play_circle_outline, stats['inProgress']!, 'En Curso'),
          const SizedBox(width: 12),
          _buildStatCard(Icons.check_circle_outline, stats['completed']!, 'Completados'),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, int value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 2),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF374151), size: 24),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6A7282)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildTabButton('Todos', 'all'),
          const SizedBox(width: 8),
          _buildTabButton('En Curso', 'in-progress'),
          const SizedBox(width: 8),
          _buildTabButton('Completados', 'completed'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, String filter) {
    final isActive = _activeFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = filter),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isActive ? AppColors.coursePrimary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? AppColors.coursePrimary : const Color(0xFFE5E7EB),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList(List<ViewCourse> courses) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: courses.map((course) {
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Header
                SizedBox(
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        course.image,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Text(
                          course.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (course.status == 'completed')
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Completado',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.description,
                        style: const TextStyle(color: Color(0xFF4A5565), fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF6A7282), size: 16),
                          const SizedBox(width: 6),
                          Text(course.duration, style: const TextStyle(color: Color(0xFF6A7282), fontSize: 14)),
                          const SizedBox(width: 16),
                          const Icon(Icons.menu_book, color: Color(0xFF6A7282), size: 16),
                          const SizedBox(width: 6),
                          Text('${course.lessons} lecciones', style: const TextStyle(color: Color(0xFF6A7282), fontSize: 14)),
                        ],
                      ),
                      if (course.status != 'not-started') ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progreso', style: TextStyle(color: Color(0xFF6A7282), fontSize: 12)),
                            Text('${course.progress}%', style: const TextStyle(color: Color(0xFF6A7282), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: course.progress / 100,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.coursePrimary),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.coursePrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getButtonText(course),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CustomSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _CustomSliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_CustomSliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
