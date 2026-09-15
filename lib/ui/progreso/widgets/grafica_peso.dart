import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../config/tema.dart';
import '../../core/widgets/estados.dart';
import '../view_models/progreso_view_model.dart';

class GraficaPeso extends StatelessWidget {
  const GraficaPeso({
    super.key,
    required this.puntos,
    required this.etiquetaEjeX,
    this.resumen,
  });

  static const Map<String, Color> coloresOrigen = {
    'consulta': ColoresDentu.verde,
    'app': ColoresDentu.dorado,
    'whatsapp': Color(0xFF2F6FB3),
  };

  static const Map<String, String> nombresOrigen = {
    'consulta': 'Consulta',
    'app': 'App',
    'whatsapp': 'WhatsApp',
  };

  final List<PuntoGraficaPeso> puntos;
  final String Function(double x) etiquetaEjeX;
  final String? resumen;

  @override
  Widget build(BuildContext context) {
    if (puntos.isEmpty) {
      return const EstadoVacio(
        icono: Icons.show_chart_rounded,
        ilustracion: IlustracionVacio.peso,
        titulo: 'Tu curva de peso aparecerá aquí',
        mensaje: 'En cuanto registres tu primer peso, verás tu avance.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumen != null) Text(resumen!, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Semantics(
          label: 'Gráfica de peso. ${resumen ?? ''}',
          child: ExcludeSemantics(
            child: SizedBox(height: 200, child: LineChart(_datos())),
          ),
        ),
        const SizedBox(height: 8),
        const _Leyenda(),
      ],
    );
  }

  LineChartData _datos() {
    final pesos = puntos.map((p) => p.peso);
    final maxX = math.max(puntos.last.x, 1.0);
    const sinTitulos = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return LineChartData(
      minX: 0,
      maxX: maxX,
      minY: (pesos.reduce(math.min) - 1).floorToDouble(),
      maxY: (pesos.reduce(math.max) + 1).ceilToDouble(),
      gridData: const FlGridData(drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: sinTitulos,
        rightTitles: sinTitulos,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (valor, meta) =>
                SideTitleWidget(meta: meta, child: Text(valor.toStringAsFixed(0))),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: math.max(1, (maxX / 3).ceilToDouble()),
            maxIncluded: false,
            getTitlesWidget: (valor, meta) =>
                SideTitleWidget(meta: meta, child: Text(etiquetaEjeX(valor))),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => ColoresDentu.verde,
          getTooltipItems: (tocados) => [
            for (final tocado in tocados)
              LineTooltipItem(
                '${puntos[tocado.spotIndex].peso} kg\n'
                '${nombresOrigen[puntos[tocado.spotIndex].origen] ?? ''}',
                const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [for (final p in puntos) FlSpot(p.x, p.peso)],
          color: ColoresDentu.verde.withValues(alpha: 0.6),
          barWidth: 2,
          dotData: FlDotData(
            getDotPainter: (_, _, _, indice) => FlDotCirclePainter(
              radius: 5,
              color: coloresOrigen[puntos[indice].origen] ?? ColoresDentu.verde,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        for (final origen in GraficaPeso.nombresOrigen.keys)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: GraficaPeso.coloresOrigen[origen],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(GraficaPeso.nombresOrigen[origen]!),
            ],
          ),
      ],
    );
  }
}
