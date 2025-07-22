import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/rendez_vous.dart';
import '../../models/client.dart';
import '../../models/service.dart';
import '../../providers/rendez_vous_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/service_provider.dart';
import 'conflict_dialog.dart';

class RdvForm extends ConsumerStatefulWidget {
  final RendezVous? rdv;
  final DateTime? dateInitiale;
  final TimeOfDay? heureInitiale;

  const RdvForm({
    super.key,
    this.rdv,
    this.dateInitiale,
    this.heureInitiale,
  });

  @override
  ConsumerState<RdvForm> createState() => _RdvFormState();
}

class _RdvFormState extends ConsumerState<RdvForm> {
  final _formKey = GlobalKey<FormState>();
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  Client? _selectedClient;
  Service? _selectedService;
  StatutRendezVous _selectedStatut = StatutRendezVous.confirme;
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  String? _searchClientQuery;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.rdv != null) {
      // Mode édition
      _selectedDate = DateTime(
        widget.rdv!.dateHeure.year,
        widget.rdv!.dateHeure.month,
        widget.rdv!.dateHeure.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(widget.rdv!.dateHeure);
      _selectedStatut = widget.rdv!.statut;
      _notesController.text = widget.rdv!.notes ?? '';
    } else {
      // Mode création
      _selectedDate = widget.dateInitiale ?? DateTime.now();
      _selectedTime = widget.heureInitiale ?? TimeOfDay.now();
      _notesController.text = '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientState = ref.watch(clientProvider);
    final serviceState = ref.watch(serviceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rdv != null ? 'Modifier RDV' : 'Nouveau RDV'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _sauvegarder,
              child: const Text('Sauvegarder'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélection du client
              _buildClientSelection(clientState),
              const SizedBox(height: 20),
              
              // Sélection du service
              _buildServiceSelection(serviceState),
              const SizedBox(height: 20),
              
              // Date et heure
              _buildDateTimeSelection(theme),
              const SizedBox(height: 20),
              
              // Statut
              _buildStatutSelection(theme),
              const SizedBox(height: 20),
              
              // Notes
              _buildNotesField(theme),
              const SizedBox(height: 20),
              
              // Résumé
              if (_selectedClient != null && _selectedService != null)
                _buildSummary(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelection(ClientState clientState) {
    final clients = _searchClientQuery?.isNotEmpty == true 
        ? clientState.clients.where((c) => 
            c.nomComplet.toLowerCase().contains(_searchClientQuery!.toLowerCase()) ||
            c.telephone?.contains(_searchClientQuery!) == true ||
            c.email?.toLowerCase().contains(_searchClientQuery!.toLowerCase()) == true
          ).toList()
        : clientState.clients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        DropdownButtonFormField<Client>(
          value: _selectedClient,
          decoration: InputDecoration(
            hintText: 'Rechercher un client...',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) => value == null ? 'Veuillez sélectionner un client' : null,
          isExpanded: true,
          items: clients.map((client) {
            return DropdownMenuItem<Client>(
              value: client,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    client.nomComplet,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (client.telephone?.isNotEmpty == true)
                    Text(
                      client.telephone!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (client) {
            setState(() {
              _selectedClient = client;
            });
          },
        ),
      ],
    );
  }

  Widget _buildServiceSelection(ServiceState serviceState) {
    final services = serviceState.services.where((s) => s.actif).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        DropdownButtonFormField<Service>(
          value: _selectedService,
          decoration: InputDecoration(
            hintText: 'Sélectionner un service...',
            prefixIcon: const Icon(Icons.design_services),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) => value == null ? 'Veuillez sélectionner un service' : null,
          isExpanded: true,
          items: services.map((service) {
            return DropdownMenuItem<Service>(
              value: service,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.nom,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Text(
                        service.dureeFormatee,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        service.prixFormate,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (service) {
            setState(() {
              _selectedService = service;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeSelection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date *',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Heure *',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      Text(_selectedTime.format(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatutSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        DropdownButtonFormField<StatutRendezVous>(
          value: _selectedStatut,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.flag),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: StatutRendezVous.values.map((statut) {
            IconData icon;
            Color color;
            
            switch (statut) {
              case StatutRendezVous.confirme:
                icon = Icons.check_circle;
                color = Colors.green;
                break;
              case StatutRendezVous.enAttente:
                icon = Icons.schedule;
                color = Colors.orange;
                break;
              case StatutRendezVous.annule:
                icon = Icons.cancel;
                color = Colors.red;
                break;
              case StatutRendezVous.complete:
                icon = Icons.done_all;
                color = Colors.blue;
                break;
            }
            
            return DropdownMenuItem<StatutRendezVous>(
              value: statut,
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(_getStatutLabel(statut)),
                ],
              ),
            );
          }).toList(),
          onChanged: (statut) {
            if (statut != null) {
              setState(() {
                _selectedStatut = statut;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Notes personnalisées...',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 3,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildSummary(ThemeData theme) {
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    final dateFin = dateTime.add(Duration(minutes: _selectedService!.dureeMinutes));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé du rendez-vous',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildSummaryRow('Client', _selectedClient!.nomComplet, Icons.person),
          _buildSummaryRow('Service', _selectedService!.nom, Icons.design_services),
          _buildSummaryRow(
            'Date',
            DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(dateTime),
            Icons.calendar_today,
          ),
          _buildSummaryRow(
            'Horaire',
            '${_formatTime(dateTime)} - ${_formatTime(dateFin)}',
            Icons.access_time,
          ),
          _buildSummaryRow('Durée', _selectedService!.dureeFormatee, Icons.schedule),
          _buildSummaryRow('Prix', _selectedService!.prixFormate, Icons.euro),
          _buildSummaryRow('Statut', _getStatutLabel(_selectedStatut), Icons.flag),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label :',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null || _selectedService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final rdv = RendezVous(
        id: widget.rdv?.id,
        clientId: _selectedClient!.id!,
        serviceId: _selectedService!.id!,
        dateHeure: dateTime,
        dureeMinutes: _selectedService!.dureeMinutes,
        prix: _selectedService!.prix,
        statut: _selectedStatut,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        dateCreation: widget.rdv?.dateCreation ?? DateTime.now(),
        dateModification: widget.rdv != null ? DateTime.now() : null,
        clientNom: _selectedClient!.nom,
        clientPrenom: _selectedClient!.prenom,
        serviceNom: _selectedService!.nom,
      );

      final notifier = ref.read(rendezVousProvider.notifier);
      bool success;

      if (widget.rdv != null) {
        // Mode édition
        success = await notifier.modifierRendezVous(rdv);
      } else {
        // Mode création
        success = await notifier.ajouterRendezVous(rdv);
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.rdv != null 
                  ? 'Rendez-vous modifié avec succès' 
                  : 'Rendez-vous créé avec succès'),
            ),
          );
        }
      } else {
        // Vérifier s'il y a des conflits
        final rdvState = ref.read(rendezVousProvider);
        if (rdvState.conflits.isNotEmpty) {
          _showConflictDialog(rdv, rdvState.conflits);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors de la sauvegarde'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showConflictDialog(RendezVous rdv, List<RendezVous> conflits) {
    showDialog(
      context: context,
      builder: (context) => ConflictDialog(
        conflits: conflits,
        nouveauRdv: rdv,
        onForce: () async {
          Navigator.of(context).pop();
          
          final notifier = ref.read(rendezVousProvider.notifier);
          final success = await notifier.ajouterRendezVousMalgreConflits(rdv);
          
          if (success && mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rendez-vous créé malgré le conflit'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        onCancel: () {
          Navigator.of(context).pop();
          ref.read(rendezVousProvider.notifier).effacerConflits();
        },
      ),
    );
  }

  String _getStatutLabel(StatutRendezVous statut) {
    switch (statut) {
      case StatutRendezVous.confirme:
        return 'Confirmé';
      case StatutRendezVous.enAttente:
        return 'En attente';
      case StatutRendezVous.annule:
        return 'Annulé';
      case StatutRendezVous.complete:
        return 'Complété';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
