import 'package:flutter/material.dart';
import '../../models/rendez_vous.dart';

class ConflictDialog extends StatelessWidget {
  final List<RendezVous> conflits;
  final RendezVous nouveauRdv;
  final VoidCallback onForce;
  final VoidCallback onCancel;

  const ConflictDialog({
    super.key,
    required this.conflits,
    required this.nouveauRdv,
    required this.onForce,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          const Text('Conflit détecté'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le créneau sélectionné entre en conflit avec ${conflits.length} autre(s) rendez-vous :',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Nouveau RDV
            _buildRdvInfo(
              context,
              'Nouveau rendez-vous',
              nouveauRdv,
              Colors.blue.shade50,
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Conflits
            Text(
              'Conflits détectés :',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: conflits.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildRdvInfo(
                    context,
                    'RDV ${index + 1}',
                    conflits[index],
                    Colors.red.shade50,
                    Colors.red,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous pouvez forcer la création du rendez-vous malgré le conflit, ou annuler et choisir un autre créneau.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Annuler'),
        ),
        FilledButton.tonal(
          onPressed: onForce,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.shade100,
            foregroundColor: Colors.orange.shade700,
          ),
          child: const Text('Forcer la création'),
        ),
      ],
    );
  }

  Widget _buildRdvInfo(
    BuildContext context,
    String titre,
    RendezVous rdv,
    Color backgroundColor,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                titre,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rdv.clientNomComplet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.design_services,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rdv.serviceNom ?? 'Service non défini',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '${_formatTime(rdv.dateHeure)} - ${_formatTime(rdv.dateFin)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.schedule,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                rdv.dureeFormatee,
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                rdv.prixFormate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          if (rdv.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.note,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rdv.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
