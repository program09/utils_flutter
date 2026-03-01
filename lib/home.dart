import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orm/utils/event_bridge.dart';
import 'package:orm/utils/events.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _estado = 'Esperando...';
  List<String> _logs = [];

  // 1. Definir variables para las suscripciones
  StreamSubscription? _eventsSub;
  StreamSubscription? _bridgeSub;

  @override
  void initState() {
    super.initState();

    // 2. Guardar las suscripciones
    _eventsSub = Events.listener('syncCompleted', (data) {
      if (!mounted) return;
      setState(() {
        _estado = '📬 ${data['message'] ?? 'Evento recibido'}';
        _logs.insert(
          0,
          '${DateTime.now().toString().substring(11, 19)}: ${data['message']}',
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${data['message']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    });

    // Escuchar eventos del background
    _bridgeSub = EventBridge.listener('syncCompleted', (data) {
      if (!mounted) return;
      setState(() {
        _estado = '📬 ${data['message'] ?? 'Evento recibido'}';
        _logs.insert(
          0,
          '${DateTime.now().toString().substring(11, 19)}: ${data['message']}',
        );
      });
    });
  }

  @override
  void dispose() {
    // 3. CANCELAR TODO AL CERRAR LA PANTALLA
    _eventsSub?.cancel();
    _bridgeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EventBridge Demo')),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Text(
              _estado,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.event, color: Colors.blue),
                  title: Text(_logs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
