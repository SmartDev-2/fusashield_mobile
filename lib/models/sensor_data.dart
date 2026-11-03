import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SensorData {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const SensorData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.unit = '',
  });
}

const dummySensors = <SensorData>[
  SensorData(
    title: 'Suhu Udara',
    value: '30.5',
    unit: '°C',
    icon: Icons.thermostat_rounded,
    color: Colors.orange,
  ),
  SensorData(
    title: 'Kelembapan Udara',
    value: '72',
    unit: '%',
    icon: Icons.water_drop_rounded,
    color: Colors.blue,
  ),
  SensorData(
    title: 'Kelembapan Tanah',
    value: '45',
    unit: '%',
    icon: Icons.grass_rounded,
    color: AppColors.accent,
  ),
  SensorData(
    title: 'Status Pompa',
    value: 'OFF',
    icon: Icons.water_rounded,
    color: Colors.deepPurple,
  ),
];
