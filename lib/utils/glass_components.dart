import 'dart:ui';
import 'package:flutter/material.dart';

class AuraTheme {
  // --- CORE COLORS ---
  static const Color kMidnightBlack = Color(0xFF050505);
  static const Color kDeepSpace = Color(0xFF0A0A12);
  static const Color kNeonCyan = Color(0xFF00FBFF);
  static const Color kElectricPurple = Color(0xFF8E2DE2);
  static const Color kHotPink = Color(0xFFF000FF);
  static const Color kAccentCyan = Color(0xFF00E5FF);
  
  // --- GLASS CONSTANTS ---
  static const double kBlurSigma = 25.0;
  static const double kBorderWidth = 0.8;
  static final Color kGlassBase = Colors.white.withValues(alpha: 0.05);
  static final Color kGlassBorder = Colors.white.withValues(alpha: 0.12);

  // --- GRADIENTS ---
  static LinearGradient auraGradient(Color auraColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        auraColor.withValues(alpha: 0.3),
        auraColor.withValues(alpha: 0.05),
        Colors.transparent,
      ],
    );
  }

  static const LinearGradient kCyberMesh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      kMidnightBlack,
      Color(0xFF0D0D1A),
      kMidnightBlack,
    ],
  );

  // --- TEXT STYLES ---
  static const TextStyle kHeadingDisplay = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: -1.0,
    fontFamily: 'Inter',
  );

  static const TextStyle kBodySubtle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFFB0B0B0),
    height: 1.5,
  );
}

// --- RADICAL GLASS CONTAINER ---
class AuraGlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool showGlow;
  final double? width;
  final double? height;

  const AuraGlassCard({
    super.key,
    required this.child,
    this.accentColor,
    this.borderRadius = 28,
    this.padding,
    this.margin,
    this.onTap,
    this.showGlow = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Premium Light Mode: Navbar ve kartlar için daha belirgin ayrım
    final Color glassColor = isDark 
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.07); // Hafif koyu tint (Glass Black)
        
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.05); // İnce koyu kenarlık

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        width: width,
        height: height,
        decoration: !isDark ? BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ) : null,
        child: Stack(
          children: [
            if (showGlow && accentColor != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor!.withValues(alpha: isDark ? 0.4 : 0.15),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Glass Effect
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AuraTheme.kBlurSigma, 
                  sigmaY: AuraTheme.kBlurSigma
                ),
                child: Container(
                  padding: padding ?? const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: glassColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: borderColor,
                      width: isDark ? AuraTheme.kBorderWidth : 1.0, 
                    ),
                    // Işık modunda gradient kaldırıldı, daha düz ve temiz cam
                    gradient: isDark ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ) : null,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- AURA SCAFFOLD ---
class AuraScaffold extends StatelessWidget {
  final Widget body;
  final Color? auraColor;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;

  const AuraScaffold({
    super.key,
    required this.body,
    this.auraColor,
    this.bottomNavigationBar,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        children: [
          // Background Decor (Clean Light Mode)
          if (!isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFAFAFA), // Pure White/Gray
                      Color(0xFFF3F4F6), // Soft Gray
                    ],
                  ),
                ),
              ),
            ),

          // Background Mesh (Only for Dark Mode)
          if (isDark)
            Positioned.fill(
              child: Container(decoration: const BoxDecoration(gradient: AuraTheme.kCyberMesh)),
            ),
          
          // Dynamic Aura Glow (Optimized for both modes)
          if (auraColor != null) ...[
            // Sağ Üst Orb
            Positioned(
              top: -150,
              right: -100,
              child: _AuraOrb(
                color: auraColor!, 
                size: 450, 
                opacity: isDark ? 0.25 : 0.15 // Işık modunda daha soft
              ),
            ),
            
            // Sol Orta Orb (Dinamik Blur Etkisi için)
            Positioned(
              top: 150,
              left: -150,
              child: _AuraOrb(
                color: isDark ? AuraTheme.kElectricPurple : AuraTheme.kAccentCyan.withValues(alpha: 0.4), 
                size: 400, 
                opacity: isDark ? 0.2 : 0.1
              ),
            ),
          ],
          
          // Sol Alt Orb
          Positioned(
            bottom: -120,
            left: -100,
            child: _AuraOrb(
              color: auraColor?.withValues(alpha: 0.5) ?? AuraTheme.kNeonCyan, 
              size: 350,
              opacity: isDark ? 0.25 : 0.15
            ),
          ),

          SafeArea(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _AuraOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _AuraOrb({required this.color, required this.size, this.opacity = 0.25});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// --- AURA GLASS TEXTFIELD ---
class AuraGlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData? icon;
  final TextInputType keyboardType;
  final int maxLines;

  const AuraGlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    
    // Modern Light Mode Design for TextField
    final Color fieldColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF3F4F6); // Açık modda solid gri (daha temiz görünüm)
        
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE5E7EB); // Açık modda belirgin gri kenarlık

    return Container(
      decoration: !isDark ? BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Işık modunda gölge kaldırıldı, flat tasarım
      ) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              gradient: isDark ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ) : null,
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: TextStyle(
                color: onSurface, 
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDark ? onSurface.withValues(alpha: 0.4) : const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: icon != null ? Icon(
                  icon, 
                  color: isDark ? onSurface.withValues(alpha: 0.6) : const Color(0xFF6B7280), 
                  size: 22
                ) : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuraSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;

  const AuraSearchField({
    super.key,
    required this.controller,
    this.hintText = "İlgi alanına göre ara...",
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<AuraSearchField> createState() => _AuraSearchFieldState();
}

class _AuraSearchFieldState extends State<AuraSearchField> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    final Color bgColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF3F4F6);
    final Color borderColor = isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFE5E7EB);
    final Color activeBorder = AuraTheme.kAccentCyan;
    final Color hintColor = isDark ? onSurface.withValues(alpha: 0.5) : const Color(0xFF9CA3AF);
    final Color iconColor = isDark ? onSurface.withValues(alpha: 0.7) : const Color(0xFF6B7280);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _hasFocus ? activeBorder : borderColor, width: _hasFocus ? 2 : 1.5),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        style: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 22),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: iconColor, size: 20),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call("");
                    widget.onClear?.call();
                    setState(() {});
                  },
                )
              : null,
          hintText: widget.hintText,
          hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        ),
      ),
    );
  }
}
