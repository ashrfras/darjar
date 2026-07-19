import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/marketplace/data/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({super.key});

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  ListingType _type = ListingType.offer;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      key: const Key('create-listing-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarPageHeader(
                title: localizations.createListing,
                description: localizations.createListingDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<ListingType>(
                      segments: [
                        ButtonSegment(
                          value: ListingType.offer,
                          label: Text(localizations.offer),
                        ),
                        ButtonSegment(
                          value: ListingType.giveAway,
                          label: Text(localizations.giveAway),
                        ),
                        ButtonSegment(
                          value: ListingType.request,
                          label: Text(localizations.request),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (selection) {
                        setState(() => _type = selection.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.large),
                    DarJarTextField(
                      label: localizations.listingTitle,
                      hint: localizations.listingTitleHint,
                      controller: _titleController,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    TextField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: localizations.description,
                        hintText: localizations.listingDescriptionHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    DarJarTextField(
                      label: localizations.price,
                      hint: localizations.priceHint,
                      controller: _priceController,
                      prefixIcon: Icons.payments_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    DarJarButton(
                      key: const Key('publish-listing-button'),
                      label: localizations.publishListing,
                      expanded: true,
                      onPressed: _publish,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _publish() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final price = _priceController.text.trim();
    if (title.isEmpty || description.isEmpty || price.isEmpty) return;

    final listing = ref
        .read(marketplaceListingsProvider.notifier)
        .create(
          title: title,
          description: description,
          priceLabel: price,
          type: _type,
        );
    context.go(AppRoutes.listingDetails(listing.id));
  }
}
