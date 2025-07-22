import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/rendez_vous.dart';
import '../../providers/rendez_vous_provider.dart';

class RdvCard extends ConsumerWidget {
  final RendezVous rdv;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompact;

  const RdvCard({
    super.key,
    required this.rdv,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isCompact ? 2 : 4,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatutIndicator(theme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rdv.clientNomComplet,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isCompact) ...[
                          const SizedBox(height: 2),
                          Text(
                            rdv.serviceNom ?? 'Service non défini',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isCompact) _buildActionsMenu(context, ref),
                ],
              ),
              
              if (!isCompact) ...[
                const SizedBox(height: 8),
                _buildTimeAndPrice(theme),
                
                if (rdv.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    rdv.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ] else ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatTime(rdv.dateHeure)} (${rdv.dureeFormatee})',
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      rdv.prixFormate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatutIndicator(ThemeData theme) {
    Color color;
    IconData icon;
    
    switch (rdv.statut) {
      case StatutRendezVous.confirme:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case StatutRendezVous.enAttente:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case StatutRendezVous.annule:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case StatutRendezVous.complete:
        color = Colors.blue;
        icon = Icons.done_all;
        break;
    }
    
    return Container(
      width: 8,
      height: isCompact ? 32 : 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildTimeAndPrice(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
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
        const SizedBox(width: 4),
        Text(
          rdv.dureeFormatee,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          rdv.prixFormate,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'complete':
            await _changerStatut(ref, StatutRendezVous.complete);
            break;
          case 'confirm':
            await _changerStatut(ref, StatutRendezVous.confirme);
            break;
          case 'cancel':
            await _changerStatut(ref, StatutRendezVous.annule);
            break;
          case 'call':
            await _appelerClient(context);
            break;
          case 'delete':
            await _confirmerSuppression(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('Modifier'),
            ],
          ),
        ),
        if (!rdv.estComplete) ...[
          const PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.done_all, color: Colors.blue),
                SizedBox(width: 8),
                Text('Marquer complété'),
              ],
            ),
          ),
        ],
        if (!rdv.estConfirme && !rdv.estComplete) ...[
          const PopupMenuItem(
            value: 'confirm',
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Confirmer'),
              ],
            ),
          ),
        ],
        if (!rdv.estAnnule && !rdv.estComplete) ...[
          const PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.orange),
                SizedBox(width: 8),
                Text('Annuler'),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'call',
          child: Row(
            children: [
              Icon(Icons.phone, color: Colors.blue),
              SizedBox(width: 8),
              Text('Appeler'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Supprimer'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changerStatut(WidgetRef ref, StatutRendezVous nouveauStatut) async {
    final notifier = ref.read(rendezVousProvider.notifier);
    await notifier.changerStatutRendezVous(rdv.id!, nouveauStatut);
  }

  Future<void> _appelerClient(BuildContext context) async {
    // Note: Le téléphone du client n'est pas directement accessible depuis RDV
    // Il faudrait récupérer les infos du client
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'appel à implémenter'),
      ),
    );
  }

  Future<void> _confirmerSuppression(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rendez-vous'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le rendez-vous de ${rdv.clientNomComplet} ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(rendezVousProvider.notifier);
      final success = await notifier.supprimerRendezVous(rdv.id!);
      
      if (context.mounted) {
        if (success) {
          onDelete?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rendez-vous supprimé')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
