import 'package:image_picker/image_picker.dart';

import 'track_model.dart';

/// Payload for [TrackController.addFlag] (live) and track-detail flag APIs.
class AddFlagData {
  AddFlagData({
    required this.type,
    required this.description,
    required this.images,
    required this.coordinate,
    this.existingImageUrls = const [],
  });

  final String type;
  final String description;
  final List<XFile> images;
  final LatLng coordinate;
  /// Already-uploaded URLs kept when editing a flag on the server.
  final List<String> existingImageUrls;
}
