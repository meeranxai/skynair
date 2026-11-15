import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/security_provider.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final List<String> _pin = [];
  bool _isError = false;

  void _onNumberTap(int number) {
    if (_pin.length < 4) {
      setState(() {
        _pin.add(number.toString());
        _isError = false;
      });
      
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin.removeLast();
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final pinString = _pin.join();
    final isValid = await ref.read(appLockProvider.notifier).verifyPin(pinString);
    
    if (!isValid) {
      setState(() {
        _pin.clear();
        _isError = true;
      });
      // Vibrate would be good here if we had the plugin
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Skynaire Protected',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your secret PIN',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            
            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isError 
                      ? theme.colorScheme.error 
                      : filled 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surfaceVariant,
                    border: Border.all(
                      color: filled ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                );
              }),
            ),
            
            if (_isError) ...[
              const SizedBox(height: 16),
              Text(
                'Incorrect PIN. Try again.',
                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
              ),
            ],
            
            const Spacer(),
            
            // Number Pad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox.shrink(); // Empty left
                  if (index == 10) return _buildNumberButton(0);
                  if (index == 11) return _buildBackspaceButton();
                  return _buildNumberButton(index + 1);
                },
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _onNumberTap(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        alignment: Alignment.center,
        child: Text(
          number.toString(),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        alignment: Alignment.center,
        child: Icon(
          Icons.backspace_outlined,
          size: 28,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
