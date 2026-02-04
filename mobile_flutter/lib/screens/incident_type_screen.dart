import 'package:flutter/material.dart';
import 'package:siaas/widgets/incident_type_card.dart';
// 1. IMPORTAR LA LIBRERÍA DE VIBRACIÓN
import 'package:vibration/vibration.dart';

class IncidentTypeScreen extends StatefulWidget {
  const IncidentTypeScreen({super.key});

  @override
  State<IncidentTypeScreen> createState() => _IncidentTypeScreenState();
}

class _IncidentTypeScreenState extends State<IncidentTypeScreen> {
  final List<Map<String, String>> types = const [
    {'id': 'picadura_abeja', 'label': 'Picadura', 'asset': 'assets/icons/icons_bee.png'},
    {'id': 'corte', 'label': 'Corte', 'asset': 'assets/icons/icons_cut.png'},
    {'id': 'insolacion', 'label': 'Insolación', 'asset': 'assets/icons/icons_sun.png'},
    {'id': 'intoxicacion', 'label': 'Intoxicación', 'asset': 'assets/icons/icons_skull.png'},
    {'id': 'caida', 'label': 'Caída', 'asset': 'assets/icons/icons_fall.png'},
    {'id': 'otro', 'label': 'Otros', 'asset': 'assets/icons/icons_other.png'},
  ];

  String? selected;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final crossAxisCount = isTablet ? 3 : 2;
    final childAspectRatio = isTablet ? 1.0 : 0.92;
    final spacing = isTablet ? 18.0 : 16.0;

    final bool isEnabled = selected != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        centerTitle: true,
        title: const Text(
          'TIPO DE INCIDENTE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: types.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final t = types[index];
                    final id = t['id']!;
                    final label = t['label']!;
                    final asset = t['asset']!;

                    return IncidentTypeCard(
                      title: label,
                      assetPath: asset,
                      isSelected: selected == id,
                      onTap: () async {
                        setState(() => selected = id);

                        // 2. MEJORA: Feedback táctil corto (Tic) al seleccionar
                        // Ayuda a confirmar la selección bajo sol intenso
                        if (await Vibration.hasVibrator() ?? false) {
                          Vibration.vibrate(duration: 40);
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              /// ✅ BOTÓN PRO (PASO 3)
              AnimatedScale(
                scale: isEnabled ? 1.0 : 0.97,
                duration: const Duration(milliseconds: 180),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? const Color(0xFF1976D2)
                          : const Color(0xFF1976D2).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isEnabled
                          ? [
                        BoxShadow(
                          color: const Color(0xFF1976D2)
                              .withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: !isEnabled
                            ? null
                            : () async {
                          // 3. MEJORA: Vibración de confirmación de acción
                          if (await Vibration.hasVibrator() ?? false) {
                            Vibration.vibrate(duration: 100);
                          }

                          Navigator.pushNamed(
                            context,
                            '/report',
                            arguments: {'type': selected},
                          );
                        },
                        child: Center(
                          child: Text(
                            'SIGUIENTE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: isEnabled
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}