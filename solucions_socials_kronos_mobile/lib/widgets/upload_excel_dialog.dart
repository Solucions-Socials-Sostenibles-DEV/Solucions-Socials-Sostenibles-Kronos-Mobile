import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadExcelDialog extends StatefulWidget {
  const UploadExcelDialog({super.key});

  @override
  State<UploadExcelDialog> createState() => _UploadExcelDialogState();
}

class _UploadExcelDialogState extends State<UploadExcelDialog> {
  bool _isUploading = false;
  PlatformFile? _selectedFile;

  // Constantes de validación
  static const int maxSizeExcel = 10 * 1024 * 1024; // 10MB
  static const int maxSizeCsv = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = <String>['xlsx', 'xls', 'csv'];

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: false,
        withReadStream: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.first;
      
      // Validar extensión
      final String? extension = file.extension?.toLowerCase();
      if (extension == null || !allowedExtensions.contains(extension)) {
        if (!mounted) return;
        _showError('Formato no válido. Solo se permiten archivos .xlsx, .xls o .csv');
        return;
      }

      // Validar tamaño
      final int maxSize = extension == 'csv' ? maxSizeCsv : maxSizeExcel;
      if (file.size > maxSize) {
        if (!mounted) return;
        final String maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(0);
        _showError('El archivo es demasiado grande. Tamaño máximo: $maxSizeMB MB');
        return;
      }

      setState(() {
        _selectedFile = file;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Error al seleccionar el archivo: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      _showError('Por favor, selecciona un archivo primero');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // TODO: Implementar la lógica de subida del archivo
      // Aquí irá la lógica para procesar y subir el archivo a Supabase
      
      // Simulación de subida (eliminar cuando se implemente la lógica real)
      await Future<void>.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archivo subido correctamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Cerrar el diálogo
      Navigator.of(context).pop(_selectedFile);
    } catch (e) {
      if (!mounted) return;
      _showError('Error al subir el archivo: $e');
      setState(() {
        _isUploading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Título
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Subir Hoja de Ruta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Instrucciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Instrucciones',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    'Selecciona un archivo Excel (.xlsx, .xls) o CSV (.csv)',
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionItem(
                    'El archivo debe tener el formato correcto con todas las columnas',
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionItem(
                    'Tamaño máximo: 10MB (Excel) / 5MB (CSV)',
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionItem(
                    'La nueva hoja reemplazará la actual',
                    isWarning: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón de selección de archivo
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Seleccionar archivo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            // Información del archivo seleccionado
            if (_selectedFile != null) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.withOpacity(0.1)
                      : Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _selectedFile!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedFile!.extension?.toUpperCase()} • ${_formatFileSize(_selectedFile!.size)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _isUploading
                          ? null
                          : () {
                              setState(() {
                                _selectedFile = null;
                              });
                            },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isUploading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading || _selectedFile == null
                        ? null
                        : _uploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Subir archivo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text, {bool isWarning = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          size: 16,
          color: isWarning ? Colors.orange : Colors.blue,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isWarning ? Colors.orange[700] : null,
            ),
          ),
        ),
      ],
    );
  }
}

