// ignore_for_file: unused_length, unused_import, unnecessary_cast, unused_element, no_leading_underscores_for_local_identifiers, check_suitability, preserve_referential_equality, filter_hole

import 'package:isar_community/isar.dart';
import 'note.dart';

final NoteSchema = CollectionSchema<Note>(
  name: r'Note',
  id: 6284318083599466921,
  properties: {
    r'content': PropertySchema(
      id: 0,
      name: r'content',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isFavorite': PropertySchema(
      id: 2,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'linkedNoteIds': PropertySchema(
      id: 3,
      name: r'linkedNoteIds',
      type: IsarType.longList,
    ),
    r'processingScore': PropertySchema(
      id: 4,
      name: r'processingScore',
      type: IsarType.double,
    ),
    r'state': PropertySchema(
      id: 5,
      name: r'state',
      type: IsarType.byte,
    ),
    r'tags': PropertySchema(
      id: 6,
      name: r'tags',
      type: IsarType.stringList,
    ),
    r'title': PropertySchema(
      id: 7,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _noteEstimateSize,
  serialize: _noteSerialize,
  deserialize: _noteDeserialize,
  deserializeProp: _noteDeserializeProp,
  idName: r'id',
  indexes: {
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'tags': IndexSchema(
      id: 4029205728550669204,
      name: r'tags',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'tags',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: (Note object) => object.id,
  getLinks: (Note object) => [],
  attach: (IsarCollection<Note> col, Id id, Note object) {
    object.id = id;
  },
  version: '3.3.0', // Must match Isar.version
);

int _noteEstimateSize(Note object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  {
    final list = object.linkedNoteIds;
    if (list != null) {
      bytesCount += 3 + list.length * 8;
    }
  }
  {
    final list = object.tags;
    if (list != null) {
      bytesCount += 3;
      for (var value in list) {
        bytesCount += value.length * 3 + 3;
      }
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _noteSerialize(Note object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeString(offsets[0], object.content);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeBool(offsets[2], object.isFavorite);
  writer.writeLongList(offsets[3], object.linkedNoteIds);
  writer.writeDouble(offsets[4], object.processingScore ?? 0.0);
  writer.writeByte(offsets[5], object.state.index);
  writer.writeStringList(offsets[6], object.tags);
  writer.writeString(offsets[7], object.title);
  writer.writeDateTime(offsets[8], object.updatedAt);
}

Note _noteDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = Note();
  object.content = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.isFavorite = reader.readBool(offsets[2]);
  object.linkedNoteIds = reader.readLongList(offsets[3]);
  object.processingScore = reader.readDoubleOrNull(offsets[4]);
  final stateByte = reader.readByte(offsets[5]);
  object.state = NoteState.values[stateByte % NoteState.values.length];
  object.tags = reader.readStringList(offsets[6]);
  object.title = reader.readString(offsets[7]);
  object.updatedAt = reader.readDateTime(offsets[8]);
  return object;
}

dynamic _noteDeserializeProp(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset));
    case 1:
      return (reader.readDateTime(offset));
    case 2:
      return (reader.readBool(offset));
    case 3:
      return (reader.readLongList(offset));
    case 4:
      return (reader.readDoubleOrNull(offset));
    case 5:
      return (NoteState.values[reader.readByte(offset) % NoteState.values.length]);
    case 6:
      return (reader.readStringList(offset));
    case 7:
      return (reader.readString(offset));
    case 8:
      return (reader.readDateTime(offset));
    default:
      throw UnsupportedError('Unknown property with id $propertyId');
  }
}
