import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecocash_partnership/core/widgets/app_loading.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  static const Color _navy = Color(0xFF142D4E);
  static const Color _yellow = Color(0xFFFFC928);
  static const Color _background = Color(0xFFF4F6F9);
  static const Color _secondary = Color(0xFF8290A3);
  static const Color _border = Color(0xFFEDF0F4);
  static const Color _red = Color(0xFFE05252);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: _isLoading
          ? AppLoading(message: 'Menyiapkan pengaturan aplikasi...', size: 76)
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      children: [
                        _buildBackButton(context),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Pengaturan',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CE),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: _navy,
                            size: 21,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildIntroCard(),

                    const SizedBox(height: 28),

                    _buildSectionTitle(
                      'Akun',
                      'Kelola informasi dan keamanan akun Anda',
                    ),
                    _buildMenuGroup([
                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profil',
                        subtitle: 'Perbarui informasi pribadi Anda',
                        onTap: () => context.push('/edit-profile'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.shield_outlined,
                        title: 'Keamanan',
                        subtitle: 'PIN, kata sandi, dan perangkat',
                        onTap: () => context.push('/keamanan'),
                      ),
                    ]),

                    const SizedBox(height: 25),

                    _buildSectionTitle(
                      'Preferensi',
                      'Atur pengalaman penggunaan aplikasi',
                    ),
                    _buildMenuGroup([
                      _buildMenuItem(
                        icon: Icons.language_rounded,
                        title: 'Bahasa',
                        subtitle: 'Bahasa yang digunakan aplikasi',
                        trailingText: 'Indonesia',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Pengaturan Notifikasi',
                        subtitle: 'Atur pemberitahuan akun dan transaksi',
                        onTap: () {
                          context.push('/pengaturan-notifikasi');
                        },
                      ),
                    ]),

                    const SizedBox(height: 25),

                    _buildSectionTitle(
                      'Umum',
                      'Informasi dan bantuan penggunaan aplikasi',
                    ),
                    _buildMenuGroup([
                      _buildMenuItem(
                        icon: Icons.support_agent_rounded,
                        title: 'Pusat Bantuan',
                        subtitle: 'Dapatkan bantuan dari tim EcoCash',
                        onTap: () {
                          context.push('/pusat-bantuan');
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang EcoCash Indonesia',
                        subtitle: 'Informasi aplikasi dan pengembang',
                        trailingText: 'v3.0.0',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Syarat & Ketentuan / Privasi',
                        subtitle: 'Ketentuan penggunaan dan privasi',
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 27),

                    _buildDeleteAccountCard(context),

                    const SizedBox(height: 25),

                    // FOOTER
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _yellow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'EcoCash Partner',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Versi aplikasi 3.0.0',
                            style: TextStyle(color: _secondary, fontSize: 10),
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            Navigator.pop(context);
          }
        },
        child: const SizedBox(
          width: 43,
          height: 43,
          child: Icon(Icons.arrow_back_rounded, color: _navy, size: 21),
        ),
      ),
    );
  }

  // ============================================================
  // INTRO CARD
  // ============================================================

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.045),
              ),
            ),
          ),
          Positioned(
            right: 15,
            bottom: -65,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.035),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _yellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: _navy,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Text(
                    'Pengaturan Aplikasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 19),
              const Text(
                'Atur aplikasi sesuai kebutuhan Anda.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kelola akun, preferensi, notifikasi, dan informasi EcoCash Partner dalam satu tempat.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 43,
                height: 4,
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: _secondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU GROUP
  // ============================================================

  Widget _buildMenuGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5D8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _navy, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _secondary,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 5),
                Text(
                  trailingText,
                  style: const TextStyle(
                    color: _secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 7),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: _secondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 71,
      endIndent: 15,
      color: _border,
    );
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Widget _buildDeleteAccountCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => _showDeleteAccountDialog(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFF3DEDE)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.delete_forever_outlined,
                  color: _red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengajuan Hapus Akun',
                      style: TextStyle(
                        color: _red,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Informasi penutupan akun mitra',
                      style: TextStyle(color: _secondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _red, size: 23),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG HAPUS AKUN
  // ============================================================

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
          child: Padding(
            padding: const EdgeInsets.all(21),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 57,
                    height: 57,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: _red,
                      size: 29,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                const Center(
                  child: Text(
                    'Penutupan Akun Mitra',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sesuai ketentuan EcoCash, akun Mitra yang terikat dengan riwayat dompet dan penjemputan tidak dapat dihapus secara mandiri dari aplikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _secondary,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 17),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5D8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.support_agent_rounded, color: _navy, size: 21),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Silakan hubungi Administrator melalui Pusat Bantuan untuk mengajukan penutupan akun.',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: _secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            context.push('/chat-cs');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navy,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text(
                            'Chat CS Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
