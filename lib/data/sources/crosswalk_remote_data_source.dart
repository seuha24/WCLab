part of data_source;

abstract class CrosswalkRemoteDataSource {
  Future<List<CrosswalkModel>> getCrosswalks(
    List<DiscoveredDevice> results,
    LatLng position,
  );
}

class CrosswalkRemoteDataSourceImpl implements CrosswalkRemoteDataSource {
  FirebaseFirestore firestore;
  Distance distance;

  CrosswalkRemoteDataSourceImpl({
    required this.firestore,
    required this.distance,
  });

  Map<String, dynamic> _getDirectionAndPosition(
    var geo1,
    var geo2,
    LatLng pos,
  ) {
    LatLng pos1 = LatLng(geo1['geo'].latitude, geo1['geo'].longitude);
    LatLng pos2 = LatLng(geo2['geo'].latitude, geo2['geo'].longitude);

    double meter1 = distance(pos, pos1);
    double meter2 = distance(pos, pos2);

    if (meter1 > meter2) {
      return {'pos': pos1, 'dir': geo1['dir']};
    } else if (meter1 < meter2) {
      return {'pos': pos2, 'dir': geo2['dir']};
    }
    return {'pos': null, 'dir': null};
  }

  @override
  Future<List<CrosswalkModel>> getCrosswalks(
    List<DiscoveredDevice> lists,
    LatLng position,
  ) async {
    try {
      Set<CrosswalkModel> temps = {};
      List<CrosswalkModel> results = [];

      Iterator<DiscoveredDevice> post = lists.iterator;

      if (CrosswalkAPI.map.isEmpty) {
        CollectionReference collectionRef =
            firestore.collection('safelight_db');
        QuerySnapshot querySnapshot = await collectionRef.get();
        CrosswalkAPI.map = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      }

      while (post.moveNext()) {
        bool isFind = false;

        for (var map in CrosswalkAPI.map) {
          if (map.containsValue(post.current.name)) {
            var geo1 = map['pos'][0];
            var geo2 = map['pos'][1];

            Map<String, dynamic> pos = _getDirectionAndPosition(
              geo1,
              geo2,
              position,
            );
            temps.add(
              CrosswalkModel.fromMap({
                'name': map['name'],
                'post': post.current,
                'type': ECrosswalk.values[map['type']],
                'dir': pos['dir'],
                'pos': pos['pos'],
              }),
            );
            isFind = true;
            break;
          }
        }
        if (isFind) {
          continue;
        }
        results.add(
          CrosswalkModel.fromMap({
            'post': post.current,
            'dir': null,
            'pos': null,
          }),
        );
      }
      results.insertAll(0, temps.toList());
      return results;
    } catch (e) {
      throw ServerException();
    }
  }
}
