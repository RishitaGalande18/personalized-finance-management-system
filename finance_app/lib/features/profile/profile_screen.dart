import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() => isLoading = true);
    try {
      final profile = await ApiService.getProfile();
      setState(() {
        userProfile = profile;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading profile: $e");
      setState(() => isLoading = false);
    }
  }

  void logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: AppColors.primaryDark,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProfile == null
              ? const Center(
                  child: Text("Failed to load profile",
                      style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Header
                      Card(
                        color: AppColors.bgCard,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.person,
                                    size: 50, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                userProfile!['name'] ?? 'User',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userProfile!['email'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // User Details
                      Card(
                        color: AppColors.bgCard,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ListTile(
                                title: const Text("User Type",
                                    style:
                                        TextStyle(color: Colors.white70)),
                                trailing: Text(
                                  userProfile!['user_type'] ?? '-',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const Divider(color: Colors.white12),
                              ListTile(
                                title: const Text("Monthly Income",
                                    style:
                                        TextStyle(color: Colors.white70)),
                                trailing: Text(
                                  '\$${userProfile!['monthly_income']?.toStringAsFixed(2) ?? '0'}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(color: Colors.white12),
                              ListTile(
                                title: const Text("Risk Profile",
                                    style:
                                        TextStyle(color: Colors.white70)),
                                trailing: Text(
                                  userProfile!['risk_profile'] ?? '-',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Settings Section
                      const Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Settings",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Card(
                        color: AppColors.bgCard,
                        child: ListTile(
                          leading: Icon(Icons.notifications,
                              color: Colors.white),
                          title: Text("Enable Notifications",
                              style: TextStyle(color: Colors.white)),
                          trailing: Switch(value: true, onChanged: null),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Card(
                        color: AppColors.bgCard,
                        child: ListTile(
                          leading:
                              Icon(Icons.security, color: Colors.white),
                          title: Text("Change Password",
                              style: TextStyle(color: Colors.white)),
                          trailing: Icon(Icons.arrow_forward,
                              color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: AppColors.bgCard,
                        child: ListTile(
                          leading: Icon(Icons.info, color: Colors.white),
                          title: const Text("About App",
                              style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.arrow_forward,
                              color: Colors.white70),
                          onTap: () => showAboutDialog(context: context),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: logout,
                          child: const Text(
                            "Logout",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
