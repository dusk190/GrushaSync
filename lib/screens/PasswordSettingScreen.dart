import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dualModeService.dart';

class PasswordSettingsScreen extends StatefulWidget {
  const PasswordSettingsScreen({super.key});

  @override
  State<PasswordSettingsScreen> createState() => _PasswordSettingsScreenState();
}

class _PasswordSettingsScreenState extends State<PasswordSettingsScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    final service = Provider.of<DualModeService>(context, listen: false);
    _passwordController.text = service.networkPassword ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DualModeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки сети'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Пароль сети',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Устройства с одинаковым паролем видят друг друга.\n'
                  'Оставьте поле пустым для открытой сети.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _isObscure,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final newPassword = _passwordController.text;
                await service.setNetworkPassword(
                    newPassword.isEmpty ? null : newPassword
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пароль сети сохранён')),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Сохранить'),
            ),
            const SizedBox(height: 20),
            if (service.networkPassword != null && service.networkPassword!.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await service.setNetworkPassword(null);
                  _passwordController.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Пароль сброшен, сеть открыта')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Сбросить пароль (открыть сеть)'),
              ),
          ],
        ),
      ),
    );
  }
}