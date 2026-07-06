import 'package:flutter/material.dart';

class UploadPanel extends StatelessWidget {
  const UploadPanel({
    super.key,
    required this.isLoading,
    required this.analysisStatusMessage,
    required this.errorMessage,
    required this.selectedSourceName,
    required this.rawTextPreview,
    required this.onPickPdf,
  });

  final bool isLoading;
  final String analysisStatusMessage;
  final String? errorMessage;
  final String? selectedSourceName;
  final String rawTextPreview;
  final VoidCallback onPickPdf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload and Parse',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pick an Anna University result PDF. The app extracts the text, identifies the student details, separates current exam and arrear exam students, and classifies each row as pass or arrear.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: isLoading ? null : onPickPdf,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(
                    isLoading
                        ? 'Processing...'
                        : selectedSourceName == null
                        ? 'Upload PDF'
                        : 'Upload Another PDF',
                  ),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(999),
                minHeight: 8,
              ),
              const SizedBox(height: 10),
              Text(
                analysisStatusMessage.isEmpty
                    ? 'Analyzing uploaded PDF...'
                    : analysisStatusMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (selectedSourceName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Current source: $selectedSourceName',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF4C7BF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (rawTextPreview.isNotEmpty) ...[
              const SizedBox(height: 14),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'Preview extracted PDF text',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Useful when you need to verify how the PDF text was extracted',
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13201C),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SelectableText(
                      rawTextPreview.length > 1800
                          ? '${rawTextPreview.substring(0, 1800)}...'
                          : rawTextPreview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
