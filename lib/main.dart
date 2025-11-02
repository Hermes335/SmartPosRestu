import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/order_management_screen.dart';
import 'screens/table_management_screen.dart';
import 'screens/staff_management_screen.dart';
import 'screens/analytics_screen.dart';
import 'utils/constants.dart';

/// Main entry point of the SmartServe POS application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize Firebase
  // await Firebase.initializeApp();
  
  runApp(const SmartServePOS());
}

/// Root application widget
class SmartServePOS extends StatelessWidget {
  const SmartServePOS({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Dark theme configuration
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConstants.darkBackground,
        primaryColor: AppConstants.primaryOrange,
        colorScheme: ColorScheme.dark(
          primary: AppConstants.primaryOrange,
          secondary: AppConstants.accentOrange,
          surface: AppConstants.cardBackground,
          background: AppConstants.darkBackground,
          error: AppConstants.errorRed,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.darkSecondary,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppConstants.textPrimary),
          titleTextStyle: AppConstants.headingMedium,
        ),
        cardTheme: CardThemeData(
          color: AppConstants.cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.paddingMedium,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppConstants.primaryOrange,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: AppConstants.headingLarge,
          headlineMedium: AppConstants.headingMedium,
          headlineSmall: AppConstants.headingSmall,
          bodyLarge: AppConstants.bodyLarge,
          bodyMedium: AppConstants.bodyMedium,
          bodySmall: AppConstants.bodySmall,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // List of screens for navigation
  final List<Widget> _screens = const [
    DashboardScreen(),
    OrderManagementScreen(),
    TableManagementScreen(),
    StaffManagementScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppConstants.darkSecondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSmall,
              vertical: AppConstants.paddingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                _buildNavItem(1, Icons.receipt_long, 'Orders'),
                _buildNavItem(2, Icons.table_restaurant, 'Tables'),
                _buildNavItem(3, Icons.people, 'Staff'),
                _buildNavItem(4, Icons.analytics, 'Analytics'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build navigation item
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryOrange.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppConstants.primaryOrange
                  : AppConstants.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? AppConstants.primaryOrange
                    : AppConstants.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
