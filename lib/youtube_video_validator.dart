library youtube_video_validator;

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:youtube_video_validator/model/youtube_video_model.dart';

/// Youtube Video Validator
class YoutubeVideoValidator {
  static YoutubeVideo video = YoutubeVideo();

  static const String _uriVideoInfo = 'http://youtube.com/get_video_info';
  static final Map<String, String> _playabilityStatus = {
    'ok': 'OK',
    'login_required': 'LOGIN_REQUIRED',
    'unplayable': 'UNPLAYABLE',
    'error': 'ERROR',
  };
  static const _queryStringLength = 'player_response='.length;
  static final _pattern = RegExp(
      r'^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$');

  /// Validate the specified Youtube video URL.
  static bool validateUrl(String url) {
    if (url == null) {
      throw ArgumentError('url');
    }

    if (url.isEmpty) {
      return false;
    }

    final bool match = _pattern.hasMatch(url);

    return match;
  }

  /// Validate the specified Youtube video ID.
  static Future<bool> validateID(String videoID, {bool loadData = false}) async {
    final Map<String, dynamic> videoInfo = await _getVideoInfo(videoID);

    if (videoInfo == null) {
      return false;
    }

    final bool isRealVideo = _isRealVideo(videoInfo);

    if (loadData && isRealVideo) {
      video.fromJson(videoInfo['videoDetails']);
    }

    return isRealVideo;
  }

  static Future<YoutubeVideo> loadVideoInfo(String videoID) async {
    final Map<String, dynamic> videoInfo = await _getVideoInfo(videoID);

    if (videoInfo == null) {
      return null;
    }

    final bool isRealVideo = _isRealVideo(videoInfo);

    return isRealVideo ? (YoutubeVideo()..fromJson(videoInfo['videoDetails'])) : null;
  }

  static bool _isRealVideo(Map<String, dynamic> videoInfo) {
    final String videoStatus = videoInfo['playabilityStatus']['status'];
    final bool isRealVideo =
        videoStatus == _playabilityStatus['ok'] || videoStatus == _playabilityStatus['login_required'];
    return isRealVideo;
  }

  static Future<Map<String, dynamic>> _getVideoInfo(String videoID) async {
    if (videoID == null) {
      throw ArgumentError('videoID');
    }

    if (videoID.isEmpty || videoID.length != 11) {
      return null;
    }

    final url = '$_uriVideoInfo?video_id=$videoID';

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return null;
    }

    final List<String> options = (response.body).split('&');
    final option = options.firstWhere((value) => value.contains('player_response='), orElse: () => '');

    if (option == '') {
      return null;
    }
    final Map<String, dynamic> videoInfo = jsonDecode(Uri.decodeFull(option.substring(_queryStringLength)));

    return videoInfo;
  }
}
