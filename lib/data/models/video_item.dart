class VideoItem {
final String id;
final String title;
final String url;
final String? thumbnail;


const VideoItem({
required this.id,
required this.title,
required this.url,
this.thumbnail,
});


factory VideoItem.fromJson(Map<String, dynamic> json) {
return VideoItem(
id: json['id'] as String,
title: json['title'] as String,
url: json['url'] as String,
thumbnail: json['thumbnail'] as String?,
);
}
}