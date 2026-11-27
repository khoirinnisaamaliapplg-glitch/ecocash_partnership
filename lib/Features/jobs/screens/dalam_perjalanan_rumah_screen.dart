import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../services/api_service.dart';
import '../../../services/job_socket_service.dart';

class MaterialInputItem {
  final int materialId;
  final int? wasteTypeId;
  final String name;
  final double ratePerKg;
  double weight;
  bool isCustomerSelected;

  MaterialInputItem({
    required this.materialId,
    this.wasteTypeId,
    required this.name,
    required this.ratePerKg,
    this.weight = 0.0,
    this.isCustomerSelected = false,
  });

  double get subtotal => weight * ratePerKg;
}

class TrashPhotoItem {
  final String? path;
  final Uint8List? bytes;
  final String label;

  TrashPhotoItem({
    this.path,
    this.bytes,
    required this.label,
  });
}

class DalamPerjalananRumahScreen extends StatefulWidget {
  final Map extraData;

  const DalamPerjalananRumahScreen({super.key, this.extraData = const {}});

  @override
  State<DalamPerjalananRumahScreen> createState() => _DalamPerjalananRumahScreenState();
}

class _DalamPerjalananRumahScreenState extends State<DalamPerjalananRumahScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final JobSocketService _socketService = JobSocketService.instance;
  final ImagePicker _picker = ImagePicker();

  StreamSubscription<JobSocketEvent>? _socketSub;
  int _currentStep = 1; // 1: Menuju Lokasi, 2: Timbang, 3: Setor Tujuan, 4: Selesai
  bool _isLoading = false;
  bool _isLoadingMaterials = true;
  Timer? _statusCheckTimer;

  List<MaterialInputItem> _materialInputs = [];
  String _qrCodeHandover = '';
  Map<String, dynamic>? _latestJobDetail;

  final List<TrashPhotoItem> _trashPhotos = [];

  final LatLng _userLocation = const LatLng(-6.8915, 107.6101);
  LatLng get _customerLocation {
    final double? lat = double.tryParse(
      (_effectiveJob['latitude'] ?? _effectiveJob['lat'] ?? widget.extraData['latitude'] ?? '').toString(),
    );
    final double? lng = double.tryParse(
      (_effectiveJob['longitude'] ?? _effectiveJob['lng'] ?? widget.extraData['longitude'] ?? '').toString(),
    );
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(-6.8985, 107.6151);
  }

  Map get _rawJob {
    if (widget.extraData['rawJob'] is Map) {
      final raw = widget.extraData['rawJob'] as Map;
      if (raw['job'] is Map) return raw['job'] as Map;
      return raw;
    }
    if (widget.extraData['job'] is Map) {
      return widget.extraData['job'] as Map;
    }
    return widget.extraData;
  }

  dynamic get _jobId {
    return _latestJobDetail?['id'] ??
        _rawJob['id'] ??
        widget.extraData['jobId'] ??
        widget.extraData['id'];
  }

  Map get _effectiveJob => _latestJobDetail ?? _rawJob;

  bool get _hasTargetMachine {
    final dynamic mId = _effectiveJob['machineId'] ?? _effectiveJob['machine']?['id'];
    if (mId != null && mId.toString().isNotEmpty && mId.toString() != 'null') {
      return true;
    }
    final String desc = (_effectiveJob['description'] ?? '').toString();
    return RegExp(r'\[TARGET_MACHINE_ID:\d+\]').hasMatch(desc);
  }

  String get _title =>
      _effectiveJob['title'] ?? widget.extraData['title'] ?? _effectiveJob['customerName'] ?? 'Penjemputan Warga';
  String get _rawAddress =>
      _effectiveJob['address'] ?? widget.extraData['address'] ?? _effectiveJob['description'] ?? 'Lokasi Penjemputan';
  String get _cleanAddress => _rawAddress.replaceAll(RegExp(r'\[.*?\]'), '').trim();

  String get _customerName =>
      _effectiveJob['user']?['name'] ?? _effectiveJob['customerName'] ?? 'Warga EcoCash';
  String get _customerPhone =>
      _effectiveJob['user']?['phoneNumber'] ?? _effectiveJob['customerPhone'] ?? '-';
  String get _customerAvatarUrl =>
      _effectiveJob['user']?['avatarUrl'] ?? _effectiveJob['avatarUrl'] ?? '';

  String get _targetMachineCode {
    final code = _effectiveJob['machine']?['machineCode'] ??
        _effectiveJob['targetMachine']?['machineCode'] ??
        _effectiveJob['machineCode'];
    if (code != null && code.toString().isNotEmpty && code.toString() != 'null') {
      return code.toString();
    }
    return 'RVM-001';
  }

  String get _targetDestinationName {
    if (_hasTargetMachine) {
      final name = _effectiveJob['machine']?['name'] ??
          _effectiveJob['targetMachineName'] ??
          _effectiveJob['targetMachine']?['name'];
      if (name != null && name.toString().isNotEmpty && name.toString() != 'null') {
        return name.toString();
      }
      return 'Smart Container Terdekat';
    }
    return 'Mitra Bank Sampah EcoCash';
  }

  String get _customerNotes {
    final directNote = _effectiveJob['notes']?.toString().trim();
    if (directNote != null && directNote.isNotEmpty) return directNote;

    final desc = _effectiveJob['description']?.toString() ?? '';
    final matchNote = RegExp(r'Catatan:\s*([^\[]+)').firstMatch(desc);
    if (matchNote != null && matchNote.group(1) != null) {
      return matchNote.group(1)!.trim();
    }
    return 'Sampah diletakkan di teras atau depan rumah.';
  }

  /// Daftar ringkasan jenis sampah & berat yang diminta warga (untuk selalu ditampilkan)
  List<String> get _citizenRequestedItemsDisplay {
    final List<String> items = [];

    // 1. Dari relasi database `weights`
    final weights = _effectiveJob['weights'];
    if (weights is List && weights.isNotEmpty) {
      for (final w in weights) {
        if (w is Map) {
          final String matName = (w['material']?['name'] ?? w['materialName'] ?? '').toString();
          final double pw = double.tryParse((w['pickupWeight'] ?? '0').toString()) ?? 0.0;
          if (matName.isNotEmpty) {
            items.add(pw > 0 ? '$matName (${pw.toStringAsFixed(1)} kg)' : matName);
          }
        }
      }
    }
    if (items.isNotEmpty) return items;

    // 2. Dari tag [CATEGORY:...] atau materialCategory / materialTag
    final String catHint = _extractCitizenCategoryHint();
    if (catHint.isNotEmpty) {
      final parts = catHint.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts;
    }

    // 3. Dari material yang sudah ter-match di _materialInputs
    for (final m in _materialInputs.where((m) => m.isCustomerSelected)) {
      items.add(m.weight > 0 ? '${m.name} (${m.weight.toStringAsFixed(1)} kg)' : m.name);
    }

    return items;
  }

  double get _totalWeight => _materialInputs.fold(0.0, (sum, m) => sum + m.weight);
  double get _totalPayout => _materialInputs.fold(0.0, (sum, m) => sum + m.subtotal);

  String get _displayPrice {
    final raw = widget.extraData['price'] ??
        _effectiveJob['price'] ??
        _effectiveJob['estimatedReward'] ??
        _effectiveJob['actualReward'] ??
        _effectiveJob['reward'];
    if (raw == null) return 'Rp 25.000';
    final String str = raw.toString().trim();
    return str.startsWith('Rp') ? str : 'Rp $str';
  }

  String _formatCurrency(num amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  void initState() {
    super.initState();
    _initJobSocket();
    _bootstrapJobAndMaterials();
  }

  @override
  void dispose() {
    if (_jobId != null) {
      _socketService.leaveJobRoom(_jobId);
    }
    _socketSub?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initJobSocket() async {
    await _socketService.connect();
    if (_jobId != null) {
      _socketService.joinJobRoom(_jobId);
    }

    _socketSub = _socketService.events.listen((event) {
      if (!mounted || _jobId == null) return;
      if (event.type == 'job:status' &&
          event.payload['jobId']?.toString() == _jobId.toString()) {
        final String nextStatus = (event.payload['status'] ?? '').toString().toUpperCase();
        if (nextStatus == 'COMPLETED' && _currentStep != 4) {
          _statusCheckTimer?.cancel();
          final bool byMachine = event.payload['confirmedByMachine'] == true;
          _showSnack(
            byMachine
                ? 'Layar Smart Container telah menimbang & mengonfirmasi setoran! Tugas selesai.'
                : 'Setoran telah terverifikasi! Tugas selesai.',
            AppColors.ecoGreen,
          );
          setState(() => _currentStep = 4);
        } else if ((nextStatus == 'IN_TRANSIT' || nextStatus == 'HANDOVER') && _currentStep < 3) {
          setState(() => _currentStep = 3);
        } else if (nextStatus == 'CHECKED_IN' && _currentStep < 2) {
          setState(() => _currentStep = 2);
        }
      }
    });
  }

  void _showSnack(String message, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
  }

  Future<void> _bootstrapJobAndMaterials() async {
    if (_jobId != null) {
      try {
        final detailRes = await _apiService.getJobDetail(_jobId);
        if (detailRes['success'] == true && detailRes['data'] is Map && mounted) {
          final dataMap = detailRes['data'] as Map;
          _latestJobDetail = Map<String, dynamic>.from(
            dataMap['job'] is Map ? dataMap['job'] as Map : dataMap,
          );
        }
      } catch (_) {}
    }

    await _initFlowState();
    await _loadMaterialsFromAdmin();
  }

  Map<int, double> _extractCitizenMaterialWeightsMap() {
    final Map<int, double> map = {};
    final String desc = (_effectiveJob['description'] ?? _rawJob['description'] ?? '').toString();
    final match = RegExp(r'\[MATERIALS:([^\]]+)\]').firstMatch(desc);
    if (match != null && match.group(1) != null) {
      for (final pair in match.group(1)!.split(',')) {
        final kv = pair.split(':');
        if (kv.length == 2) {
          final id = int.tryParse(kv[0].trim());
          final w = double.tryParse(kv[1].trim());
          if (id != null && id > 0 && w != null && w > 0) {
            map[id] = w;
          }
        }
      }
    }
    return map;
  }

  List<int> _extractCitizenWasteTypeIds() {
    final Set<int> ids = {};
    final dynamic rawIds = _effectiveJob['wasteTypeIds'] ?? _rawJob['wasteTypeIds'] ?? widget.extraData['wasteTypeIds'];
    if (rawIds is List) {
      for (final item in rawIds) {
        final parsed = int.tryParse(item.toString());
        if (parsed != null && parsed > 0) ids.add(parsed);
      }
    }
    final String desc = (_effectiveJob['description'] ?? _rawJob['description'] ?? '').toString();
    final match = RegExp(r'\[WASTE_TYPES:([\d,]+)\]').firstMatch(desc);
    if (match != null && match.group(1) != null) {
      for (final part in match.group(1)!.split(',')) {
        final parsed = int.tryParse(part.trim());
        if (parsed != null && parsed > 0) ids.add(parsed);
      }
    }
    return ids.toList();
  }

  String _extractCitizenCategoryHint() {
    final String desc = (_effectiveJob['description'] ?? _rawJob['description'] ?? '').toString();
    final match = RegExp(r'\[CATEGORY:([^\]]+)\]').firstMatch(desc);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
    final hint = (_effectiveJob['materialCategory'] ??
            _effectiveJob['materialTag'] ??
            _rawJob['materialCategory'] ??
            _rawJob['materialTag'] ??
            widget.extraData['materialCategory'] ??
            widget.extraData['materialTag'] ??
            '')
        .toString();
    if (hint.isNotEmpty &&
        hint.toLowerCase() != 'sampah warga' &&
        hint.toLowerCase() != 'sampah daur ulang warga') {
      return hint;
    }
    return '';
  }

  Future<void> _loadMaterialsFromAdmin() async {
    setState(() => _isLoadingMaterials = true);
    try {
      final Map<String, dynamic> res = await _apiService.getMaterials();
      final dynamic dataField = res['data'];
      final List<dynamic> rawList = dataField is List ? dataField : [];

      if (rawList.isNotEmpty && mounted) {
        final List<MaterialInputItem> loaded = rawList.map((item) {
          final int id = int.tryParse(item['id'].toString()) ?? 1;
          final int? wtId = int.tryParse((item['wasteTypeId'] ?? item['wasteType']?['id'] ?? '').toString());
          final String name = (item['name'] ?? 'Material').toString();
          final double rate = double.tryParse((item['pricePerKg'] ?? '500').toString()) ?? 500.0;
          return MaterialInputItem(
            materialId: id,
            wasteTypeId: wtId,
            name: name,
            ratePerKg: rate,
            weight: 0.0,
          );
        }).toList();

        // 1. Prioritas Utama: Rincian `weights` dari database (dibuat saat warga pesan atau kurir timbang)
        final weights = _effectiveJob['weights'] ?? _rawJob['weights'];
        final Map<int, double> tagWeightsMap = _extractCitizenMaterialWeightsMap();

        if (weights is List && weights.isNotEmpty) {
          for (var w in weights) {
            final mId = int.tryParse((w['materialId'] ?? '').toString());
            final pWeight = double.tryParse((w['pickupWeight'] ?? '0').toString()) ?? 0.0;
            final matchIdx = loaded.indexWhere((m) => m.materialId == mId);
            if (matchIdx != -1) {
              loaded[matchIdx].weight = pWeight;
              loaded[matchIdx].isCustomerSelected = true;
            }
          }
        } else if (tagWeightsMap.isNotEmpty) {
          // 2. Prioritas Kedua: Tag [MATERIALS:id:weight,...] di deskripsi
          tagWeightsMap.forEach((mId, pWeight) {
            final matchIdx = loaded.indexWhere((m) => m.materialId == mId);
            if (matchIdx != -1) {
              loaded[matchIdx].weight = pWeight;
              loaded[matchIdx].isCustomerSelected = true;
            }
          });
        } else {
          // 3. Prioritas Ketiga: Cocokkan ID / kategori pilihan warga & bagi estimasi berat
          final double estW = double.tryParse((_effectiveJob['estimatedWeight'] ?? '0').toString()) ?? 0.0;
          final List<int> citizenIds = _extractCitizenWasteTypeIds();
          final String categoryHint = _extractCitizenCategoryHint().toLowerCase();

          final List<MaterialInputItem> matched = [];

          if (citizenIds.isNotEmpty) {
            for (final targetId in citizenIds) {
              final directMatch = loaded.where((m) => m.materialId == targetId).toList();
              final candidates = directMatch.isNotEmpty
                  ? directMatch
                  : loaded.where((m) => m.wasteTypeId == targetId).toList();
              if (candidates.isNotEmpty && !matched.contains(candidates.first)) {
                matched.add(candidates.first);
              }
            }
          }

          if (matched.isEmpty && categoryHint.isNotEmpty) {
            for (final m in loaded) {
              final lowerName = m.name.toLowerCase();
              if (categoryHint.contains(lowerName) ||
                  (categoryHint.contains('pet') && lowerName.contains('pet')) ||
                  (categoryHint.contains('hdpe') && lowerName.contains('hdpe')) ||
                  ((categoryHint.contains('kardus') || categoryHint.contains('kertas')) &&
                      (lowerName.contains('kardus') || lowerName.contains('kertas'))) ||
                  ((categoryHint.contains('kaleng') || categoryHint.contains('aluminium')) &&
                      lowerName.contains('kaleng')) ||
                  (categoryHint.contains('kaca') && lowerName.contains('kaca')) ||
                  (categoryHint.contains('campuran') && lowerName.contains('campuran'))) {
                if (!matched.contains(m)) matched.add(m);
              }
            }
          }

          if (matched.isNotEmpty && estW > 0) {
            final double perItem = double.parse((estW / matched.length).toStringAsFixed(1));
            double allocated = 0.0;
            for (int i = 0; i < matched.length; i++) {
              matched[i].isCustomerSelected = true;
              if (i == matched.length - 1) {
                matched[i].weight = double.parse((estW - allocated).clamp(0.1, 999.0).toStringAsFixed(1));
              } else {
                matched[i].weight = perItem;
                allocated += perItem;
              }
            }
          } else if (estW > 0 && loaded.isNotEmpty) {
            loaded.first.weight = estW;
            loaded.first.isCustomerSelected = true;
          }
        }

        // Urutkan agar jenis sampah yang dipilih warga tampil paling atas
        loaded.sort((a, b) {
          if (a.isCustomerSelected == b.isCustomerSelected) return 0;
          return a.isCustomerSelected ? -1 : 1;
        });

        setState(() {
          _materialInputs = loaded;
          _isLoadingMaterials = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("Gagal memuat material dari DB: $e");
    }

    if (mounted && _materialInputs.isEmpty) {
      setState(() {
        _materialInputs = [
          MaterialInputItem(materialId: 1, name: 'PET (Botol Bening)', ratePerKg: 500, weight: 0.0),
          MaterialInputItem(materialId: 4, name: 'Kardus & Kertas', ratePerKg: 500, weight: 0.0),
          MaterialInputItem(materialId: 3, name: 'Kaleng Aluminium', ratePerKg: 500, weight: 0.0),
          MaterialInputItem(materialId: 5, name: 'Botol & Pecahan Kaca', ratePerKg: 500, weight: 0.0),
        ];
        _isLoadingMaterials = false;
      });
    }
  }

  Future<void> _initFlowState() async {
    final String status = (_effectiveJob['status'] ?? '').toString().toUpperCase();

    if (status == 'CHECKED_IN' || status == 'PICKUP') {
      if (mounted) setState(() => _currentStep = 2);
    } else if (status == 'IN_TRANSIT' || status == 'HANDOVER') {
      if (mounted) setState(() => _currentStep = 3);
      await _fetchExistingQr();
      _startStatusPolling();
    } else if (status == 'COMPLETED') {
      if (mounted) setState(() => _currentStep = 4);
    } else {
      if (_jobId != null) {
        await _apiService.startRoute(_jobId);
      }
    }
  }

  Future<void> _fetchExistingQr() async {
    if (_jobId == null) return;
    final res = await _apiService.generateHandoverQr(_jobId);
    if (res['success'] == true && res['data']?['qrCode'] != null && mounted) {
      setState(() {
        _qrCodeHandover = res['data']['qrCode'].toString();
      });
    }
  }

  void _startStatusPolling() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted || _currentStep != 3 || _jobId == null) {
        timer.cancel();
        return;
      }

      try {
        final res = await _apiService.getJobDetail(_jobId);
        if (res['success'] == true && res['data'] != null) {
          final String currentStatus = (res['data']['status'] ?? '').toString().toUpperCase();
          if (currentStatus == 'COMPLETED') {
            timer.cancel();
            if (mounted) {
              _showSnack('Setoran telah terverifikasi! Tugas selesai.', AppColors.ecoGreen);
              setState(() => _currentStep = 4);
            }
          }
        }
      } catch (e) {
        debugPrint('Polling status error: $e');
      }
    });
  }

  Future<void> _takeTrashPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        final Uint8List imageBytes = await photo.readAsBytes();
        _showPhotoLabelModal(imageBytes);
      }
    } catch (e) {
      _showError('Gagal membuka kamera: $e');
    }
  }

  void _showPhotoLabelModal(Uint8List imageBytes) {
    final String initialLabel = _materialInputs.any((m) => m.weight > 0)
        ? '${_materialInputs.firstWhere((m) => m.weight > 0).name} • ${_totalWeight.toStringAsFixed(1)}kg'
        : 'Foto Timbangan Sampah';

    final TextEditingController labelController = TextEditingController(text: initialLabel);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppColors.darkNavy, size: 24),
            SizedBox(width: 10),
            Text('Keterangan Foto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pilih atau ketik jenis/kategori sampah:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._materialInputs.where((m) => m.weight > 0).map(
                      (m) => _buildQuickChip('${m.name} • ${m.weight.toStringAsFixed(1)}kg', labelController),
                    ),
                _buildQuickChip('Sampah Campur', labelController),
                _buildQuickChip('Bukti Timbangan Digital', labelController),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: labelController,
              decoration: InputDecoration(
                hintText: 'Contoh: Botol Plastik / Kardus',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final String labelText = labelController.text.trim();
              setState(() {
                _trashPhotos.add(TrashPhotoItem(
                  bytes: imageBytes,
                  label: labelText.isEmpty ? 'Foto Sampah' : labelText,
                ));
              });
              Navigator.pop(ctx);
              _showSnack('Foto bukti sampah berhasil ditambahkan!', AppColors.ecoGreen);
            },
            child: const Text('Simpan Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () => controller.text = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryYellow.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
      ),
    );
  }

  Future<void> _handleStepNext() async {
    if (_jobId == null) {
      if (_currentStep < 4) setState(() => _currentStep++);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_currentStep == 1) {
        final res = await _apiService.checkIn(_jobId);
        if (res['success'] == true) {
          setState(() => _currentStep = 2);
          _showSnack('Berhasil Check-In di lokasi penjemputan!', AppColors.ecoGreen);
        } else {
          _showError(res['message'] ?? 'Gagal Check-In');
        }
      } else if (_currentStep == 2) {
        final activeMaterials = _materialInputs.where((m) => m.weight > 0).toList();

        if (activeMaterials.isEmpty) {
          _showError('Isi timbangan minimal 1 jenis material sebelum melanjutkan!');
          setState(() => _isLoading = false);
          return;
        }

        final materialsPayload = activeMaterials
            .map((m) => {
                  'materialId': m.materialId,
                  'pickupWeight': m.weight,
                  'pricePerKg': m.ratePerKg,
                })
            .toList();

        final resPickup = await _apiService.submitPickup(_jobId, materials: materialsPayload);
        if (resPickup['success'] == true) {
          final resQr = await _apiService.generateHandoverQr(_jobId);
          setState(() {
            _qrCodeHandover = (resQr['data']?['qrCode'] ?? 'HANDOVER-#$_jobId').toString();
            _currentStep = 3;
          });
          _startStatusPolling();
        } else {
          _showError(resPickup['message'] ?? 'Gagal menyimpan timbangan');
        }
      } else if (_currentStep == 3) {
        if (_hasTargetMachine) {
          _openCameraScannerModal();
        } else {
          await _submitMitraHandoverSimulation();
        }
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitMitraHandoverSimulation() async {
    final activeMaterials = _materialInputs
        .where((m) => m.weight > 0)
        .map((m) => {
              'materialId': m.materialId,
              'handoverWeight': m.weight,
            })
        .toList();

    final res = await _apiService.verifyHandover(
      _jobId,
      qrCode: _qrCodeHandover.isNotEmpty ? _qrCodeHandover : 'HANDOVER-#$_jobId',
      materials: activeMaterials,
      notes: 'Serah terima muatan warga ke Mitra Bank Sampah EcoCash',
    );

    if (res['success'] == true) {
      _statusCheckTimer?.cancel();
      if (mounted) {
        _showSnack('Serah terima ke Mitra Bank Sampah berhasil dikonfirmasi!', AppColors.ecoGreen);
        setState(() => _currentStep = 4);
      }
    } else {
      _showError(res['message'] ?? 'Gagal memverifikasi serah terima mitra');
    }
  }

  void _openCameraScannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Pindai QR Fisik Smart Container', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  onDetect: (capture) async {
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                        final String scannedCode = barcode.rawValue!.trim();
                        Navigator.pop(ctx);
                        _submitMachineScanVerification(scannedCode);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Arahkan kamera ke stiker QR Code yang tertera di mesin kontainer',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMachineScanVerification(String scannedCode) async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.completeToMachine(
        _jobId,
        machineCode: scannedCode,
        totalWeightKg: _totalWeight,
      );

      if (res['success'] == true) {
        _statusCheckTimer?.cancel();
        if (mounted) {
          _showSnack('Kontainer $scannedCode terverifikasi! Muatan berhasil disetor.', AppColors.ecoGreen);
          setState(() => _currentStep = 4);
        }
      } else {
        _showError(res['message'] ?? 'Kode kontainer tidak cocok dengan penugasan');
      }
    } catch (e) {
      _showError('Gagal memverifikasi mesin: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    _showSnack(message, AppColors.error);
  }

  Widget _buildCitizenWasteSummaryBanner() {
    final items = _citizenRequestedItemsDisplay;
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryYellow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded, size: 16, color: AppColors.darkNavy),
              SizedBox(width: 6),
              Text(
                'Jenis Sampah yang Diinput Warga:',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryDark, size: 20),
          onPressed: () {
            if (_currentStep > 1 && _currentStep < 4) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          'Proses Penjemputan',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ValueListenableBuilder<bool>(
              valueListenable: _socketService.connectionNotifier,
              builder: (_, connected, __) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: connected ? const Color(0xFF22C55E) : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          connected ? 'LIVE' : 'SYNC',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _hasTargetMachine ? Icons.recycling_rounded : Icons.store_mall_directory_rounded,
                          size: 18,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hasTargetMachine
                                  ? 'Penjemputan Warga → Smart Container'
                                  : 'Penjemputan Warga → Mitra Bank Sampah',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Order #${_jobId ?? "-"} • Tujuan: $_targetDestinationName',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        _buildStepHeaderItem(1, 'Menuju Lokasi'),
                        _buildStepHeaderDivider(1),
                        _buildStepHeaderItem(2, 'Timbang'),
                        _buildStepHeaderDivider(2),
                        _buildStepHeaderItem(3, _hasTargetMachine ? 'Setor Mesin' : 'Serah Mitra'),
                        _buildStepHeaderDivider(3),
                        _buildStepHeaderItem(4, 'Selesai'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildActiveStepBody(),
              ),
            ),

            if (_currentStep < 4)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleStepNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2.2),
                          )
                        : Text(
                            _getBottomButtonText(),
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getBottomButtonText() {
    switch (_currentStep) {
      case 1:
        return 'Konfirmasi Sampai di Lokasi';
      case 2:
        return _hasTargetMachine
            ? 'Simpan Timbangan & Lanjut ke Mesin'
            : 'Simpan Timbangan & Lanjut ke Mitra';
      case 3:
        return _hasTargetMachine
            ? 'Pindai QR Mesin (Opsional / Manual)'
            : 'Konfirmasi Serah Terima Mitra';
      default:
        return 'Lanjutkan';
    }
  }

  Widget _buildActiveStepBody() {
    switch (_currentStep) {
      case 1:
        return _buildStep1MenujuLokasi();
      case 2:
        return _buildStep2Timbang();
      case 3:
        return _buildStep3SetorTujuan();
      case 4:
        return _buildStep4Selesai();
      default:
        return Container();
    }
  }

  Widget _buildStep1MenujuLokasi() {
    final selectedNames = _materialInputs
        .where((m) => m.isCustomerSelected)
        .map((m) => m.name)
        .toList();
    final String summaryMaterial = selectedNames.isNotEmpty
        ? selectedNames.join(', ')
        : _materialInputs.map((m) => m.name).take(2).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: FlutterMap(
                  options: MapOptions(initialCenter: _customerLocation, initialZoom: 14.5),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation,
                          width: 32,
                          height: 32,
                          child: const Icon(Icons.two_wheeler_rounded, color: AppColors.darkNavy, size: 28),
                        ),
                        Marker(
                          point: _customerLocation,
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.location_pin, color: AppColors.ecoGreen, size: 36),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.navigation_rounded, color: AppColors.primaryYellow, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MENUJU TITIK PENJEMPUTAN',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primaryYellow),
                            ),
                            Text(
                              _cleanAddress,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.35),
                backgroundImage: _customerAvatarUrl.isNotEmpty ? NetworkImage(_customerAvatarUrl) : null,
                child: _customerAvatarUrl.isEmpty
                    ? Text(
                        _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'W',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: AppColors.darkNavy),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
                    const SizedBox(height: 2),
                    Text('Telp: $_customerPhone', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.darkNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryYellow, size: 20),
                  onPressed: () => context.push('/chat/room/$_jobId'),
                  tooltip: 'Chat Warga',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _buildCitizenWasteSummaryBanner(),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.recycling_rounded, color: AppColors.ecoGreen, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimasi Muatan Warga', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      '~${_totalWeight > 0 ? _totalWeight.toStringAsFixed(1) : "15.0"} kg ($summaryMaterial)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.darkNavy, borderRadius: BorderRadius.circular(20)),
                child: Text('$_displayPrice (Est.)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: const Border(left: BorderSide(color: AppColors.ecoGreen, width: 4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.note_alt_outlined, size: 20, color: AppColors.ecoGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Instruksi Penjemputan Pemesan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
                    const SizedBox(height: 2),
                    Text(_customerNotes, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Timbang() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCitizenWasteSummaryBanner(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Input Bobot Riil Lapangan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.darkNavy)),
                  Text('Jenis & estimasi berat warga terisi otomatis, silakan sesuaikan hasil timbang', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, size: 12, color: AppColors.ecoGreen),
                  SizedBox(width: 4),
                  Text('HARGA ADMIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.ecoGreen)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_isLoadingMaterials)
          const AppLoading(message: 'Memuat jenis & harga material...', size: 64)
        else ...[
          ..._materialInputs.map((material) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RealWeightInputCard(
                title: material.name,
                subRate: 'Rp ${_formatCurrency(material.ratePerKg)} / kg',
                weight: material.weight,
                ratePerKg: material.ratePerKg,
                isCustomerSelected: material.isCustomerSelected,
                onChanged: (val) {
                  setState(() {
                    material.weight = val;
                  });
                },
              ),
            );
          }),
        ],

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkNavy,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL BERAT TERKUMPUL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text('${_totalWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryYellow)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('TOTAL SALDO MASUK WARGA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text('Rp ${_formatCurrency(_totalPayout)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4ADE80))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bukti Foto Timbangan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _trashPhotos.isEmpty ? AppColors.primaryYellow.withValues(alpha: 0.35) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _trashPhotos.isEmpty ? 'Opsional (Disarankan)' : 'Tersimpan (${_trashPhotos.length} Foto)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _trashPhotos.isEmpty ? AppColors.darkNavy : AppColors.ecoGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: _takeTrashPhoto,
                child: Container(
                  width: 90,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkNavy.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: AppColors.darkNavy, size: 24),
                      SizedBox(height: 4),
                      Text('Ambil Foto\nBukti', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: AppColors.textSecondary, height: 1.1)),
                    ],
                  ),
                ),
              ),
              if (_trashPhotos.isNotEmpty) const SizedBox(width: 8),

              ..._trashPhotos.map((photo) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildPhotoThumbnailItem(photo),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3SetorTujuan() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _hasTargetMachine
                      ? 'Tujuan: $_targetDestinationName ($_targetMachineCode)'
                      : 'Tujuan: $_targetDestinationName',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _hasTargetMachine
                    ? 'Setorkan Muatan ke Smart Container'
                    : 'Serah Terima ke Mitra Bank Sampah',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
              ),
              const SizedBox(height: 4),
              Text(
                _hasTargetMachine
                    ? 'Masukkan sampah ke kompartemen $_targetMachineCode. Layar mesin akan menimbang dan mengonfirmasi transaksi otomatis dalam 1 tombol tanpa perlu aksi di HP.'
                    : 'Tunjukkan QR Handover ini kepada petugas Mitra Bank Sampah atau tekan tombol konfirmasi mitra di bawah.',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (_qrCodeHandover.isNotEmpty)
                      QrImageView(
                        data: _qrCodeHandover,
                        version: QrVersions.auto,
                        size: 160.0,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.darkNavy),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.darkNavy),
                      )
                    else
                      const Icon(Icons.qr_code_2_rounded, size: 160, color: AppColors.darkNavy),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tag_rounded, size: 12, color: AppColors.textMuted),
                        Text(
                          ' ${_qrCodeHandover.isNotEmpty ? _qrCodeHandover : "EC-JOB-${_jobId ?? "-"}"}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (_hasTargetMachine)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Menunggu konfirmasi layar Smart Container... Halaman ini otomatis selesai begitu mesin menekan tombol Konfirmasi.',
                          style: TextStyle(fontSize: 11, color: Colors.white, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Muatan Riil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
                        Text('${_totalWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ecoGreen)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _materialInputs
                          .where((m) => m.weight > 0)
                          .map((m) => _buildMiniMaterialChip(m.name.toUpperCase(), '${m.weight.toStringAsFixed(1)} kg'))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
],
    );
  }

  Widget _buildStep4Selesai() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 38,
          backgroundColor: AppColors.ecoGreen,
          child: Icon(Icons.check_rounded, size: 42, color: Colors.white),
        ),
        const SizedBox(height: 16),

        const Text('Pekerjaan Berhasil Diselesaikan!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
        const SizedBox(height: 4),
        Text(_displayPrice, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ecoGreen)),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Pekerjaan', _title),
              const Divider(height: 20),
              _buildSummaryRow('Nasabah', _customerName),
              const Divider(height: 20),
              _buildSummaryRow('Titik Setor', _targetDestinationName),
              const Divider(height: 20),
              _buildSummaryRow('Total Bobot Tervalidasi', '${_totalWeight.toStringAsFixed(1)} kg'),
              const Divider(height: 20),
              _buildSummaryRow('Saldo Diterima Warga', 'Rp ${_formatCurrency(_totalPayout)}'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/main'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepHeaderItem(int stepNumber, String title) {
    final bool isDone = _currentStep > stepNumber;
    final bool isActive = _currentStep == stepNumber;
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isDone
              ? AppColors.ecoGreen
              : (isActive ? AppColors.darkNavy : Colors.grey.shade300),
          child: isDone
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? AppColors.primaryYellow : Colors.grey.shade700,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive || isDone ? FontWeight.w800 : FontWeight.normal,
            color: isActive ? AppColors.darkNavy : (isDone ? AppColors.ecoGreen : Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildStepHeaderDivider(int stepNumber) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > stepNumber ? AppColors.ecoGreen : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }

  Widget _buildPhotoThumbnailItem(TrashPhotoItem photo) {
    Widget imageWidget;

    if (photo.bytes != null) {
      imageWidget = Image.memory(
        photo.bytes!,
        width: 90,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        ),
      );
    } else if (photo.path != null && photo.path!.isNotEmpty) {
      imageWidget = Image.network(
        photo.path!,
        width: 90,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        ),
      );
    } else {
      imageWidget = Container(color: Colors.grey.shade300);
    }

    return Container(
      width: 90,
      height: 80,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned.fill(child: imageWidget),
            const Positioned(top: 4, right: 4, child: Icon(Icons.check_circle_rounded, color: AppColors.ecoGreen, size: 16)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Text(
                  photo.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMaterialChip(String title, String weight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
          Text(weight, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
          ),
        ),
      ],
    );
  }
}

class _RealWeightInputCard extends StatefulWidget {
  final String title;
  final String subRate;
  final double weight;
  final double ratePerKg;
  final bool isCustomerSelected;
  final ValueChanged<double> onChanged;

  const _RealWeightInputCard({
    required this.title,
    required this.subRate,
    required this.weight,
    required this.ratePerKg,
    this.isCustomerSelected = false,
    required this.onChanged,
  });

  @override
  State<_RealWeightInputCard> createState() => _RealWeightInputCardState();
}

class _RealWeightInputCardState extends State<_RealWeightInputCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.weight.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _RealWeightInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weight != widget.weight) {
      final newStr = widget.weight.toStringAsFixed(1);
      if (_controller.text != newStr && double.tryParse(_controller.text) != widget.weight) {
        _controller.text = newStr;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateWeight(double newWeight) {
    final double clamped = newWeight.clamp(0.0, 999.0);
    _controller.text = clamped.toStringAsFixed(1);
    widget.onChanged(clamped);
  }

  String _formatCurrency(num amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalPayout = widget.weight * widget.ratePerKg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isCustomerSelected ? AppColors.ecoGreen : AppColors.cardBorder,
          width: widget.isCustomerSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.darkNavy),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isCustomerSelected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Pilihan Warga',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.ecoGreen),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text('@ ${widget.subRate}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ecoGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 105,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.darkNavy),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    suffixText: 'KG ',
                    suffixStyle: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                  onChanged: (val) {
                    final double? parsed = double.tryParse(val.replaceAll(',', '.'));
                    if (parsed != null) {
                      widget.onChanged(parsed.clamp(0.0, 999.0));
                    }
                  },
                ),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.darkNavy), onPressed: () => _updateWeight(widget.weight - 0.5)),
              IconButton(icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.darkNavy), onPressed: () => _updateWeight(widget.weight + 0.5)),
              ElevatedButton(
                onPressed: () => _updateWeight(widget.weight + 5.0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.primaryDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('+5kg', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Rp ${_formatCurrency(totalPayout)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ecoGreen)),
          ),
        ],
      ),
    );
  }
}
