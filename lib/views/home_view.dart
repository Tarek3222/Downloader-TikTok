// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cubit/download_cubit.dart';
import '../cubit/language_cubit.dart';
import '../models/tiktok_video.dart';
import 'settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController urlController = TextEditingController();

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  void _handleDownload(BuildContext context) async {
    final url = urlController.text.trim();
    if (url.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_enter_url'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await context.read<DownloadCubit>().downloadVideo(url);
    urlController.clear();
  }

  void _shareVideo(TikTokVideo video) async {
    await Share.shareFiles(
      [video.downloadPath],
      text: video.description,
    );
  }

  void _copyDescription(BuildContext context, String description) async {
    final scheme = Theme.of(context).colorScheme;
    await Clipboard.setData(ClipboardData(text: description));
    Get.snackbar(
      'success'.tr,
      'description_copied'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: scheme.primary,
      colorText: Colors.white,
    );
  }

  // ignore: unused_element
  void _downloadCover(BuildContext context, TikTokVideo video) async {
    await context.read<DownloadCubit>().downloadCover(video);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isRTL =
        context.select<LanguageCubit, bool>((c) => c.state.isRTL);

    return BlocListener<DownloadCubit, DownloadState>(
      listenWhen: (p, c) => p.message != c.message,
      listener: (context, state) {
        if (state.message != null) {
          Get.snackbar(
            state.messageColor == Colors.red ? 'error'.tr : 'success'.tr,
            state.message!,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: state.messageColor ?? scheme.primary,
            colorText: Colors.white,
          );
          context.read<DownloadCubit>().clearMessage();
        }
      },
      child: BlocBuilder<LanguageCubit, LanguageState>(
        buildWhen: (p, c) => p.locale != c.locale || p.isRTL != c.isRTL,
        builder: (context, __) => Scaffold(
          appBar: AppBar(
            title: const Text('TikTok Downloader'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: scheme.primary,
                ),
                onPressed: () => Get.to(() => const SettingsView()),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: urlController,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        hintText: 'paste_link'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: scheme.primary,
                          ),
                          onPressed: urlController.clear,
                        ),
                      ),
                      textDirection:
                          isRTL ? TextDirection.rtl : TextDirection.ltr,
                    ).animate().fadeIn().slideX(),
                    const SizedBox(height: 16),
                    BlocBuilder<DownloadCubit, DownloadState>(
                      buildWhen: (p, c) =>
                          p.isLoading != c.isLoading ||
                          p.downloadProgress != c.downloadProgress,
                      builder: (context, dState) {
                        return ElevatedButton.icon(
                          onPressed: dState.isLoading
                              ? null
                              : () => _handleDownload(context),
                          icon: dState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                          label: Text(
                            dState.isLoading
                                ? '${(dState.downloadProgress * 100).toInt()}%'
                                : 'download'.tr,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ).animate().fadeIn().slideX(delay: 100.ms);
                      },
                    ),
                    BlocBuilder<DownloadCubit, DownloadState>(
                      buildWhen: (p, c) =>
                          p.isLoading != c.isLoading ||
                          p.downloadProgress != c.downloadProgress,
                      builder: (context, dState) {
                        if (!dState.isLoading) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            value: dState.downloadProgress,
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(scheme.primary),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<DownloadCubit, DownloadState>(
                    buildWhen: (p, c) => p.history != c.history,
                    builder: (context, dState) {
                      if (dState.history.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'no_downloads_yet'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: scheme.primary.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().scale();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: dState.history.length,
                        itemBuilder: (context, index) {
                          final video = dState.history[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => OpenFile.open(video.downloadPath),
                              onLongPress: () async {
                                if (video.originalUrl.isEmpty) {
                                  Get.snackbar(
                                    'error'.tr,
                                    'original_url_not_available'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                await Clipboard.setData(
                                    ClipboardData(text: video.originalUrl));
                                Get.snackbar(
                                  'success'.tr,
                                  'tiktok_url_copied'.tr,
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: scheme.primary,
                                  colorText: Colors.white,
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (video.coverUrl.isNotEmpty)
                                    SizedBox(
                                      width: 100,
                                      height: 180,
                                      child: CachedNetworkImage(
                                        imageUrl: video.coverUrl,
                                        fit: BoxFit.cover,
                                        memCacheHeight: 360,
                                        memCacheWidth: 200,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceVariant,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceVariant,
                                          child: const Center(
                                            child: Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            video.description,
                                            style: context.textTheme.bodyLarge,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textDirection: isRTL
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 4,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    Text(
                                                      video.timestamp
                                                          .toLocal()
                                                          .toString()
                                                          .split('.')[0],
                                                      style: context
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                              color: scheme
                                                                  .primary),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.touch_app,
                                                          size: 16,
                                                          color: scheme.primary
                                                              .withOpacity(0.5),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          'hold_to_copy_url'.tr,
                                                          style: context
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                            color: scheme
                                                                .primary
                                                                .withOpacity(
                                                                    0.5),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              BlocBuilder<DownloadCubit,
                                                  DownloadState>(
                                                buildWhen: (p, c) =>
                                                    p.isCoverDownloading !=
                                                        c.isCoverDownloading ||
                                                    p.coverDownloadProgress !=
                                                        c.coverDownloadProgress,
                                                builder: (context, dState) {
                                                  return IconButton(
                                                    style: IconButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    icon: dState
                                                            .isCoverDownloading
                                                        ? Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              CircularProgressIndicator(
                                                                value: dState
                                                                    .coverDownloadProgress,
                                                                strokeWidth: 2,
                                                              ),
                                                              Icon(
                                                                Icons.download,
                                                                color: scheme
                                                                    .primary,
                                                                size: 16,
                                                              ),
                                                            ],
                                                          )
                                                        : Icon(
                                                            Icons.download,
                                                            color:
                                                                scheme.primary,
                                                          ),
                                                    onPressed: dState
                                                            .isCoverDownloading
                                                        ? null
                                                        : () => _downloadCover(
                                                            context, video),
                                                    tooltip:
                                                        'download_cover'.tr,
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                style: IconButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                icon: Icon(
                                                  Icons.share,
                                                  color: scheme.primary,
                                                ),
                                                onPressed: () =>
                                                    _shareVideo(video),
                                                tooltip: 'share_video'.tr,
                                              ),
                                              IconButton(
                                                style: IconButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                icon: Icon(
                                                  Icons.copy,
                                                  color: scheme.primary,
                                                ),
                                                onPressed: () =>
                                                    _copyDescription(context,
                                                        video.description),
                                                tooltip: 'copy_description'.tr,
                                              ),
                                              IconButton(
                                                style: IconButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed: () => context
                                                    .read<DownloadCubit>()
                                                    .removeFromHistory(video),
                                                tooltip:
                                                    'delete_from_history'.tr,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn().slideX(delay: (100 * index).ms);
                        },
                      );
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
