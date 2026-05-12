// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChannelCollection on Isar {
  IsarCollection<Channel> get channels => this.collection();
}

const ChannelSchema = CollectionSchema(
  name: r'Channel',
  id: 3096422491918372507,
  properties: {
    r'contentType': PropertySchema(
      id: 0,
      name: r'contentType',
      type: IsarType.byte,
      enumMap: _ChannelcontentTypeEnumValueMap,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'group': PropertySchema(
      id: 2,
      name: r'group',
      type: IsarType.string,
    ),
    r'groupTitle': PropertySchema(
      id: 3,
      name: r'groupTitle',
      type: IsarType.string,
    ),
    r'isFavorite': PropertySchema(
      id: 4,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'lastPlayed': PropertySchema(
      id: 5,
      name: r'lastPlayed',
      type: IsarType.dateTime,
    ),
    r'logo': PropertySchema(
      id: 6,
      name: r'logo',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 7,
      name: r'name',
      type: IsarType.string,
    ),
    r'playCount': PropertySchema(
      id: 8,
      name: r'playCount',
      type: IsarType.long,
    ),
    r'playlistId': PropertySchema(
      id: 9,
      name: r'playlistId',
      type: IsarType.long,
    ),
    r'rating': PropertySchema(
      id: 10,
      name: r'rating',
      type: IsarType.double,
    ),
    r'totalMilliseconds': PropertySchema(
      id: 11,
      name: r'totalMilliseconds',
      type: IsarType.long,
    ),
    r'tvgId': PropertySchema(
      id: 12,
      name: r'tvgId',
      type: IsarType.long,
    ),
    r'tvgLogo': PropertySchema(
      id: 13,
      name: r'tvgLogo',
      type: IsarType.string,
    ),
    r'tvgName': PropertySchema(
      id: 14,
      name: r'tvgName',
      type: IsarType.string,
    ),
    r'url': PropertySchema(
      id: 15,
      name: r'url',
      type: IsarType.string,
    ),
    r'watchedMilliseconds': PropertySchema(
      id: 16,
      name: r'watchedMilliseconds',
      type: IsarType.long,
    )
  },
  estimateSize: _channelEstimateSize,
  serialize: _channelSerialize,
  deserialize: _channelDeserialize,
  deserializeProp: _channelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _channelGetId,
  getLinks: _channelGetLinks,
  attach: _channelAttach,
  version: '3.1.0+1',
);

int _channelEstimateSize(
  Channel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.group;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.groupTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.logo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.tvgLogo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.tvgName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.url.length * 3;
  return bytesCount;
}

void _channelSerialize(
  Channel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByte(offsets[0], object.contentType.index);
  writer.writeString(offsets[1], object.description);
  writer.writeString(offsets[2], object.group);
  writer.writeString(offsets[3], object.groupTitle);
  writer.writeBool(offsets[4], object.isFavorite);
  writer.writeDateTime(offsets[5], object.lastPlayed);
  writer.writeString(offsets[6], object.logo);
  writer.writeString(offsets[7], object.name);
  writer.writeLong(offsets[8], object.playCount);
  writer.writeLong(offsets[9], object.playlistId);
  writer.writeDouble(offsets[10], object.rating);
  writer.writeLong(offsets[11], object.totalMilliseconds);
  writer.writeLong(offsets[12], object.tvgId);
  writer.writeString(offsets[13], object.tvgLogo);
  writer.writeString(offsets[14], object.tvgName);
  writer.writeString(offsets[15], object.url);
  writer.writeLong(offsets[16], object.watchedMilliseconds);
}

Channel _channelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Channel();
  object.contentType =
      _ChannelcontentTypeValueEnumMap[reader.readByteOrNull(offsets[0])] ??
          ContentType.live;
  object.description = reader.readStringOrNull(offsets[1]);
  object.group = reader.readStringOrNull(offsets[2]);
  object.groupTitle = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.isFavorite = reader.readBool(offsets[4]);
  object.lastPlayed = reader.readDateTimeOrNull(offsets[5]);
  object.logo = reader.readStringOrNull(offsets[6]);
  object.name = reader.readString(offsets[7]);
  object.playCount = reader.readLong(offsets[8]);
  object.playlistId = reader.readLongOrNull(offsets[9]);
  object.rating = reader.readDouble(offsets[10]);
  object.totalMilliseconds = reader.readLong(offsets[11]);
  object.tvgId = reader.readLongOrNull(offsets[12]);
  object.tvgLogo = reader.readStringOrNull(offsets[13]);
  object.tvgName = reader.readStringOrNull(offsets[14]);
  object.url = reader.readString(offsets[15]);
  object.watchedMilliseconds = reader.readLong(offsets[16]);
  return object;
}

P _channelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_ChannelcontentTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          ContentType.live) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ChannelcontentTypeEnumValueMap = {
  'live': 0,
  'movie': 1,
  'series': 2,
};
const _ChannelcontentTypeValueEnumMap = {
  0: ContentType.live,
  1: ContentType.movie,
  2: ContentType.series,
};

Id _channelGetId(Channel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _channelGetLinks(Channel object) {
  return [];
}

void _channelAttach(IsarCollection<dynamic> col, Id id, Channel object) {
  object.id = id;
}

extension ChannelQueryWhereSort on QueryBuilder<Channel, Channel, QWhere> {
  QueryBuilder<Channel, Channel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChannelQueryWhere on QueryBuilder<Channel, Channel, QWhereClause> {
  QueryBuilder<Channel, Channel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Channel, Channel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Channel, Channel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Channel, Channel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ChannelQueryFilter
    on QueryBuilder<Channel, Channel, QFilterCondition> {
  QueryBuilder<Channel, Channel, QAfterFilterCondition> contentTypeEqualTo(
      ContentType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentType',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> contentTypeGreaterThan(
    ContentType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contentType',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> contentTypeLessThan(
    ContentType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contentType',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> contentTypeBetween(
    ContentType lower,
    ContentType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contentType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'group',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'group',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'group',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'group',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'group',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'group',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupTitle',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupTitle',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'groupTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'groupTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> groupTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> isFavoriteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> lastPlayedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastPlayed',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> lastPlayedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastPlayed',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> lastPlayedEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastPlayed',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> lastPlayedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastPlayed',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> lastPlayedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastPlayed',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> lastPlayedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastPlayed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'logo',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'logo',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'logo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'logo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logo',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> logoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'logo',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'playCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'playCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'playCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'playCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playlistIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'playlistId',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playlistIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'playlistId',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playlistIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'playlistId',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playlistIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'playlistId',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playlistIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'playlistId',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> playlistIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'playlistId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> ratingEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> ratingGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rating',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> ratingLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rating',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> ratingBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rating',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition>
      totalMillisecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalMilliseconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition>
      totalMillisecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalMilliseconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition>
      totalMillisecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalMilliseconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition>
      totalMillisecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalMilliseconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tvgId',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tvgId',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tvgId',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tvgId',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tvgId',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tvgId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tvgLogo',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tvgLogo',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tvgLogo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tvgLogo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tvgLogo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tvgLogo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tvgLogo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tvgLogo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tvgLogo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tvgLogo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tvgLogo',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgLogoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tvgLogo',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tvgName',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tvgName',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tvgName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tvgName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tvgName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tvgName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tvgName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tvgName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tvgName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tvgName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tvgName',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> tvgNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tvgName',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition> urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition>
      watchedMillisecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'watchedMilliseconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition>
      watchedMillisecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'watchedMilliseconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition>
      watchedMillisecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'watchedMilliseconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Channel, Channel, QAfterFilterCondition>
      watchedMillisecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'watchedMilliseconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ChannelQueryObject
    on QueryBuilder<Channel, Channel, QFilterCondition> {}

extension ChannelQueryLinks
    on QueryBuilder<Channel, Channel, QFilterCondition> {}

extension ChannelQuerySortBy on QueryBuilder<Channel, Channel, QSortBy> {
  QueryBuilder<Channel, Channel, QAfterSortBy> sortByContentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByContentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'group', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'group', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByGroupTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupTitle', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByGroupTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupTitle', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByLastPlayed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayed', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByLastPlayedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayed', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByPlayCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByPlayCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByPlaylistId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playlistId', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByPlaylistIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playlistId', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByTotalMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMilliseconds', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByTotalMillisecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMilliseconds', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByTvgId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgId', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByTvgIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgId', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByTvgLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgLogo', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByTvgLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgLogo', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByTvgName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgName', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByTvgNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgName', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByWatchedMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedMilliseconds', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> sortByWatchedMillisecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedMilliseconds', Sort.desc);
    });
  }
}

extension ChannelQuerySortThenBy
    on QueryBuilder<Channel, Channel, QSortThenBy> {
  QueryBuilder<Channel, Channel, QAfterSortBy> thenByContentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByContentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'group', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'group', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByGroupTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupTitle', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByGroupTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupTitle', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByLastPlayed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayed', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByLastPlayedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayed', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByPlayCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByPlayCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playCount', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByPlaylistId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playlistId', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByPlaylistIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playlistId', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByTotalMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMilliseconds', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByTotalMillisecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMilliseconds', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByTvgId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgId', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByTvgIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgId', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByTvgLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgLogo', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByTvgLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgLogo', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByTvgName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgName', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByTvgNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tvgName', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByWatchedMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedMilliseconds', Sort.asc);
    });
  }

  QueryBuilder<Channel, Channel, QAfterSortBy> thenByWatchedMillisecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedMilliseconds', Sort.desc);
    });
  }
}

extension ChannelQueryWhereDistinct
    on QueryBuilder<Channel, Channel, QDistinct> {
  QueryBuilder<Channel, Channel, QDistinct> distinctByContentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentType');
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByGroup(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'group', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByGroupTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByLastPlayed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastPlayed');
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByLogo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'logo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByPlayCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'playCount');
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByPlaylistId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'playlistId');
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rating');
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByTotalMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalMilliseconds');
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByTvgId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tvgId');
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByTvgLogo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tvgLogo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByTvgName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tvgName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Channel, Channel, QDistinct> distinctByWatchedMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'watchedMilliseconds');
    });
  }
}

extension ChannelQueryProperty
    on QueryBuilder<Channel, Channel, QQueryProperty> {
  QueryBuilder<Channel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Channel, ContentType, QQueryOperations> contentTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentType');
    });
  }

  QueryBuilder<Channel, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<Channel, String?, QQueryOperations> groupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'group');
    });
  }

  QueryBuilder<Channel, String?, QQueryOperations> groupTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupTitle');
    });
  }

  QueryBuilder<Channel, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<Channel, DateTime?, QQueryOperations> lastPlayedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastPlayed');
    });
  }

  QueryBuilder<Channel, String?, QQueryOperations> logoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logo');
    });
  }

  QueryBuilder<Channel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Channel, int, QQueryOperations> playCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'playCount');
    });
  }

  QueryBuilder<Channel, int?, QQueryOperations> playlistIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'playlistId');
    });
  }

  QueryBuilder<Channel, double, QQueryOperations> ratingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rating');
    });
  }

  QueryBuilder<Channel, int, QQueryOperations> totalMillisecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalMilliseconds');
    });
  }

  QueryBuilder<Channel, int?, QQueryOperations> tvgIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tvgId');
    });
  }

  QueryBuilder<Channel, String?, QQueryOperations> tvgLogoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tvgLogo');
    });
  }

  QueryBuilder<Channel, String?, QQueryOperations> tvgNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tvgName');
    });
  }

  QueryBuilder<Channel, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }

  QueryBuilder<Channel, int, QQueryOperations> watchedMillisecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'watchedMilliseconds');
    });
  }
}
