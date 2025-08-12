import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:media_scanner/media_scanner.dart';
import '../models/tiktok_video.dart';

typedef ProgressCallback = void Function(int received, int total);

class TikTokService {
  final _dio = Dio();
  final _cookieJar = CookieJar();
  static const String _defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  TikTokService() {
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.options.followRedirects = true;
    _dio.options.headers.addAll({
      HttpHeaders.userAgentHeader: _defaultUserAgent,
      HttpHeaders.acceptLanguageHeader: 'en-US,en;q=0.9',
      HttpHeaders.acceptHeader:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'sec-ch-ua-platform': '"Windows"',
    });
  }

  Future<TikTokVideo> downloadVideo(String url,
      {ProgressCallback? onProgress}) async {
    try {
      // Clean up and format the URL
      var cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http')) {
        cleanUrl = 'https://$cleanUrl';
      }
      log('Downloading video from URL: $cleanUrl'); // Debug log

      // Get the HTML content of the TikTok page with desktop-like headers
      final response = await _dio.get(
        cleanUrl,
        options: Options(headers: {
          HttpHeaders.refererHeader: 'https://www.tiktok.com/',
          HttpHeaders.userAgentHeader: _defaultUserAgent,
        }),
      );
      final html = response.data.toString();

      // Extract video URL using regex
      final playMatch = RegExp(r'"playAddr":"([^"]+)"').firstMatch(html);
      final downloadMatch =
          RegExp(r'"downloadAddr":"([^"]+)"').firstMatch(html);
      String? videoUrl = playMatch?.group(1) ?? downloadMatch?.group(1);
      if (videoUrl == null) {
        throw Exception('Could not find video URL');
      }
      videoUrl = videoUrl
          .replaceAll(r'\u002F', '/')
          .replaceAll(r'\u0026', '&')
          .replaceAll('&amp;', '&');
      if (videoUrl.startsWith('//')) {
        videoUrl = 'https:$videoUrl';
      }
      if (videoUrl.startsWith('http:')) {
        videoUrl = videoUrl.replaceFirst('http:', 'https:');
      }

      // Extract description using regex, handle case where description might not exist
      String description = '';
      final descMatch = RegExp(r'"desc":"([^"]*)"').firstMatch(html);
      if (descMatch != null && descMatch.group(1) != null) {
        description = descMatch.group(1)!.replaceAll(r'\u002F', '/');
      }

      // Extract cover image URL, handle case where it might not exist
      String coverUrl = '';
      final coverMatch = RegExp(r'"cover":"([^"]+)"').firstMatch(html);
      if (coverMatch != null && coverMatch.group(1) != null) {
        coverUrl = coverMatch.group(1)!.replaceAll(r'\u002F', '/');
      }

      // Create download path
      final downloadPath = await getDownloadPath();
      if (downloadPath == null) {
        throw Exception('Could not access download directory');
      }

      // Generate unique filename using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoPath = '$downloadPath/tiktok_$timestamp.mp4';

      // Download the video
      try {
        await _downloadFile(
          videoUrl,
          videoPath,
          referer: cleanUrl,
          onProgress: onProgress,
        );
      } on DioException catch (e) {
        // Retry with CDN domain if blocked
        if (e.response?.statusCode == 403) {
          final cdnUrl = _rewriteToCdn(videoUrl);
          await _downloadFile(
            cdnUrl,
            videoPath,
            referer: cleanUrl,
            onProgress: onProgress,
          );
        } else {
          rethrow;
        }
      }

      // Scan media to make it visible in gallery
      if (Platform.isAndroid) {
        await MediaScanner.loadMedia(path: videoPath);
      }

      final video = TikTokVideo(
        downloadPath: videoPath,
        description: description.isNotEmpty ? description : 'No description',
        coverUrl: coverUrl,
        originalUrl: cleanUrl, // Use the cleaned URL
      );
      log('Created video with original URL: ${video.originalUrl}'); // Debug log
      return video;
    } catch (e) {
      log(e.toString());
      throw Exception('Failed to download video: $e');
    }
  }

  Future<void> downloadCoverImage(TikTokVideo video,
      {ProgressCallback? onProgress}) async {
    try {
      if (video.coverUrl.isEmpty) {
        throw Exception('No cover image available');
      }

      final downloadPath = await getDownloadPath();
      if (downloadPath == null) {
        throw Exception('Could not access download directory');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '$downloadPath/tiktok_cover_$timestamp.jpg';

      await _downloadFile(video.coverUrl, imagePath, onProgress: onProgress);

      if (Platform.isAndroid) {
        await MediaScanner.loadMedia(path: imagePath);
      }
    } catch (e) {
      throw Exception('Failed to download cover image: $e');
    }
  }

  Future<void> _downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onProgress,
    String? referer,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          headers: {
            HttpHeaders.refererHeader: referer ?? 'https://www.tiktok.com/',
            HttpHeaders.userAgentHeader: _defaultUserAgent,
            HttpHeaders.acceptHeader: '*/*',
            HttpHeaders.connectionHeader: 'keep-alive',
          },
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  String _rewriteToCdn(String url) {
    final uri = Uri.parse(url);
    final host = uri.host;
    if (host.contains('tiktok.com')) {
      final newHost =
          host.replaceAll('v16-webapp.tiktok.com', 'v16.tiktokcdn.com');
      return uri.replace(host: newHost).toString();
    }
    return url;
  }

  Future<String?> getDownloadPath() async {
    try {
      if (Platform.isAndroid) {
        final directory =
            Directory('/storage/emulated/0/DCIM/TIKTOKDOWNLOADER');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory.path;
      }
      return null;
    } catch (e) {
      log('Error getting download path: $e');
      return null;
    }
  }
}
