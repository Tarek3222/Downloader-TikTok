import 'dart:convert';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tiktok_video.dart';
import '../services/tiktok_service.dart';

class DownloadState extends Equatable {
  final TikTokVideo? videoInfo;
  final List<TikTokVideo> history;
  final bool isLoading;
  final double downloadProgress;
  final bool isCoverDownloading;
  final double coverDownloadProgress;
  final String? message;
  final Color? messageColor;

  const DownloadState({
    this.videoInfo,
    this.history = const [],
    this.isLoading = false,
    this.downloadProgress = 0.0,
    this.isCoverDownloading = false,
    this.coverDownloadProgress = 0.0,
    this.message,
    this.messageColor,
  });

  DownloadState copyWith({
    TikTokVideo? videoInfo,
    List<TikTokVideo>? history,
    bool? isLoading,
    double? downloadProgress,
    bool? isCoverDownloading,
    double? coverDownloadProgress,
    String? message,
    Color? messageColor,
    bool clearMessage = false,
  }) {
    return DownloadState(
      videoInfo: videoInfo ?? this.videoInfo,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isCoverDownloading: isCoverDownloading ?? this.isCoverDownloading,
      coverDownloadProgress:
          coverDownloadProgress ?? this.coverDownloadProgress,
      message: clearMessage ? null : (message ?? this.message),
      messageColor: clearMessage ? null : (messageColor ?? this.messageColor),
    );
  }

  @override
  List<Object?> get props => [
        videoInfo,
        history,
        isLoading,
        downloadProgress,
        isCoverDownloading,
        coverDownloadProgress,
        message,
        messageColor,
      ];
}

class DownloadCubit extends Cubit<DownloadState> {
  final TikTokService _tikTokService;
  static const _historyKey = 'download_history';

  DownloadCubit({TikTokService? service})
      : _tikTokService = service ?? TikTokService(),
        super(const DownloadState()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_historyKey) ?? <String>[];
      final videos = jsonList
          .map((jsonStr) => TikTokVideo.fromJson(jsonDecode(jsonStr)))
          .toList();
      videos.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      emit(state.copyWith(history: videos));
    } catch (e) {
      log('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList =
          state.history.map((v) => jsonEncode(v.toJson())).toList();
      await prefs.setStringList(_historyKey, jsonList);
    } catch (e) {
      log('Error saving history: $e');
    }
  }

  Future<void> downloadVideo(String url) async {
    try {
      emit(state.copyWith(
          isLoading: true, downloadProgress: 0.0, clearMessage: true));
      final video = await _tikTokService.downloadVideo(
        url,
        onProgress: (received, total) {
          if (total != -1) {
            emit(state.copyWith(downloadProgress: received / total));
          }
        },
      );
      final newHistory = [video, ...state.history];
      emit(state.copyWith(
        videoInfo: video,
        history: newHistory,
        message: 'Video downloaded successfully',
        messageColor: Colors.green,
      ));
      await _saveHistory();
    } catch (e) {
      emit(state.copyWith(message: e.toString(), messageColor: Colors.red));
    } finally {
      emit(state.copyWith(isLoading: false, downloadProgress: 0.0));
    }
  }

  Future<void> downloadCover(TikTokVideo video) async {
    try {
      emit(state.copyWith(
          isCoverDownloading: true,
          coverDownloadProgress: 0.0,
          clearMessage: true));
      await _tikTokService.downloadCoverImage(
        video,
        onProgress: (received, total) {
          if (total != -1) {
            emit(state.copyWith(coverDownloadProgress: received / total));
          }
        },
      );
      emit(state.copyWith(
          message: 'Cover image downloaded successfully',
          messageColor: Colors.green));
    } catch (e) {
      emit(state.copyWith(message: e.toString(), messageColor: Colors.red));
    } finally {
      emit(state.copyWith(
          isCoverDownloading: false, coverDownloadProgress: 0.0));
    }
  }

  Future<String?> getDownloadPath() async {
    try {
      final downloadPath = await _tikTokService.getDownloadPath();
      if (downloadPath == null) {
        emit(state.copyWith(
            message: 'Could not access download directory',
            messageColor: Colors.red));
      }
      return downloadPath;
    } catch (e) {
      emit(state.copyWith(
          message: 'Could not access download directory: $e',
          messageColor: Colors.red));
      return null;
    }
  }

  Future<void> clearHistory() async {
    emit(state.copyWith(history: []));
    await _saveHistory();
  }

  Future<void> removeFromHistory(TikTokVideo video) async {
    final updated = List<TikTokVideo>.from(state.history)..remove(video);
    emit(state.copyWith(history: updated));
    await _saveHistory();
  }

  void clearMessage() {
    if (state.message != null) {
      emit(state.copyWith(clearMessage: true));
    }
  }
}
