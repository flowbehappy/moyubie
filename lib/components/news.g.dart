// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotedRecord _$PromotedRecordFromJson(Map<String, dynamic> json) =>
    PromotedRecord(
      DateTime.parse(json['at'] as String),
      (json['records'] as List<dynamic>)
          .map((e) => Promoted.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PromotedRecordToJson(PromotedRecord instance) =>
    <String, dynamic>{
      'at': instance.at.toIso8601String(),
      'records': instance.records,
    };

News _$NewsFromJson(Map<String, dynamic> json) => News(
      $enumDecode(_$_NewsSourceEnumMap, json['source']),
      json['id'] as int,
      json['url'] as String,
      json['title'] as String,
      json['content'] as String,
    );

Map<String, dynamic> _$NewsToJson(News instance) => <String, dynamic>{
      'source': _$_NewsSourceEnumMap[instance.source]!,
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'url': instance.url,
    };

const _$_NewsSourceEnumMap = {
  _NewsSource.HackerNews: 'HackerNews',
};

Promoted _$PromotedFromJson(Map<String, dynamic> json) => Promoted(
      News.fromJson(json['news'] as Map<String, dynamic>),
      json['reason'] as String,
    );

Map<String, dynamic> _$PromotedToJson(Promoted instance) => <String, dynamic>{
      'news': instance.news,
      'reason': instance.reason,
    };
