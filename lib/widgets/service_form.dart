import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/service.dart';
import 'tag_chip.dart';
import 'duration_input.dart';

class ServiceForm extends StatefulWidget {
  final Service? service;
  final Function(Service) onSubmit;
  final VoidCallback? onCancel;

  const ServiceForm({
    super.key,
    this.service,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  
  int _dureeMinutes = 30;
  String? _categorie;
  List<String> _tags = [];
  bool _actif = true;

  final List<String> _categoriesDisponibles = [
    'Coiffure',
    'Soin',
    'Massage',
    'Maquillage',
    'Manucure',
    'Consultation',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _initializeFromService(widget.service!);
    }
  }

  void _initializeFromService(Service service) {
    _nomController.text = service.nom;
    _descriptionController.text = service.description ?? '';
    _prixController.text = service.prix.toString();
    _dureeMinutes = service.dureeMinutes;
    _categorie = service.categorie;
    _tags = List.from(service.tags);
    _actif = service.actif;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final service = Service(
        id: widget.service?.id,
        nom: _nomController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
        dureeMinutes: _dureeMinutes,
        prix: double.parse(_prixController.text),
        categorie: _categorie,
        tags: _tags,
        actif: _actif,
        dateCreation: widget.service?.dateCreation ?? DateTime.now(),
        dateModification: widget.service != null ? DateTime.now() : null,
      );
      widget.onSubmit(service);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.service != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le service' : 'Nouveau service'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: Text(
              isEditing ? 'Modifier' : 'Créer',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom du service
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du service',
                hintText: 'Ex: Coupe homme',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.room_service),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                if (value.trim().length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Décrivez votre service...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Durée
            DurationInput(
              initialMinutes: _dureeMinutes,
              onChanged: (minutes) => setState(() => _dureeMinutes = minutes),
            ),
            const SizedBox(height: 16),

            // Prix
            TextFormField(
              controller: _prixController,
              decoration: const InputDecoration(
                labelText: 'Prix',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
                suffixText: '€',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le prix est obligatoire';
                }
                final prix = double.tryParse(value);
                if (prix == null) {
                  return 'Prix invalide';
                }
                if (prix < 0) {
                  return 'Le prix ne peut pas être négatif';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Catégorie
            DropdownButtonFormField<String>(
              value: _categorie,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categoriesDisponibles.map((categorie) {
                return DropdownMenuItem(
                  value: categorie,
                  child: Text(categorie),
                );
              }).toList(),
              onChanged: (value) => setState(() => _categorie = value),
              hint: const Text('Sélectionner une catégorie'),
            ),
            const SizedBox(height: 16),

            // Tags
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tags',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                TagInput(
                  tags: _tags,
                  onTagsChanged: (tags) => setState(() => _tags = tags),
                  hintText: 'Ajouter un tag (ex: rapide, premium...)',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statut actif/inactif
            Card(
              child: SwitchListTile(
                title: const Text('Service actif'),
                subtitle: Text(
                  _actif 
                    ? 'Le service est disponible pour les rendez-vous'
                    : 'Le service est masqué et indisponible',
                ),
                value: _actif,
                onChanged: (value) => setState(() => _actif = value),
                secondary: Icon(
                  _actif ? Icons.visibility : Icons.visibility_off,
                  color: _actif ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preview
            if (_nomController.text.isNotEmpty) ...[
              Text(
                'Aperçu',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _ServicePreview(
                nom: _nomController.text,
                description: _descriptionController.text.isEmpty 
                  ? null 
                  : _descriptionController.text,
                dureeMinutes: _dureeMinutes,
                prix: double.tryParse(_prixController.text) ?? 0.0,
                categorie: _categorie,
                tags: _tags,
                actif: _actif,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServicePreview extends StatelessWidget {
  final String nom;
  final String? description;
  final int dureeMinutes;
  final double prix;
  final String? categorie;
  final List<String> tags;
  final bool actif;

  const _ServicePreview({
    required this.nom,
    this.description,
    required this.dureeMinutes,
    required this.prix,
    this.categorie,
    required this.tags,
    required this.actif,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final previewService = Service(
      nom: nom,
      description: description,
      dureeMinutes: dureeMinutes,
      prix: prix,
      categorie: categorie,
      tags: tags,
      actif: actif,
      dateCreation: DateTime.now(),
    );

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aperçu du service',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              nom,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (categorie != null) ...[
              const SizedBox(height: 4),
              Text(
                categorie!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(previewService.dureeFormatee),
                  avatar: const Icon(Icons.access_time, size: 16),
                  backgroundColor: colorScheme.secondaryContainer,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(previewService.prixFormate),
                  avatar: const Icon(Icons.euro, size: 16),
                  backgroundColor: colorScheme.tertiaryContainer,
                ),
                if (!actif) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Inactif'),
                    backgroundColor: colorScheme.errorContainer,
                  ),
                ],
              ],
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
