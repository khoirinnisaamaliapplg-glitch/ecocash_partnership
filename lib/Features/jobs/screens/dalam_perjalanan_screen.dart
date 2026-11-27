import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/job_socket_service.dart';

class DalamPerjalananScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const DalamPerjalananScreen({super.key, required this.jobData});

  @override
  State<DalamPerjalananScreen> createState() => _DalamPerjalananScreenState();
}

class _DalamPerjalananScreenState extends State<DalamPerjalananScreen> {
  final PartnerApiService _apiService = PartnerApiService();
  final JobSocketService _socketService = JobSocketService.instance;
  StreamSubscription<JobSocketEvent>? _socketSub;

  bool _isActionLoading = false;
  int _currentStep = 1; // 1: Kosongkan Smart Container, 2: Serah Terima Mitra Bank Sampah, 3: Selesai
  String _qrCodeHandover = '';
  double _pickedUpWeightKg = 0.0;
  int? _actualReward;
  int _pickedUpMaterialId = 1;
  Map<String, dynamic>? _latestJobDetail;

  Map get _effectiveJob {
    if (_latestJobDetail != null) return _latestJobDetail!;
    if (widget.jobData['rawJob'] is Map) {
      final raw = widget.jobData['rawJob'] as Map;
      if (raw['job'] is Map) return raw['job'] as Map;
      return raw;
    }
    if (widget.jobData['job'] is Map) {
      return widget.jobData['job'] as Map;
    }
    return widget.jobData;
  }

  Map? get _machine {
    if (widget.jobData['machine'] is Map) return widget.jobData['machine'] as Map;
    if (_effectiveJob['machine'] is Map) return _effectiveJob['machine'] as Map;
    return null;
  }

  dynamic get _jobId =>
      _effectiveJob['id'] ?? widget.jobData['jobId'] ?? widget.jobData['id'];

  int? get _binSlot {
    final rawSlot = widget.jobData['binSlot'] ?? _effectiveJob['binSlot'];
    if (rawSlot != null) return int.tryParse(rawSlot.toString());
    final desc = (_effectiveJob['description'] ?? '').toString();
    final match = RegExp(r'\[BIN_SLOT:(\d+)\]').firstMatch(desc);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  double get _jobWeightKg {
    if (_pickedUpWeightKg > 0) return _pickedUpWeightKg;

    final weights = _effectiveJob['weights'];
    if (weights is List && weights.isNotEmpty) {
      double total = 0.0;
      for (final w in weights) {
        if (w is Map) {
          total += double.tryParse((w['pickupWeight'] ?? '0').toString()) ?? 0.0;
        }
      }
      if (total > 0) return total;
    }

    final rawW = _effectiveJob['estimatedWeight'] ?? widget.jobData['estimatedWeight'];
    final parsed = double.tryParse((rawW ?? '').toString());
    if (parsed != null && parsed > 0) return parsed;

    final volStr = (widget.jobData['volume'] ?? _effectiveJob['volume'] ?? '').toString();
    final volMatch = RegExp(r'([\d.]+)').firstMatch(volStr.replaceAll(',', '.'));
    if (volMatch != null) {
      final v = double.tryParse(volMatch.group(1)!);
      if (v != null && v > 0) return v;
    }
    return 20.0;
  }

  LatLng get _destinationLocation {
    final double? lat = double.tryParse(
      (_machine?['latitude'] ?? _effectiveJob['latitude'] ?? widget.jobData['latitude'] ?? '').toString(),
    );
    final double? lng = double.tryParse(
      (_machine?['longitude'] ?? _effectiveJob['longitude'] ?? widget.jobData['longitude'] ?? '').toString(),
    );
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(-6.9200, 107.6350);
  }

  @override
  void initState() {
    super.initState();
    _initJobSocket();
    _bootstrapContainerFlow();
  }

  @override
  void dispose() {
    if (_jobId != null) {
      _socketService.leaveJobRoom(_jobId);
    }
    _socketSub?.cancel();
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
        final String status = (event.payload['status'] ?? '').toString().toUpperCase();
        if (status == 'COMPLETED' && _currentStep != 3) {
          setState(() => _currentStep = 3);
        }
      }
    });
  }

  Future<void> _bootstrapContainerFlow() async {
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

    final weights = _effectiveJob['weights'];
    if (weights is List && weights.isNotEmpty && weights.first is Map) {
      final first = weights.first as Map;
      final mId = int.tryParse((first['materialId'] ?? '').toString());
      final pw = double.tryParse((first['pickupWeight'] ?? '0').toString()) ?? 0.0;
      if (mId != null && mId > 0) _pickedUpMaterialId = mId;
      if (pw > 0) _pickedUpWeightKg = pw;
    }

    final String status = (_effectiveJob['status'] ?? widget.jobData['status'] ?? 'ACCEPTED')
        .toString()
        .toUpperCase();

    if (status == 'COMPLETED') {
      if (mounted) setState(() => _currentStep = 3);
      return;
    }

    if (status == 'PICKUP' || status == 'IN_TRANSIT' || status == 'HANDOVER') {
      if (_pickedUpWeightKg <= 0) {
        _pickedUpWeightKg = _jobWeightKg;
      }
      if (mounted) setState(() => _currentStep = 2);
      await _ensureHandoverQr();
      return;
    }

    if (_jobId != null && (status == 'ACCEPTED' || status == 'AVAILABLE')) {
      await _apiService.startRoute(_jobId);
    }
  }

  Future<void> _ensureHandoverQr() async {
    if (_jobId == null) return;
    final res = await _apiService.generateHandoverQr(_jobId);
    if (!mounted) return;
    setState(() {
      _qrCodeHandover = (res['data']?['qrCode'] ?? 'EC-JOB-$_jobId').toString();
    });
  }

  Future<int> _resolveTargetMaterialId() async {
    try {
      final String desc = (_effectiveJob['description'] ?? '').toString();
      final wtMatch = RegExp(r'\[WASTE_TYPES:([\d,]+)\]').firstMatch(desc);
      final int? targetWtId = wtMatch != null
          ? int.tryParse(wtMatch.group(1)!.split(',').first.trim())
          : null;

      final res = await _apiService.getMaterials();
      if (res['success'] == true && res['data'] is List) {
        final list = res['data'] as List;
        if (targetWtId != null) {
          final found = list.where((m) =>
              int.tryParse((m['wasteTypeId'] ?? m['wasteType']?['id'] ?? '').toString()) == targetWtId);
          if (found.isNotEmpty) {
            return int.tryParse(found.first['id'].toString()) ?? 1;
          }
        }
        if (list.isNotEmpty) {
          return int.tryParse(list.first['id'].toString()) ?? 1;
        }
      }
    } catch (_) {}
    return 1;
  }

  void _showEmptyingDialog(double availableWeight) {
    const double vehicleLimit = 150.0;
    final double maxTake = (availableWeight < vehicleLimit ? availableWeight : vehicleLimit).clamp(1.0, 500.0);
    double selectedWeight = maxTake;
    final int? slot = _binSlot;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final int estReward = 35000 + (selectedWeight * 2000).round();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot != null
                        ? 'Konfirmasi Pengosongan Box #$slot'
                        : 'Konfirmasi Pengosongan Kontainer',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Berat di ${slot != null ? "kompartemen Box #$slot" : "mesin"}: ${availableWeight.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
                      ),
                      Text(
                        'Komisi: Rp ${estReward.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ecoGreen),
                      ),
                    ],
                  ),
                  if (maxTake > 1.0)
                    Slider(
                      value: selectedWeight.clamp(1.0, maxTake),
                      min: 1.0,
                      max: maxTake,
                      activeColor: AppColors.ecoGreen,
                      onChanged: (val) {
                        setModalState(() => selectedWeight = double.parse(val.toStringAsFixed(1)));
                      },
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _processEmptyingPickup(selectedWeight);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        slot != null
                            ? 'Buka Box #$slot & Muat Sampah'
                            : 'Buka Kompartemen & Muat Sampah',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processEmptyingPickup(double takenWeight) async {
    setState(() => _isActionLoading = true);
    try {
      final int materialId = await _resolveTargetMaterialId();
      final int? slot = _binSlot;
      final res = await _apiService.submitPickup(
        _jobId,
        materials: [
          {'materialId': materialId, 'pickupWeight': takenWeight}
        ],
        notes: slot != null
            ? 'Muatan Box #$slot berhasil diangkut ke armada'
            : 'Muatan kontainer berhasil diangkut ke armada',
      );

      if (!mounted) return;

      if (res['success'] == true) {
        _pickedUpWeightKg = takenWeight;
        _pickedUpMaterialId = materialId;
        if (res['data'] is Map) {
          final d = res['data'] as Map;
          _latestJobDetail = Map<String, dynamic>.from(d['job'] is Map ? d['job'] as Map : d);
        }
        await _ensureHandoverQr();

        if (!mounted) return;
        setState(() {
          _isActionLoading = false;
          _currentStep = 2;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              slot != null
                  ? 'Muatan Box #$slot (${takenWeight.toStringAsFixed(1)} kg) dimuat! Lanjut setor ke Mitra Bank Sampah.'
                  : 'Muatan ${takenWeight.toStringAsFixed(1)} kg dimuat! Lanjut setor ke Mitra Bank Sampah.',
            ),
            backgroundColor: AppColors.ecoGreen,
          ),
        );
      } else {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal mencatat muatan kontainer'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleCheckIn() async {
    if (_jobId == null) {
      context.push('/scan', extra: widget.jobData);
      return;
    }

    setState(() => _isActionLoading = true);
    final res = await _apiService.checkIn(_jobId);
    setState(() => _isActionLoading = false);

    if (!mounted) return;

    if (res['success'] == true || res['status'] == 'CHECKED_IN') {
      final int? slot = _binSlot;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            slot != null
                ? 'Tiba di Smart Container! Kompartemen Box #$slot siap dibuka.'
                : 'Tiba di lokasi Smart Container! Pintu siap dibuka.',
          ),
          backgroundColor: AppColors.ecoGreen,
        ),
      );
      _showEmptyingDialog(_jobWeightKg);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal melakukan check-in'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleBankSampahHandover() async {
    if (_jobId == null) return;
    setState(() => _isActionLoading = true);

    try {
      final int? slot = _binSlot;
      final double weightToHandover = _pickedUpWeightKg > 0 ? _pickedUpWeightKg : _jobWeightKg;
      final int matId = _pickedUpMaterialId > 0 ? _pickedUpMaterialId : await _resolveTargetMaterialId();

      final res = await _apiService.verifyHandover(
        _jobId,
        qrCode: _qrCodeHandover.isNotEmpty ? _qrCodeHandover : 'EC-JOB-$_jobId',
        materials: [
          {
            'materialId': matId,
            'handoverWeight': weightToHandover,
          }
        ],
        notes: slot != null
            ? 'Serah terima muatan Box #$slot ke Mitra Bank Sampah'
            : 'Serah terima muatan Smart Container ke Mitra Bank Sampah',
      );

      if (!mounted) return;
      setState(() => _isActionLoading = false);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              slot != null
                  ? 'Serah terima ke Mitra Bank Sampah berhasil! Kapasitas Box #$slot telah di-reset.'
                  : 'Serah terima ke Mitra Bank Sampah berhasil! Kapasitas kontainer telah di-reset.',
            ),
            backgroundColor: AppColors.ecoGreen,
          ),
        );
        final dynamic rawReward = res['data']?['collectorSettlement']?['totalEarning'] ?? res['data']?['job']?['estimatedReward'] ?? res['data']?['actualReward'] ?? res['data']?['reward'];
        final int? parsedReward = rawReward != null ? double.tryParse(rawReward.toString())?.round() : null;
        setState(() {
          if (parsedReward != null && parsedReward > 0) _actualReward = parsedReward;
          _currentStep = 3;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memverifikasi serah terima ke Mitra Bank Sampah'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String machineName =
        (widget.jobData['title'] ?? _effectiveJob['title'] ?? _machine?['name'] ?? 'Smart Container').toString();
    final String address = (widget.jobData['address'] ??
            _effectiveJob['address'] ??
            _machine?['address'] ??
            _machine?['placeName'] ??
            'Lokasi Mesin')
        .toString();
    final String descCat = RegExp(r'\[CATEGORY:([^\]]+)\]').firstMatch((_effectiveJob['description'] ?? '').toString())?.group(1)?.trim() ?? '';
    final String material = (widget.jobData['materialTag'] ?? _effectiveJob['materialTag'] ?? (descCat.isNotEmpty ? descCat : 'Kontainer Penuh')).toString();
    final String volume =
        (widget.jobData['volume'] ?? _effectiveJob['volume'] ?? '${_jobWeightKg.toStringAsFixed(1)} kg').toString();
    final int? slot = _binSlot;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _currentStep == 2
              ? 'Setor ke Mitra Bank Sampah'
              : (slot != null ? 'Pengosongan Box #$slot' : 'Menuju Smart Container'),
          style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ValueListenableBuilder<bool>(
              valueListenable: _socketService.connectionNotifier,
              builder: (_, connected, _) {
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
      body: _currentStep == 1
          ? _buildStep1ContainerPickup(machineName, address, material, volume, slot)
          : (_currentStep == 2
              ? _buildStep2BankSampahHandover(machineName, material, slot)
              : _buildStep3Completed(machineName, material, slot)),
    );
  }

  Widget _buildStep1ContainerPickup(
    String machineName,
    String address,
    String material,
    String volume,
    int? slot,
  ) {
    final LatLng destinationLocation = _destinationLocation;
    final LatLng startLocation = LatLng(
      destinationLocation.latitude - 0.0045,
      destinationLocation.longitude - 0.0045,
    );

    final List<LatLng> routePoints = [
      startLocation,
      LatLng(startLocation.latitude + 0.0022, startLocation.longitude + 0.0010),
      LatLng(destinationLocation.latitude - 0.0015, destinationLocation.longitude - 0.0020),
      destinationLocation,
    ];

    return Stack(
      children: [
        Positioned.fill(
          bottom: 250,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: destinationLocation,
              initialZoom: 14.8,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecocash_partnership',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(points: routePoints, strokeWidth: 4.5, color: AppColors.darkNavy),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: startLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.local_shipping_rounded, color: AppColors.darkNavy, size: 36),
                  ),
                  Marker(
                    point: destinationLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin, color: AppColors.error, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                if (slot != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TAHAP 1/2 • KOMPARTEMEN TARGET: BOX #$slot',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
                    ),
                  ),
                ],
                Text(machineName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
                const SizedBox(height: 2),
                Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.recycling_rounded, color: AppColors.ecoGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot != null ? 'Kompartemen & Material' : 'Material Mesin',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    material,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.darkNavy),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Estimasi Muatan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(volume, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.ecoGreen)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isActionLoading ? null : _handleCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isActionLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2))
                        : Text(
                            slot != null ? 'Sampai di Mesin & Buka Box #$slot' : 'Sampai di Mesin & Buka Kontainer',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2BankSampahHandover(String machineName, String material, int? slot) {
    final double weight = _pickedUpWeightKg > 0 ? _pickedUpWeightKg : _jobWeightKg;
    final dynamic backendReward = _actualReward ?? _effectiveJob['actualReward'] ?? _effectiveJob['estimatedReward'];
    final int estReward = (backendReward != null && (double.tryParse(backendReward.toString()) ?? 0) > 0)
        ? double.parse(backendReward.toString()).round()
        : (35000 + (weight * 2000).round());
    final String formattedReward = estReward.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkNavy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store_mall_directory_rounded, color: AppColors.primaryYellow, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAHAP 2/2 • TUJUAN PENYETORAN',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryYellow),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mitra Bank Sampah / Pengepul EcoCash',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                const Text(
                  'Serah Terima Muatan Kontainer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  slot != null
                      ? 'Tunjukkan QR Handover ini ke petugas Mitra Bank Sampah untuk menyetor muatan Box #$slot dan mereset kapasitas kompartemen.'
                      : 'Tunjukkan QR Handover ini ke petugas Mitra Bank Sampah untuk menyetor muatan kontainer.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
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
                          size: 165,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.darkNavy),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.darkNavy),
                        )
                      else
                        const Icon(Icons.qr_code_2_rounded, size: 165, color: AppColors.darkNavy),
                      const SizedBox(height: 8),
                      Text(
                        _qrCodeHandover.isNotEmpty ? _qrCodeHandover : 'EC-JOB-${_jobId ?? "-"}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.darkNavy),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Asal Mesin', machineName),
                      const Divider(height: 16),
                      _buildInfoRow('Kompartemen & Material', slot != null ? 'Box #$slot ($material)' : material),
                      const Divider(height: 16),
                      _buildInfoRow('Total Muatan Diangkut', '${weight.toStringAsFixed(1)} kg'),
                      const Divider(height: 16),
                      _buildInfoRow('Estimasi Komisi Mitra', 'Rp $formattedReward', valueColor: AppColors.ecoGreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isActionLoading ? null : _handleBankSampahHandover,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ecoGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isActionLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Konfirmasi Serah Terima ke Mitra Bank Sampah',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Completed(String machineName, String material, int? slot) {
    final double weight = _pickedUpWeightKg > 0 ? _pickedUpWeightKg : _jobWeightKg;
    final dynamic backendReward = _actualReward ?? _effectiveJob['actualReward'] ?? _effectiveJob['estimatedReward'];
    final int estReward = (backendReward != null && (double.tryParse(backendReward.toString()) ?? 0) > 0)
        ? double.parse(backendReward.toString()).round()
        : (35000 + (weight * 2000).round());
    final String formattedReward = estReward.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.ecoGreen,
            child: Icon(Icons.check_rounded, size: 42, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pengosongan & Penyetoran Selesai!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Rp $formattedReward',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ecoGreen),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildInfoRow('Mesin Asal', machineName),
                const Divider(height: 18),
                _buildInfoRow('Kompartemen Di-reset', slot != null ? 'Box #$slot ($material)' : material),
                const Divider(height: 18),
                _buildInfoRow('Titik Penyetoran', 'Mitra Bank Sampah EcoCash'),
                const Divider(height: 18),
                _buildInfoRow('Bobot Disetor', '${weight.toStringAsFixed(1)} kg'),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.darkNavy,
            ),
          ),
        ),
      ],
    );
  }
}
