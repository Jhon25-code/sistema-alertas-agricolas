import 'package:flutter/material.dart';

class IncidentTypeCard extends StatelessWidget {
  final String title;
  final String assetPath;
  final bool isSelected;
  final VoidCallback onTap;

  const IncidentTypeCard({
    Key? key,
    required this.title,
    required this.assetPath,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.04 : 1.0, // 🔹 zoom suave
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E88E5)
                  : Colors.grey.shade300,
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF1E88E5).withValues(alpha: 0.28)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              // 🖼️ Imagen protagonista (más ancha)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.asset(
                    assetPath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 📝 Texto
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
