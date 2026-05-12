// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epg.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEpgChannelCollection on Isar {
  IsarCollection<EpgChannel> get epgChannels => this.collection();
}

const EpgChannelSchema = CollectionSchema(
  name: r'EpgChannel',
  id: 5761410378486424843,
  properties: {
    r'channelId': PropertySchema(
      id: 0,
      name: r'channelId',
      type: IsarType.string,
    ),
    r'displayName': PropertySchema(
      id: 1,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'icon': PropertySchema(
      id: 2,
      name: r'icon',
      type: IsarType.string,
    )
  },
  estimateSize: _epgChannelEstimateSize,
  serialize: _epgChannelSerialize,
  deserialize: _epgChannelDeserialize,
  deserializeProp: _epgChannelDeserializeProp,
  idName: r'id',
  indexes: {
    r'channelId': IndexSchema(
      id: -8352446570702114471,
      name: r'channelId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'channelId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _epgChannelGetId,
  getLinks: _epgChannelGetLinks,
  attach: _epgChannelAttach,
  version: '3.1.0+1',
);

int _epgChannelEstimateSize(
  EpgChannel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.channelId.length * 3;
  {
    final value = object.displayName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.icon;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _epgChannelSerialize(
  EpgChannel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.channelId);
  writer.writeString(offsets[1], object.displayName);
  writer.writeString(offsets[2], object.icon);
}

EpgChannel _epgChannelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EpgChannel();
  object.channelId = reader.readString(offsets[0]);
  object.displayName = reader.readStringOrNull(offsets[1]);
  object.icon = reader.readStringOrNull(offsets[2]);
  object.id = id;
  return object;
}

P _epgChannelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _epgChannelGetId(EpgChannel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _epgChannelGetLinks(EpgChannel object) {
  return [];
}

void _epgChannelAttach(IsarCollection<dynamic> col, Id id, EpgChannel object) {
  object.id = id;
}

extension EpgChannelByIndex on IsarCollection<EpgChannel> {
  Future<EpgChannel?> getByChannelId(String channelId) {
    return getByIndex(r'channelId', [channelId]);
  }

  EpgChannel? getByChannelIdSync(String channelId) {
    return getByIndexSync(r'channelId', [channelId]);
  }

  Future<bool> deleteByChannelId(String channelId) {
    return deleteByIndex(r'channelId', [channelId]);
  }

  bool deleteByChannelIdSync(String channelId) {
    return deleteByIndexSync(r'channelId', [channelId]);
  }

  Future<List<EpgChannel?>> getAllByChannelId(List<String> channelIdValues) {
    final values = channelIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'channelId', values);
  }

  List<EpgChannel?> getAllByChannelIdSync(List<String> channelIdValues) {
    final values = channelIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'channelId', values);
  }

  Future<int> deleteAllByChannelId(List<String> channelIdValues) {
    final values = channelIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'channelId', values);
  }

  int deleteAllByChannelIdSync(List<String> channelIdValues) {
    final values = channelIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'channelId', values);
  }

  Future<Id> putByChannelId(EpgChannel object) {
    return putByIndex(r'channelId', object);
  }

  Id putByChannelIdSync(EpgChannel object, {bool saveLinks = true}) {
    return putByIndexSync(r'channelId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByChannelId(List<EpgChannel> objects) {
    return putAllByIndex(r'channelId', objects);
  }

  List<Id> putAllByChannelIdSync(List<EpgChannel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'channelId', objects, saveLinks: saveLinks);
  }
}

extension EpgChannelQueryWhereSort
    on QueryBuilder<EpgChannel, EpgChannel, QWhere> {
  QueryBuilder<EpgChannel, EpgChannel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EpgChannelQueryWhere
    on QueryBuilder<EpgChannel, EpgChannel, QWhereClause> {
  QueryBuilder<EpgChannel, EpgChannel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<EpgChannel, EpgChannel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterWhereClause> idBetween(
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

  QueryBuilder<EpgChannel, EpgChannel, QAfterWhereClause> channelIdEqualTo(
      String channelId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'channelId',
        value: [channelId],
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterWhereClause> channelIdNotEqualTo(
      String channelId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channelId',
              lower: [],
              upper: [channelId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channelId',
              lower: [channelId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channelId',
              lower: [channelId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channelId',
              lower: [],
              upper: [channelId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension EpgChannelQueryFilter
    on QueryBuilder<EpgChannel, EpgChannel, QFilterCondition> {
  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> channelIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      channelIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> channelIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> channelIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'channelId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      channelIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> channelIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> channelIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> channelIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'channelId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      channelIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'channelId',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      channelIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'channelId',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'displayName',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'displayName',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'icon',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'icon',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'icon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'icon',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> iconIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<EpgChannel, EpgChannel, QAfterFilterCondition> idBetween(
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
}

extension EpgChannelQueryObject
    on QueryBuilder<EpgChannel, EpgChannel, QFilterCondition> {}

extension EpgChannelQueryLinks
    on QueryBuilder<EpgChannel, EpgChannel, QFilterCondition> {}

extension EpgChannelQuerySortBy
    on QueryBuilder<EpgChannel, EpgChannel, QSortBy> {
  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> sortByChannelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channelId', Sort.asc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> sortByChannelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channelId', Sort.desc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> sortByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> sortByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }
}

extension EpgChannelQuerySortThenBy
    on QueryBuilder<EpgChannel, EpgChannel, QSortThenBy> {
  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> thenByChannelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channelId', Sort.asc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> thenByChannelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channelId', Sort.desc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> thenByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> thenByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension EpgChannelQueryWhereDistinct
    on QueryBuilder<EpgChannel, EpgChannel, QDistinct> {
  QueryBuilder<EpgChannel, EpgChannel, QDistinct> distinctByChannelId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'channelId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QDistinct> distinctByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgChannel, EpgChannel, QDistinct> distinctByIcon(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'icon', caseSensitive: caseSensitive);
    });
  }
}

extension EpgChannelQueryProperty
    on QueryBuilder<EpgChannel, EpgChannel, QQueryProperty> {
  QueryBuilder<EpgChannel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EpgChannel, String, QQueryOperations> channelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'channelId');
    });
  }

  QueryBuilder<EpgChannel, String?, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<EpgChannel, String?, QQueryOperations> iconProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'icon');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEpgProgramCollection on Isar {
  IsarCollection<EpgProgram> get epgPrograms => this.collection();
}

const EpgProgramSchema = CollectionSchema(
  name: r'EpgProgram',
  id: -322960372056809736,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'channelId': PropertySchema(
      id: 1,
      name: r'channelId',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'durationMinutes': PropertySchema(
      id: 3,
      name: r'durationMinutes',
      type: IsarType.long,
    ),
    r'endTime': PropertySchema(
      id: 4,
      name: r'endTime',
      type: IsarType.dateTime,
    ),
    r'episode': PropertySchema(
      id: 5,
      name: r'episode',
      type: IsarType.string,
    ),
    r'formattedEndTime': PropertySchema(
      id: 6,
      name: r'formattedEndTime',
      type: IsarType.string,
    ),
    r'formattedStartTime': PropertySchema(
      id: 7,
      name: r'formattedStartTime',
      type: IsarType.string,
    ),
    r'formattedTimeRange': PropertySchema(
      id: 8,
      name: r'formattedTimeRange',
      type: IsarType.string,
    ),
    r'icon': PropertySchema(
      id: 9,
      name: r'icon',
      type: IsarType.string,
    ),
    r'isNowPlaying': PropertySchema(
      id: 10,
      name: r'isNowPlaying',
      type: IsarType.bool,
    ),
    r'progress': PropertySchema(
      id: 11,
      name: r'progress',
      type: IsarType.double,
    ),
    r'rating': PropertySchema(
      id: 12,
      name: r'rating',
      type: IsarType.string,
    ),
    r'startTime': PropertySchema(
      id: 13,
      name: r'startTime',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(
      id: 14,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _epgProgramEstimateSize,
  serialize: _epgProgramSerialize,
  deserialize: _epgProgramDeserialize,
  deserializeProp: _epgProgramDeserializeProp,
  idName: r'id',
  indexes: {
    r'channelId': IndexSchema(
      id: -8352446570702114471,
      name: r'channelId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'channelId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _epgProgramGetId,
  getLinks: _epgProgramGetLinks,
  attach: _epgProgramAttach,
  version: '3.1.0+1',
);

int _epgProgramEstimateSize(
  EpgProgram object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.channelId.length * 3;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.episode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.formattedEndTime.length * 3;
  bytesCount += 3 + object.formattedStartTime.length * 3;
  bytesCount += 3 + object.formattedTimeRange.length * 3;
  {
    final value = object.icon;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.rating;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _epgProgramSerialize(
  EpgProgram object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.channelId);
  writer.writeString(offsets[2], object.description);
  writer.writeLong(offsets[3], object.durationMinutes);
  writer.writeDateTime(offsets[4], object.endTime);
  writer.writeString(offsets[5], object.episode);
  writer.writeString(offsets[6], object.formattedEndTime);
  writer.writeString(offsets[7], object.formattedStartTime);
  writer.writeString(offsets[8], object.formattedTimeRange);
  writer.writeString(offsets[9], object.icon);
  writer.writeBool(offsets[10], object.isNowPlaying);
  writer.writeDouble(offsets[11], object.progress);
  writer.writeString(offsets[12], object.rating);
  writer.writeDateTime(offsets[13], object.startTime);
  writer.writeString(offsets[14], object.title);
}

EpgProgram _epgProgramDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EpgProgram();
  object.category = reader.readStringOrNull(offsets[0]);
  object.channelId = reader.readString(offsets[1]);
  object.description = reader.readStringOrNull(offsets[2]);
  object.endTime = reader.readDateTime(offsets[4]);
  object.episode = reader.readStringOrNull(offsets[5]);
  object.icon = reader.readStringOrNull(offsets[9]);
  object.id = id;
  object.rating = reader.readStringOrNull(offsets[12]);
  object.startTime = reader.readDateTime(offsets[13]);
  object.title = reader.readString(offsets[14]);
  return object;
}

P _epgProgramDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _epgProgramGetId(EpgProgram object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _epgProgramGetLinks(EpgProgram object) {
  return [];
}

void _epgProgramAttach(IsarCollection<dynamic> col, Id id, EpgProgram object) {
  object.id = id;
}

extension EpgProgramQueryWhereSort
    on QueryBuilder<EpgProgram, EpgProgram, QWhere> {
  QueryBuilder<EpgProgram, EpgProgram, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EpgProgramQueryWhere
    on QueryBuilder<EpgProgram, EpgProgram, QWhereClause> {
  QueryBuilder<EpgProgram, EpgProgram, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterWhereClause> idBetween(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterWhereClause> channelIdEqualTo(
      String channelId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'channelId',
        value: [channelId],
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterWhereClause> channelIdNotEqualTo(
      String channelId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channelId',
              lower: [],
              upper: [channelId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channelId',
              lower: [channelId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channelId',
              lower: [channelId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channelId',
              lower: [],
              upper: [channelId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension EpgProgramQueryFilter
    on QueryBuilder<EpgProgram, EpgProgram, QFilterCondition> {
  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> categoryContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> categoryMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> channelIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      channelIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> channelIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> channelIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'channelId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      channelIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> channelIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> channelIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'channelId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> channelIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'channelId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      channelIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'channelId',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      channelIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'channelId',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionEqualTo(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionGreaterThan(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionLessThan(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionBetween(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionStartsWith(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionEndsWith(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      durationMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      durationMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      durationMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      durationMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> endTimeEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      endTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> endTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> endTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> episodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'episode',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      episodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'episode',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> episodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'episode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      episodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'episode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> episodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'episode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> episodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'episode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> episodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'episode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> episodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'episode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> episodeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'episode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> episodeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'episode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> episodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'episode',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      episodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'episode',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedEndTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formattedEndTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formattedEndTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formattedEndTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formattedEndTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formattedEndTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formattedEndTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formattedEndTime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedEndTime',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedEndTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formattedEndTime',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedStartTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formattedStartTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formattedStartTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formattedStartTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formattedStartTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formattedStartTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formattedStartTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formattedStartTime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedStartTime',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedStartTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formattedStartTime',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedTimeRange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formattedTimeRange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formattedTimeRange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formattedTimeRange',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formattedTimeRange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formattedTimeRange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formattedTimeRange',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formattedTimeRange',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedTimeRange',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      formattedTimeRangeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formattedTimeRange',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'icon',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'icon',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'icon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'icon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'icon',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> iconIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'icon',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> idBetween(
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

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      isNowPlayingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isNowPlaying',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> progressEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      progressGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> progressLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> progressBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rating',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      ratingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rating',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rating',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rating',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> ratingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      ratingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rating',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> startTimeEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      startTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> startTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> startTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension EpgProgramQueryObject
    on QueryBuilder<EpgProgram, EpgProgram, QFilterCondition> {}

extension EpgProgramQueryLinks
    on QueryBuilder<EpgProgram, EpgProgram, QFilterCondition> {}

extension EpgProgramQuerySortBy
    on QueryBuilder<EpgProgram, EpgProgram, QSortBy> {
  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByChannelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channelId', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByChannelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channelId', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      sortByDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByEpisode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episode', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByEpisodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episode', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByFormattedEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedEndTime', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      sortByFormattedEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedEndTime', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      sortByFormattedStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedStartTime', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      sortByFormattedStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedStartTime', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      sortByFormattedTimeRange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTimeRange', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      sortByFormattedTimeRangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTimeRange', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByIsNowPlaying() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNowPlaying', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByIsNowPlayingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNowPlaying', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension EpgProgramQuerySortThenBy
    on QueryBuilder<EpgProgram, EpgProgram, QSortThenBy> {
  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByChannelId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channelId', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByChannelIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channelId', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      thenByDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByEpisode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episode', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByEpisodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episode', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByFormattedEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedEndTime', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      thenByFormattedEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedEndTime', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      thenByFormattedStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedStartTime', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      thenByFormattedStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedStartTime', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      thenByFormattedTimeRange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTimeRange', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy>
      thenByFormattedTimeRangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTimeRange', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByIsNowPlaying() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNowPlaying', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByIsNowPlayingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNowPlaying', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension EpgProgramQueryWhereDistinct
    on QueryBuilder<EpgProgram, EpgProgram, QDistinct> {
  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByChannelId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'channelId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMinutes');
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByEpisode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'episode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByFormattedEndTime(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formattedEndTime',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByFormattedStartTime(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formattedStartTime',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByFormattedTimeRange(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formattedTimeRange',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByIcon(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'icon', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByIsNowPlaying() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isNowPlaying');
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progress');
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByRating(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rating', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<EpgProgram, EpgProgram, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension EpgProgramQueryProperty
    on QueryBuilder<EpgProgram, EpgProgram, QQueryProperty> {
  QueryBuilder<EpgProgram, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EpgProgram, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<EpgProgram, String, QQueryOperations> channelIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'channelId');
    });
  }

  QueryBuilder<EpgProgram, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<EpgProgram, int, QQueryOperations> durationMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMinutes');
    });
  }

  QueryBuilder<EpgProgram, DateTime, QQueryOperations> endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<EpgProgram, String?, QQueryOperations> episodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'episode');
    });
  }

  QueryBuilder<EpgProgram, String, QQueryOperations>
      formattedEndTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formattedEndTime');
    });
  }

  QueryBuilder<EpgProgram, String, QQueryOperations>
      formattedStartTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formattedStartTime');
    });
  }

  QueryBuilder<EpgProgram, String, QQueryOperations>
      formattedTimeRangeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formattedTimeRange');
    });
  }

  QueryBuilder<EpgProgram, String?, QQueryOperations> iconProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'icon');
    });
  }

  QueryBuilder<EpgProgram, bool, QQueryOperations> isNowPlayingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isNowPlaying');
    });
  }

  QueryBuilder<EpgProgram, double, QQueryOperations> progressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progress');
    });
  }

  QueryBuilder<EpgProgram, String?, QQueryOperations> ratingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rating');
    });
  }

  QueryBuilder<EpgProgram, DateTime, QQueryOperations> startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<EpgProgram, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
