import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models.dart';
import '../../domain/progress.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final r = s.progress();
    final c = r.current;
    final p = r.previous;
    final fmt = DateFormat("d 'de' MMMM", 'es');
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Tu semana', style: Theme.of(context).textTheme.headlineSmall),
        Text('Desde el lunes ${fmt.format(c.start)}'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
            child: Column(children: [
              SizedBox(height: 200, child: _WeekChart(c, p)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Legend(color: scheme.primary, text: 'Esta semana'),
                const SizedBox(width: 16),
                const _Legend(color: Colors.black38, text: 'Semana pasada'),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _Stat(
            label: 'Ansiedad promedio',
            value: c.avgAnxiety?.toStringAsFixed(1) ?? '—',
            delta: r.anxietyDelta,
          ),
          _Stat(label: 'Ejercicios', value: '${c.sessionsCompleted}'),
          _Stat(label: 'Registros', value: '${c.entries}'),
        ]),
        const SectionTitle('En pocas palabras'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(r.summary, style: const TextStyle(height: 1.45)),
          ),
        ),
        const SectionTitle('Reporte detallado'),
        if (!s.isPremium)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.summarize_outlined),
              title: const Text('Emociones de la semana y reporte para compartir'),
              subtitle: const Text(
                  'Útil si llevas tus registros a tu psicólogo o psicóloga.'),
              trailing: const PremiumLock(),
              onTap: () => openSubscription(context),
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Emociones registradas'),
                  const SizedBox(height: 8),
                  if (c.emotions.isEmpty) const Text('Sin registros aún.'),
                  ...(c.emotions.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(children: [
                              SizedBox(width: 110, child: Text(e.key.label)),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: e.value / c.entries,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.value}'),
                            ]),
                          )),
                  const SizedBox(height: 8),
                  Text('Minutos de práctica: ${c.minutesPracticed} '
                      '(semana pasada: ${p.minutesPracticed})'),
                ],
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Share.share(_reportText(r),
                subject: 'Mi reporte semanal SAMAI'),
            icon: const Icon(Icons.ios_share),
            label: const Text('Compartir reporte'),
          ),
        ],
      ],
    );
  }

  static String _reportText(ProgressReport r) {
    final c = r.current;
    final b = StringBuffer()
      ..writeln('Reporte semanal SAMAI')
      ..writeln('Semana desde: ${DateFormat('dd/MM/yyyy').format(c.start)}')
      ..writeln('Ansiedad promedio: ${c.avgAnxiety?.toStringAsFixed(1) ?? '—'} / 10 '
          '(semana anterior: ${r.previous.avgAnxiety?.toStringAsFixed(1) ?? '—'})')
      ..writeln('Ansiedad por día (L-D): ${c.dailyAvg.map((v) => v?.toStringAsFixed(1) ?? '-').join(' · ')}')
      ..writeln('Registros: ${c.entries} · Ejercicios completados: ${c.sessionsCompleted} '
          '(${c.minutesPracticed} min)')
      ..writeln('Emociones: ${c.emotions.entries.map((e) => '${e.key.label} ${e.value}').join(', ')}')
      ..writeln()
      ..writeln(r.summary)
      ..writeln()
      ..writeln('SAMAI es una herramienta de bienestar; este reporte no es un diagnóstico.');
    return b.toString();
  }
}

class _WeekChart extends StatelessWidget {
  final WeekStats current;
  final WeekStats previous;
  const _WeekChart(this.current, this.previous);

  List<FlSpot> _spots(WeekStats w) => List.generate(7, (i) {
        final v = w.dailyAvg[i];
        return v == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), v);
      });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 10,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 28,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                  style: const TextStyle(fontSize: 11)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(ProgressCalculator.dayLabel(v.toInt()),
                    style: const TextStyle(fontSize: 11)),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(previous),
            color: Colors.black38,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: _spots(current),
            color: primary,
            barWidth: 3,
            isCurved: true,
            preventCurveOverShooting: true,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 14, height: 4, color: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ]);
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final double? delta;
  const _Stat({required this.label, required this.value, this.delta});

  @override
  Widget build(BuildContext context) {
    Widget? trend;
    if (delta != null && delta!.abs() >= 0.5) {
      final down = delta! < 0;
      trend = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(down ? Icons.arrow_downward : Icons.arrow_upward,
            size: 14, color: down ? Colors.green : Colors.orange),
        Text(delta!.abs().toStringAsFixed(1),
            style: const TextStyle(fontSize: 12)),
      ]);
    }
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label, style: const TextStyle(fontSize: 12)),
              if (trend != null) trend,
            ],
          ),
        ),
      ),
    );
  }
}
