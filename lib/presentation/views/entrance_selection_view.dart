part of '../../framework/ui.dart';

class EntranceSelectionView extends StatelessWidget {
  const EntranceSelectionView({super.key, required this.buildingResponse});

  final BuildingResponse buildingResponse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("출입구 선택"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${buildingResponse.buildingName}의 출입구 선택",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: buildingResponse.entrances.length,
                itemBuilder: (context, index) {
                  final entrance = buildingResponse.entrances[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(entrance.entranceName),
                      onTap: () {
                        Navigator.pop(context, entrance);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
