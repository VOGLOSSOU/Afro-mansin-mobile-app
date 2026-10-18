import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/catalogue.dart';

bool isMediaUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

class PlantGallery extends StatelessWidget {
  const PlantGallery({super.key, required this.photos});
  final List<PlantPhoto> photos;
  @override
  Widget build(BuildContext context) {
    final valid = photos.where((p) => isMediaUrl(p.url)).toList();
    if (valid.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            const Icon(Icons.eco_outlined, size: 48, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucune photo disponible',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Photos', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: valid.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(
                  valid[index].url,
                  width: 280,
                  fit: BoxFit.cover,
                  semanticLabel: switch (valid[index].type) {
                    'feuille' => 'Feuille de la plante',
                    'partie_utile' => 'Partie utile de la plante',
                    'gros_plan' => 'Gros plan de la plante',
                    _ => 'Photo de la plante',
                  },
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 280,
                    child: Center(child: Text('Photo indisponible')),
                  ),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          width: 280,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le player est créé uniquement pour un audio renseigné, jamais au lancement.
class NameAudioButton extends StatefulWidget {
  const NameAudioButton({super.key, required this.url, required this.language});
  final String url, language;
  @override
  State<NameAudioButton> createState() => _NameAudioButtonState();
}

class _NameAudioButtonState extends State<NameAudioButton> {
  final _player = AudioPlayer();
  bool _loading = false;
  String? _loadedUrl;

  Future<void> _toggle() async {
    if (_loading) return;
    if (_player.playing &&
        _player.processingState != ProcessingState.completed) {
      await _player.pause();
      return;
    }
    setState(() => _loading = true);
    try {
      if (_loadedUrl != widget.url) {
        await _player.setUrl(widget.url);
        _loadedUrl = widget.url;
      }
      if (!mounted) return;
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      // play se termine à la fin du morceau : ne pas bloquer le bouton pendant la lecture.
      _player.play().catchError((Object _) {
        _showError();
      });
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError() {
    if (!mounted) return;
    _loadedUrl = null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Lecture audio indisponible. Vérifiez votre connexion et réessayez.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<PlayerState>(
    stream: _player.playerStateStream,
    builder: (context, snapshot) {
      final playing =
          snapshot.data?.playing == true &&
          snapshot.data?.processingState != ProcessingState.completed;
      return IconButton(
        tooltip:
            '${playing ? 'Mettre en pause' : 'Écouter'} le nom en ${widget.language}',
        onPressed: _loading ? null : _toggle,
        color: AppColors.accent,
        icon: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                playing ? Icons.pause_circle_outline : Icons.volume_up_outlined,
              ),
      );
    },
  );
}
