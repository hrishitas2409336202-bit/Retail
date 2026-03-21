import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'invoice_screen.dart';
import 'invoice_pdf_screen.dart';
import '../../services/ai_service.dart';

/// [returnProduct] – true when launched from Billing (returns a Product on pop)
/// When false (launched from Dashboard), it shows a product info sheet instead.
class BarcodeScannerScreen extends StatefulWidget {
  final bool returnProduct;
  const BarcodeScannerScreen({super.key, this.returnProduct = false});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with TickerProviderStateMixin {
  bool _isScanCompleted = false;
  bool _torchEnabled = false;
  bool _frontCamera = false;
  bool _isProcessing = false;
  late MobileScannerController _scannerController;
  late AnimationController _lineAnimController;
  late Animation<double> _lineAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: BarcodeFormat.values,
    );

    _lineAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _lineAnimController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _lineAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isScanCompleted || _isProcessing) return;
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final code = barcode.rawValue;
                if (code != null) {
                  debugPrint("SCANNER: Detected code [$code]");
                  setState(() {
                    _isScanCompleted = true;
                    _isProcessing = true;
                  });
                  HapticFeedback.mediumImpact();
                  _processScannedCode(context, code);
                  break;
                }
              }
            },
          ),

          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                const Spacer(),
                _buildScanFrame(),
                const SizedBox(height: 20),
                _buildHintText(),
                const Spacer(flex: 2),
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Analyzing...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else if (_isScanCompleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() {
                        _isScanCompleted = false;
                        _isProcessing = false;
                      }),
                      icon: const Icon(LucideIcons.refreshCcw, size: 16),
                      label: const Text('Scan Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                if (!_isScanCompleted && !_isProcessing)
                  TextButton.icon(
                    onPressed: () => _showManualEntryDialog(context),
                    icon: const Icon(
                      LucideIcons.keyboard,
                      color: Colors.white70,
                      size: 16,
                    ),
                    label: const Text(
                      'Type Barcode Manually',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                const SizedBox(height: 10),
                _buildBottomControls(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _glassButton(
            child: const Icon(
              LucideIcons.arrowLeft,
              color: Colors.white,
              size: 20,
            ),
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.returnProduct
                  ? '🛒 Scan to Add to Bill'
                  : '🔍 AI Product Scanner',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _glassButton(
            child: Icon(
              _torchEnabled ? LucideIcons.sun : LucideIcons.flashlight,
              color: _torchEnabled ? Colors.amber : Colors.white,
              size: 20,
            ),
            onTap: () {
              setState(() => _torchEnabled = !_torchEnabled);
              _scannerController.toggleTorch();
            },
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildScanFrame() {
    const frameSize = 260.0;
    const cornerSize = 28.0;
    const cornerThickness = 4.0;
    final cornerColor = AppTheme.primary;

    return ScaleTransition(
      scale: _pulseAnim,
      child: SizedBox(
        width: frameSize,
        height: frameSize,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: _corner(cornerColor, cornerSize, cornerThickness, [
                true,
                false,
                false,
                true,
              ]),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _corner(cornerColor, cornerSize, cornerThickness, [
                true,
                true,
                false,
                false,
              ]),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: _corner(cornerColor, cornerSize, cornerThickness, [
                false,
                false,
                true,
                true,
              ]),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: _corner(cornerColor, cornerSize, cornerThickness, [
                false,
                true,
                true,
                false,
              ]),
            ),

            AnimatedBuilder(
              animation: _lineAnim,
              builder: (context, _) {
                return Positioned(
                  top: _lineAnim.value * (frameSize - 4),
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.primary.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(Color color, double size, double thickness, List<bool> sides) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: sides[0]
              ? BorderSide(color: color, width: thickness)
              : BorderSide.none,
          right: sides[1]
              ? BorderSide(color: color, width: thickness)
              : BorderSide.none,
          bottom: sides[2]
              ? BorderSide(color: color, width: thickness)
              : BorderSide.none,
          left: sides[3]
              ? BorderSide(color: color, width: thickness)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: sides[0] && sides[3]
              ? const Radius.circular(6)
              : Radius.zero,
          topRight: sides[0] && sides[1]
              ? const Radius.circular(6)
              : Radius.zero,
          bottomRight: sides[2] && sides[1]
              ? const Radius.circular(6)
              : Radius.zero,
          bottomLeft: sides[2] && sides[3]
              ? const Radius.circular(6)
              : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildHintText() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.sparkles,
                color: Colors.blueAccent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                widget.returnProduct
                    ? 'Scan product to add to checkout'
                    : 'OpenFood AI will identify & add to inventory',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showManualEntryDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.keyboard, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Enter Code',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _glassButton(
            child: const Icon(
              LucideIcons.refreshCw,
              color: Colors.white,
              size: 20,
            ),
            onTap: () {
              _scannerController.switchCamera();
              setState(() => _frontCamera = !_frontCamera);
            },
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Enter Barcode',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter barcode number...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() {
                  _isScanCompleted = true;
                  _isProcessing = true;
                });
                _processScannedCode(context, code);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  // ─── Core scanning logic ────────────────────────────────────────────────────
  Future<void> _processScannedCode(BuildContext context, String code) async {
    final String cleanCode = code.trim();
    debugPrint("SCANNER: Processing code [$cleanCode]");
    final state = context.read<AppState>();
    state.updateLastScan(cleanCode);

    // 1. Receipt / Invoice QR
    if (cleanCode.startsWith('VERIFY:') ||
        cleanCode.startsWith('RCV2|') ||
        cleanCode.startsWith('RIQ:') ||
        cleanCode.contains('rq.link/v?d=') ||
        cleanCode.contains('verify?d=')) {
      Sale? sale;
      if (cleanCode.startsWith('VERIFY:')) {
        final parts = cleanCode.split(':');
        if (parts.length >= 2) sale = state.getSaleById(parts[1]);
      } else {
        sale = Sale.fromCompactCode(cleanCode);
      }
      if (mounted) setState(() => _isProcessing = false);
      if (sale != null) {
        _showVerificationResult(context, sale);
        return;
      }
    }

    // 2. UPI Payment QR
    if (cleanCode.startsWith('upi://')) {
      if (mounted) setState(() => _isProcessing = false);
      _showInfoSheet(
        context,
        LucideIcons.alertCircle,
        Colors.orangeAccent,
        'Payment QR Detected',
        'This is a payment QR code — not a product or receipt.\nPlease scan a product barcode or a bill QR code.',
      );
      return;
    }

    // 3. Product lookup in local inventory
    final product = state.findProductById(cleanCode);
    debugPrint(
      "SCANNER: Local lookup for [$cleanCode] result: ${product?.name ?? 'NOT FOUND'}",
    );

    if (product != null) {
      if (mounted) setState(() => _isProcessing = false);
      if (widget.returnProduct) {
        // Pop scanner and return product to billing screen
        if (mounted) Navigator.pop(context, product);
      } else {
        _showProductInfoSheet(context, product, state);
      }
    } else {
      // UNKNOWN BARCODE -> ASK GEMINI
      debugPrint("SCANNER: Calling Gemini AI for unknown barcode [$cleanCode]");
      // Show loading in the scanner itself (not a sheet), already handled by _isProcessing

      try {
        final geminiResult = await AIService.getProductFromBarcode(cleanCode);

        if (!mounted) return;

        if (geminiResult != null) {
          debugPrint("SCANNER: Gemini identified: ${geminiResult['name']}");

          if (mounted) {
            setState(() => _isProcessing = false);
            _showAIConfirmationSheet(context, geminiResult, cleanCode, state);
          }
        } else {
          debugPrint("SCANNER: Gemini failed, showing manual dialog");
          if (mounted) {
            setState(() => _isProcessing = false);
            _showQuickAddProductDialog(context, cleanCode);
          }
        }
      } catch (e) {
        debugPrint("SCANNER: Error during AI identification: $e");
        if (mounted) {
          setState(() => _isProcessing = false);
          _showQuickAddProductDialog(context, cleanCode);
        }
      }
    }
  }

  void _showAIConfirmationSheet(
    BuildContext context,
    Map<String, dynamic> result,
    String code,
    AppState state,
  ) {
    String name = result['name']?.toString() ?? 'Unknown Product';
    String category = result['category']?.toString() ?? 'Uncategorized';
    double price =
        (result['price'] is num
                ? result['price']
                : double.tryParse(result['price']?.toString() ?? '0') ?? 0.0)
            .toDouble();
    String emoji = result['emoji']?.toString() ?? '📦';
    String unit = result['unit']?.toString() ?? 'grams';
    String mfgDate = result['mfgDate']?.toString() ?? '';
    String expires = result['expires']?.toString() ?? '';
    int stock = 100;
    String shelf = result['shelf']?.toString() ?? 'A-01';
    String description = result['description']?.toString() ?? '';

    // Controllers
    final nameCtrl = TextEditingController(text: name);
    final unitCtrl = TextEditingController(text: unit);
    final stockCtrl = TextEditingController(text: stock.toString());
    final shelfCtrl = TextEditingController(text: shelf);
    final mfgCtrl = TextEditingController(text: mfgDate);
    final expCtrl = TextEditingController(text: expires);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            28,
            16,
            28,
            MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // AI Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.2),
                        Colors.purpleAccent.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        color: Colors.blueAccent,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AI PRODUCT IDENTIFICATION',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),

                // Editable Name
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 32),

                // Fields Grid
                Row(
                  children: [
                    Expanded(
                      child: _editField(
                        'Weight/Unit',
                        unitCtrl,
                        LucideIcons.scale,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _editField(
                        'Stock',
                        stockCtrl,
                        LucideIcons.package,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _editField(
                        'Shelf No',
                        shelfCtrl,
                        LucideIcons.layers,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _editField(
                        'Price',
                        TextEditingController(text: price.toString()),
                        LucideIcons.indianRupee,
                        isNumber: true,
                        enabled: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MFG DATE',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: mfgCtrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                LucideIcons.calendar,
                                size: 14,
                                color: Colors.blueAccent,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXPIRY DATE',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: expCtrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                LucideIcons.calendar,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'REJECT SCAN',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newProduct = Product(
                            id: code,
                            name: nameCtrl.text,
                            category: category,
                            price: price,
                            stock: int.tryParse(stockCtrl.text) ?? 100,
                            threshold: 10,
                            supplierId: 'SUP001',
                            unit: unitCtrl.text,
                            shelf: shelfCtrl.text,
                            mfgDate: mfgCtrl.text,
                            expires: expCtrl.text,
                            emoji: emoji,
                            description: description,
                            barcode: code,
                          );
                          state.addProduct(newProduct);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${nameCtrl.text} added to inventory',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'ACCEPT & ADD',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool isNumber = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: Colors.blueAccent),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ─── New Product Added Sheet (dashboard mode) ────────────────────────────
  void _showNewProductAddedSheet(
    BuildContext context,
    Product product,
    AppState state,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // AI Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    color: Colors.blueAccent,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Gemini AI Identified & Added',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(product.emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              product.category,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _infoTile(
                  'Price',
                  '${state.currency}${product.price.toInt()}',
                  LucideIcons.tag,
                  Colors.blueAccent,
                ),
                const SizedBox(width: 10),
                _infoTile(
                  'Stock',
                  '${product.stock}',
                  LucideIcons.package,
                  Colors.greenAccent,
                ),
                const SizedBox(width: 10),
                _infoTile(
                  'Shelf',
                  product.shelf,
                  LucideIcons.mapPin,
                  Colors.purpleAccent,
                ),
              ],
            ),
            if (product.description != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  product.description!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _isScanCompleted = false;
                        _isProcessing = false;
                      });
                    },
                    icon: const Icon(LucideIcons.scan, size: 16),
                    label: const Text('Scan Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((_) {
      if (mounted)
        setState(() {
          _isScanCompleted = false;
          _isProcessing = false;
        });
    });
  }

  // ─── Product Info Sheet (dashboard mode) ────────────────────────────────
  void _showProductInfoSheet(
    BuildContext context,
    Product product,
    AppState state,
  ) {
    final stockStatus = product.stock == 0
        ? 'Out of Stock'
        : product.stock <= product.threshold
        ? 'Low Stock'
        : 'In Stock';
    final stockColor = product.stock == 0
        ? Colors.redAccent
        : product.stock <= product.threshold
        ? Colors.orangeAccent
        : Colors.greenAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(product.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              product.category,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                _infoTile(
                  'Price',
                  '${state.currency}${product.price.toInt()}',
                  LucideIcons.tag,
                  Colors.blueAccent,
                ),
                const SizedBox(width: 10),
                _infoTile(
                  'Stock',
                  '${product.stock} units',
                  LucideIcons.package,
                  stockColor,
                ),
                const SizedBox(width: 10),
                _infoTile(
                  'Shelf',
                  product.shelf,
                  LucideIcons.mapPin,
                  Colors.purpleAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: stockColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.activity, color: stockColor, size: 16),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              stockStatus,
                              style: TextStyle(
                                color: stockColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (product.expires != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            color: Colors.orangeAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expires',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                product.expires ?? '-',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.hash,
                    color: Colors.white.withOpacity(0.3),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID: ${product.id}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _isScanCompleted = false;
                        _isProcessing = false;
                      });
                    },
                    icon: const Icon(LucideIcons.scan, size: 16),
                    label: const Text('Scan Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((_) {
      if (mounted)
        setState(() {
          _isScanCompleted = false;
          _isProcessing = false;
        });
    });
  }

  void _resetScanner() {
    if (mounted) {
      setState(() {
        _isScanCompleted = false;
        _isProcessing = false;
      });
    }
  }

  Widget _infoTile(
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 16),
                  if (onTap != null)
                    Icon(
                      LucideIcons.edit3,
                      color: color.withOpacity(0.4),
                      size: 12,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Receipt Verification Sheet ─────────────────────────────────────────
  void _showVerificationResult(BuildContext context, Sale sale) {
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              LucideIcons.checkCircle,
              color: Colors.greenAccent,
              size: 60,
            ),
            const SizedBox(height: 12),
            const Text(
              'Receipt Verified ✓',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Bill: ${sale.id}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  const Text(
                    'ITEMS',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...sale.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${item.qty}',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${state.currency}${(item.qty * item.price).toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 28),
                  _row(
                    'Subtotal',
                    '${state.currency}${(sale.total / (1 + state.taxRate / 100)).toInt()}',
                  ),
                  const SizedBox(height: 6),
                  _row(
                    'Tax (${state.taxRate.toInt()}%)',
                    '${state.currency}${(sale.total - sale.total / (1 + state.taxRate / 100)).toInt()}',
                  ),
                  const SizedBox(height: 10),
                  _row(
                    'Total Paid',
                    '${state.currency}${sale.total.toInt()}',
                    bold: true,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 10),
                  _row('Method', sale.paymentMethod),
                  const SizedBox(height: 6),
                  _row(
                    'Date',
                    DateFormat('dd MMM yyyy, hh:mm a').format(sale.date),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => InvoicePdfScreen(
                      sale: sale,
                      storeName: state.storeName,
                      currency: state.currency,
                      taxRate: state.taxRate,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'OPEN PDF INVOICE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => InvoiceScreen(sale: sale)),
                );
              },
              child: const Text(
                'VIEW DIGITAL RECEIPT',
                style: TextStyle(color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted)
        setState(() {
          _isScanCompleted = false;
          _isProcessing = false;
        });
    });
  }

  double get taxRate => context.read<AppState>().taxRate;

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 18 : 14,
          ),
        ),
      ],
    );
  }

  // ─── Generic Info / Error Sheet ──────────────────────────────────────────
  void _showInfoSheet(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String message,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _isScanCompleted = false;
                  _isProcessing = false;
                });
              },
              icon: const Icon(LucideIcons.scan, size: 16),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Quick Add Product Dialog ──────────────────────────────────────────
  void _showQuickAddProductDialog(
    BuildContext context,
    String barcode, {
    Map<String, dynamic>? prefilled,
  }) {
    final _scState = this;
    final nameController = TextEditingController(
      text: prefilled?['name']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: prefilled?['price']?.toString() ?? '',
    );
    final state = context.read<AppState>();
    final bool isReturnMode = widget.returnProduct;
    String? mfgDate = prefilled?['mfgDate']?.toString();
    String? expDate = prefilled?['expires']?.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickMfg() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: DateTime.now().subtract(const Duration(days: 30)),
              firstDate: DateTime(2015),
              lastDate: DateTime.now(),
              builder: (c, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF6C63FF),
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null)
              setSheetState(
                () => mfgDate = picked.toIso8601String().split('T').first,
              );
          }

          Future<void> pickExp() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              builder: (c, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF10B981),
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null)
              setSheetState(
                () => expDate = picked.toIso8601String().split('T').first,
              );
          }

          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6C63FF,
                              ).withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.packagePlus,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Product',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Barcode: $barcode',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Product Name
                  _premiumField(
                    controller: nameController,
                    label: 'Product Name *',
                    icon: LucideIcons.tag,
                    autofocus: true,
                  ),
                  const SizedBox(height: 14),

                  // Price
                  _premiumField(
                    controller: priceController,
                    label: 'Price (${state.currency}) *',
                    icon: LucideIcons.indianRupee,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),

                  // Date row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: pickMfg,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.calendarDays,
                                      color: Colors.greenAccent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'MFG Date',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mfgDate ?? 'Tap to set',
                                  style: TextStyle(
                                    color: mfgDate != null
                                        ? Colors.greenAccent
                                        : Colors.white24,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: pickExp,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.clock,
                                      color: Colors.redAccent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Expiry',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  expDate ?? 'Tap to set',
                                  style: TextStyle(
                                    color: expDate != null
                                        ? Colors.redAccent
                                        : Colors.white24,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _scState._resetScanner();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () async {
                            if (nameController.text.isEmpty ||
                                priceController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Name and price are required!'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            final price =
                                double.tryParse(priceController.text) ?? 10.0;
                            final cleanedId = barcode.replaceAll(
                              RegExp(r'[^a-zA-Z0-9]'),
                              '',
                            );
                            final newProduct = Product(
                              id: 'GEN-${cleanedId.substring(0, cleanedId.length > 10 ? 10 : cleanedId.length)}',
                              name: nameController.text,
                              category:
                                  prefilled?['category']?.toString() ??
                                  'Uncategorized',
                              price: price,
                              stock: 100,
                              threshold: 20,
                              emoji: prefilled?['emoji']?.toString() ?? '📦',
                              shelf: prefilled?['shelf']?.toString() ?? 'A1',
                              unit: prefilled?['unit']?.toString(),
                              description: prefilled?['description']
                                  ?.toString(),
                              imageUrl: prefilled?['imageUrl']?.toString(),
                              supplierId: 'SUP001',
                              barcode: barcode,
                              mfgDate: mfgDate,
                              expires: expDate,
                            );
                            await state.addProduct(newProduct);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              if (isReturnMode) {
                                Navigator.pop(context, newProduct);
                              } else {
                                _showProductInfoSheet(
                                  context,
                                  newProduct,
                                  state,
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF10B981)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add & Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _premiumField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
          ),
        ),
      ),
    );
  }
}
