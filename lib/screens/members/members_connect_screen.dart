import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:church_mobile/models/announcement.dart';
import 'package:church_mobile/models/member.dart';
import 'package:church_mobile/models/testimony.dart';
import 'package:church_mobile/providers/members_connect_provider.dart';
import 'package:church_mobile/services/member_service.dart';
import 'package:church_mobile/screens/members/members_directory_screen.dart';
import 'package:church_mobile/widgets/members/member_details_dialog.dart';
import 'package:church_mobile/widgets/members/celebration_card.dart';
import 'package:church_mobile/widgets/members/announcement_card.dart';
import 'package:church_mobile/widgets/members/testimony_card.dart';
import 'package:church_mobile/widgets/members/quick_action_button.dart';

import '../../widgets/bottom_nav_bar.dart';
import '../community/community_login_screen.dart';
import '../../services/community_auth_service.dart';
import 'prayer_testimony_screen.dart';

class MembersConnectScreen extends StatelessWidget {
  const MembersConnectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MembersConnectProvider(),
      child: const _MembersConnectView(),
    );
  }
}

class _MembersConnectView extends StatefulWidget {
  const _MembersConnectView({Key? key}) : super(key: key);

  @override
  State<_MembersConnectView> createState() => _MembersConnectViewState();
}

class _MembersConnectViewState extends State<_MembersConnectView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  // Inline search state
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final MemberService _memberService = MemberService();
  List<Member> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async =>
      Future.delayed(const Duration(seconds: 1));

  // ── Debounced inline search ──────────────────────────────────────────────
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _memberService.searchMembers(q.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  // ── Celebrants ────────────────────────────────────────────────────────────
  Widget _buildCelebrantsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Celebrants",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark)),
            const SizedBox(height: 10),
            Consumer<MembersConnectProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingCelebrants) {
                  return const Center(child: CircularProgressIndicator());
                }
                final celebrants = provider.todaysCelebrants;
                if (celebrants.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.grey.withOpacity(0.18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cake_outlined,
                            size: 26, color: Colors.grey[400]),
                        const SizedBox(width: 10),
                        Text('No celebrants today',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  );
                }
                final now = DateTime.now();
                return Column(
                  children: celebrants.map((m) {
                    final isBday = m.birthDate != null &&
                        m.birthDate!.month == now.month &&
                        m.birthDate!.day == now.day;
                    return CelebrationCard(member: m, isBirthday: isBday);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions — 2x2 grid ──────────────────────────────────────────────
  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorDark)),
          const SizedBox(height: 8),
          GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
            children: [
              QuickActionButton(
                  icon: Icons.group_outlined,
                  label: 'Community Forum',
                  color: Colors.indigo,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CommunityLoginScreen()))),
              QuickActionButton(
                  icon: Icons.people_alt_outlined,
                  label: 'Members Directory',
                  color: Colors.green,
                  onTap: () async {
                    final authService = CommunityAuthService();
                    final currentUser = await authService.getCurrentUser();
                    if (!mounted) return;
                    
                    if (currentUser != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const MembersDirectoryScreen(),
                      ));
                    } else {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CommunityLoginScreen(
                          onLoginSuccess: (user) {
                            Navigator.pushReplacement(context, MaterialPageRoute(
                              builder: (_) => const MembersDirectoryScreen(),
                            ));
                          },
                        ),
                      ));
                    }
                  }),
              QuickActionButton(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Send Prayer/Testimony',
                  color: Colors.deepOrange,
                  onTap: () async {
                    final authService = CommunityAuthService();
                    final currentUser = await authService.getCurrentUser();
                    if (!mounted) return;
                    
                    if (currentUser != null) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => PrayerTestimonyScreen(currentUser: currentUser),
                      );
                    } else {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CommunityLoginScreen(
                          onLoginSuccess: (user) {
                            Navigator.pop(context); // Pop login screen
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => PrayerTestimonyScreen(currentUser: user),
                            );
                          },
                        ),
                      ));
                    }
                  }),
              QuickActionButton(
                  icon: Icons.calendar_month_outlined,
                  label: 'Church Calendar',
                  color: Colors.teal,
                  onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab content ───────────────────────────────────────────────────────────
  Widget _buildAnnouncementsTab() {
    return Consumer<MembersConnectProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingAnnouncements) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = provider.announcements;
        if (list.isEmpty) {
          return const Center(child: Text('No announcements yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => AnnouncementCard(announcement: list[i]),
        );
      },
    );
  }

  Widget _buildTestimoniesTab() {
    return Consumer<MembersConnectProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingTestimonies) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = provider.testimonies;
        if (list.isEmpty) {
          return const Center(child: Text('No testimonies yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => TestimonyCard(testimony: list[i]),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDropdown =
        _searchCtrl.text.trim().isNotEmpty || _isSearching;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _handleRefresh,
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // ── Hero AppBar ───────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 210.0,
                floating: false,
                pinned: true,
                stretch: true,
                elevation: innerBoxIsScrolled ? 4.0 : 0.0,
                backgroundColor: theme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Members Connect',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ])),
                  background: Stack(fit: StackFit.expand, children: [
                    Image.asset('assets/images/members_hero.jpg',
                        fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.primaryColorDark.withOpacity(0.88),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Inline search bar + dropdown ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.22)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(Icons.search,
                                color: theme.primaryColor, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search by name or profession...',
                                  hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (_searchCtrl.text.isNotEmpty)
                              GestureDetector(
                                onTap: _clearSearch,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(Icons.close,
                                      size: 18, color: Colors.grey[500]),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Dropdown results
                      if (showDropdown)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints:
                              const BoxConstraints(maxHeight: 240),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                      child:
                                          CircularProgressIndicator()))
                              : _searchResults.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('No members found.',
                                          textAlign: TextAlign.center))
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: _searchResults.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, i) {
                                        final m = _searchResults[i];
                                        return ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            radius: 18,
                                            backgroundImage:
                                                m.imageUrl != null
                                                    ? NetworkImage(
                                                        m.imageUrl!)
                                                    : null,
                                            child: m.imageUrl == null
                                                ? Text(
                                                    m.name.isNotEmpty
                                                        ? m.name[0]
                                                            .toUpperCase()
                                                        : '?',
                                                  )
                                                : null,
                                          ),
                                          title: Text(m.name,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 13)),
                                          subtitle: m.occupation != null
                                              ? Text(m.occupation!,
                                                  style: const TextStyle(
                                                      fontSize: 12))
                                              : null,
                                          onTap: () {
                                            _clearSearch();
                                            showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  MemberDetailsDialog(
                                                      member: m),
                                            );
                                          },
                                        );
                                      },
                                    ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Celebrants ────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildCelebrantsSection()),

              // ── Quick Actions ─────────────────────────────────────────
              SliverToBoxAdapter(child: _buildQuickActionsSection()),

              // ── Sticky Tab Bar ────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: theme.primaryColor,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Announcements'),
                      Tab(text: 'Testimonies'),
                    ],
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAnnouncementsTab(),
              _buildTestimoniesTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar, {required this.backgroundColor});
  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: backgroundColor, child: _tabBar);

  @override
  bool shouldRebuild(_SliverTabBarDelegate old) => false;
}
