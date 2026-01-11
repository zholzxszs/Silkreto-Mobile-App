import 'package:flutter/material.dart';

class HomeSection extends StatefulWidget {
  const HomeSection({super.key});

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  final ScrollController _scrollController = ScrollController();
  bool _navVisible = true;
  int _selectedIndex = 0;
  double _previousOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    // small threshold to avoid flicker
    const threshold = 6.0;
    if (offset - _previousOffset > threshold && _navVisible) {
      setState(() => _navVisible = false);
    } else if (_previousOffset - offset > threshold && !_navVisible) {
      setState(() => _navVisible = true);
    }
    _previousOffset = offset;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    // Navigation for items
    if (index == 1) {
      // Scan
      Navigator.of(context).pushNamed('/scan');
    } else if (index == 2) {
      // Upload
      Navigator.of(context).pushNamed('/upload');
    } else if (index == 3) {
      // History
      Navigator.of(context).pushNamed('/history');
    } else if (index == 0) {
      // Home: stay here or pop until home
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          width: 380,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
          child: Stack(
            children: [
              // Top Header Bar
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 380,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.50, 0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [Color(0xFF63A361), Color(0xFF253D24)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x3F000000),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              // Profile Avatar
              Positioned(
                left: 16,
                top: 9,
                child: Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: NetworkImage("https://placehold.co/37x37"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // SILKRETO Title
              Positioned(
                left: 60,
                top: 16,
                child: SizedBox(
                  width: 104,
                  height: 23,
                  child: Text(
                    'SILKRETO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.90,
                    ),
                  ),
                ),
              ),
              // Notification Icon
              Positioned(
                left: 341,
                top: 18,
                child: SizedBox(width: 18, height: 18, child: Stack()),
              ),
              // Weather Card
              Positioned(
                left: 21,
                top: 83,
                child: Container(
                  width: 338,
                  height: 125,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.50, -0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [Color(0xFFFFD20F), Color(0xFFFDE7B3)],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0x3F000000),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              // Weather Image
              Positioned(
                left: 155,
                top: 97,
                child: Container(
                  width: 107,
                  height: 90,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/107x90"),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              // Date Info
              Positioned(
                left: 35,
                top: 94,
                child: Container(
                  width: 120,
                  height: 14,
                  decoration: ShapeDecoration(
                    color: const Color(0xCCFDE7B3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              // Location Icon
              Positioned(
                left: 38,
                top: 95,
                child: Container(
                  width: 12,
                  height: 12,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Stack(),
                ),
              ),
              // Location Text
              Positioned(
                left: 52,
                top: 96,
                child: Text(
                  'Sapilang, Bacnotan, La Union',
                  style: TextStyle(
                    color: const Color(0xFF2F2F2F),
                    fontSize: 8,
                    fontFamily: 'Source Sans Pro',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // Date and Time
              Positioned(
                left: 35,
                top: 121,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'SUNDAY\n',
                        style: TextStyle(
                          color: const Color(0xFF5B532C),
                          fontSize: 18,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '11 Nov, 2025',
                        style: TextStyle(
                          color: const Color(0xCC5B532C),
                          fontSize: 8,
                          fontFamily: 'Source Sans Pro',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Temperature
              Positioned(
                left: 262,
                top: 95,
                child: SizedBox(
                  width: 83,
                  child: Text(
                    '29°C',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: const Color(0xFF5B532C),
                      fontSize: 32,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      height: 1.37,
                    ),
                  ),
                ),
              ),
              // Weather Description
              Positioned(
                left: 299,
                top: 169,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Sunny',
                        style: TextStyle(
                          color: const Color(0xFF5B532C),
                          fontSize: 12,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: '                 ',
                        style: TextStyle(
                          color: const Color(0xFF2F2F2F),
                          fontSize: 12,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextSpan(
                        text: 'Feels like 31°C',
                        style: TextStyle(
                          color: const Color(0xCC5B532C),
                          fontSize: 8,
                          fontFamily: 'Source Sans Pro',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              // Weather Warning Text
              Positioned(
                left: 35,
                top: 166,
                child: SizedBox(
                  width: 102,
                  height: 31,
                  child: Text(
                    'Sunny weather may compromise the Silkworm, Grasserie and Flacherie diseases may occur.',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: const Color(0xFF5B532C),
                      fontSize: 6,
                      fontFamily: 'Source Sans Pro',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              // Explore Section Title
              Positioned(
                left: 21,
                top: 233,
                child: Text(
                  'Explore',
                  style: TextStyle(
                    color: const Color(0xFF5B532C),
                    fontSize: 16,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Disease Cards
              Positioned(
                left: 21,
                top: 270,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0x3F000000),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 49,
                top: 291,
                child: SizedBox(width: 20, height: 21, child: Stack()),
              ),
              Positioned(
                left: 44,
                top: 323,
                child: Text(
                  'Diseases',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF5B532C),
                    fontSize: 8,
                    fontFamily: 'Source Sans Pro',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Symptoms Card
              Positioned(
                left: 107,
                top: 270,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0x3F000000),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 133,
                top: 291,
                child: SizedBox(width: 23, height: 21, child: Stack()),
              ),
              Positioned(
                left: 126,
                top: 323,
                child: Text(
                  'Symptoms',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF5B532C),
                    fontSize: 8,
                    fontFamily: 'Source Sans Pro',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Prevention Card
              Positioned(
                left: 193,
                top: 270,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0x3F000000),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 219,
                top: 291,
                child: Container(
                  width: 24,
                  height: 24,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 212,
                top: 323,
                child: Text(
                  'Prevention',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF5B532C),
                    fontSize: 8,
                    fontFamily: 'Source Sans Pro',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Rearing Card
              Positioned(
                left: 279,
                top: 270,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0x3F000000),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 303,
                top: 287,
                child: Container(
                  width: 29,
                  height: 29,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 304,
                top: 323,
                child: Text(
                  'Rearing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF5B532C),
                    fontSize: 8,
                    fontFamily: 'Source Sans Pro',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Analytics Section
              Positioned(
                left: 21,
                top: 371,
                child: Text(
                  'Analytics',
                  style: TextStyle(
                    color: const Color(0xFF5B532C),
                    fontSize: 16,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Line Graph Card
              Positioned(
                left: 21,
                top: 441,
                child: Container(
                  width: 338,
                  height: 163,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0x3F000000),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 30,
                top: 453,
                child: Text(
                  'Line Graph',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontFamily: 'Source Sans Pro',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Year Dropdown
              Positioned(
                left: 299,
                top: 408,
                child: Container(
                  width: 60,
                  height: 18,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 311,
                top: 410,
                child: Text(
                  '2025',
                  style: TextStyle(
                    color: const Color(0xFF5B532C),
                    fontSize: 10,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Positioned(
                left: 338,
                top: 412,
                child: Container(
                  width: 10,
                  height: 10,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Stack(),
                ),
              ),
              // All Months Section
              Positioned(
                left: 21,
                top: 629,
                child: Text(
                  'All Months',
                  style: TextStyle(
                    color: const Color(0xFF5B532C),
                    fontSize: 16,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Month cards (November, October, September, August)
              // November Card
              Positioned(
                left: 21,
                top: 666,
                child: Container(
                  width: 327,
                  height: 50,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0x3F000000),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 31.90,
                top: 673,
                child: SizedBox(
                  width: 49.58,
                  child: Text(
                    'November',
                    style: TextStyle(
                      color: const Color(0xFF5B532C),
                      fontSize: 10,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 31.99,
                top: 699,
                child: Container(
                  width: 168.34,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 3,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: Color(0xFF66A060),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 111.72,
                top: 686,
                child: SizedBox(
                  width: 13.71,
                  child: Text(
                    '60%',
                    style: TextStyle(
                      color: const Color(0xFF66A060),
                      fontSize: 6,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 202.43,
                top: 699,
                child: Container(
                  width: 100.21,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 3,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: Color(0xFFE84A4A),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 245.68,
                top: 686,
                child: SizedBox(
                  width: 13.71,
                  child: Text(
                    '35%',
                    style: TextStyle(
                      color: const Color(0xFFE84A4A),
                      fontSize: 6,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 304.75,
                top: 699,
                child: Container(
                  width: 28.48,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 3,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: Color(0xFFB05CC5),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 314.25,
                top: 686,
                child: SizedBox(
                  width: 10.55,
                  child: Text(
                    '5%',
                    style: TextStyle(
                      color: const Color(0xFFB05CC5),
                      fontSize: 6,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 198.21,
                top: 694,
                child: Container(
                  width: 8.44,
                  height: 8,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF66A060),
                    shape: const OvalBorder(),
                  ),
                ),
              ),
              Positioned(
                left: 300.53,
                top: 694,
                child: Container(
                  width: 8.44,
                  height: 8,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE84A4A),
                    shape: const OvalBorder(),
                  ),
                ),
              ),
              Positioned(
                left: 328.65,
                top: 694,
                child: Container(
                  width: 8.44,
                  height: 8,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFB05CC5),
                    shape: const OvalBorder(),
                  ),
                ),
              ),
              Positioned(
                left: 188.98,
                top: 670,
                child: SizedBox(
                  width: 30.59,
                  child: Text(
                    'Healthy',
                    style: TextStyle(
                      color: const Color(0xFF66A060),
                      fontSize: 8,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 171.04,
                top: 676,
                child: Container(
                  width: 15.82,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: Color(0xFF66A060),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 184.50,
                top: 674,
                child: Container(
                  width: 3.16,
                  height: 3,
                  decoration: ShapeDecoration(
                    shape: OvalBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFF66A060),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 253.32,
                top: 670,
                child: SizedBox(
                  width: 17.93,
                  child: Text(
                    'NPV',
                    style: TextStyle(
                      color: const Color(0xFFE84A4A),
                      fontSize: 8,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 236.44,
                top: 676,
                child: Container(
                  width: 15.82,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE84A4A),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: Color(0xFFE84A4A),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 249.32,
                top: 674,
                child: Container(
                  width: 3.16,
                  height: 3,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE84A4A),
                    shape: OvalBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFFE84A4A),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 306.06,
                top: 670,
                child: SizedBox(
                  width: 34.81,
                  child: Text(
                    'Flacherie',
                    style: TextStyle(
                      color: const Color(0xFFB05CC5),
                      fontSize: 8,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 288.13,
                top: 676,
                child: Container(
                  width: 15.82,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFB05CC5),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: Color(0xFFB05CC5),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 301.56,
                top: 674,
                child: Container(
                  width: 3.16,
                  height: 3,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFB05CC5),
                    shape: OvalBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFFB05CC5),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom Navigation Bar
              Positioned(
                left: 63,
                top: 875,
                child: Container(
                  width: 255,
                  height: 34,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.50, 0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [Color(0xFFFFC50F), Color(0xFF997609)],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 81,
                top: 880,
                child: Container(
                  width: 19,
                  height: 19,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 82,
                top: 897,
                child: Text(
                  'Home',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF504926),
                    fontSize: 6,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 130,
                top: 881,
                child: Container(
                  width: 18,
                  height: 18,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 132,
                top: 897,
                child: Text(
                  'Scan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF504926),
                    fontSize: 6,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 178,
                top: 880,
                child: Container(
                  width: 20,
                  height: 20,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 178,
                top: 897,
                child: Text(
                  'Upload',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF504926),
                    fontSize: 6,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 230,
                top: 881,
                child: Container(
                  width: 18,
                  height: 18,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 228,
                top: 897,
                child: Text(
                  'History',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF504926),
                    fontSize: 6,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 281,
                top: 881,
                child: Container(
                  width: 18,
                  height: 18,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 279,
                top: 897,
                child: Text(
                  'Manual',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF504926),
                    fontSize: 6,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;
    final color = selected ? const Color(0xFF6B5B95) : Colors.grey[600];
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, int index, Size size) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: size.height * 0.18,
        child: Row(
          children: [
            Container(
              width: size.width * 0.34,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Icon(Icons.image, size: 60, color: Colors.grey),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item #${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        'This is a sample content card to demonstrate scrolling behavior. Replace with your real content.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
