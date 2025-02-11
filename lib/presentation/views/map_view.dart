import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:safelight/framework/core.dart';
import 'package:safelight/presentation/controllers/map_view_controller.dart';
import 'package:safelight/framework/ui.dart';
import 'package:vibration/vibration.dart'; // StartSearch, DesSearch 페이지 등

class NaverMapView extends GetView<NaverMapViewController> {
  const NaverMapView({super.key});

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 생성 및 등록
    final NaverMapViewController controller = Get.put(NaverMapViewController());

    final box = Hive.box(SystemTheme.themeBox);
    final mode = box.get(SystemTheme.mode);
    final systemBright = MediaQuery.of(context).platformBrightness;
    bool isDark = (mode == 'dark') ||
        (mode == 'system' && systemBright == Brightness.dark);

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            return controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : SizedBox.shrink();
          }),
          NaverMap(
            options: NaverMapViewOptions(
              indoorEnable: true,
              initialCameraPosition: NCameraPosition(
                target: NLatLng(
                  controller.current_latitude.value,
                  controller.current_longitude.value,
                ),
                zoom: 18.5,
                bearing: controller.compassValue.value,
                tilt: 0,
              ),
              mapType: NMapType.basic,
              activeLayerGroups: [
                NLayerGroup.building,
                NLayerGroup.transit,
              ],
              locationButtonEnable: false,
              // scrollGesturesEnable: true,
              // zoomGesturesEnable: true,
              // rotationGesturesEnable: true,
            ),
            onMapReady: (naverMapController) {
              debugPrint('네이버 맵 로딩됨');
              controller.mapController = naverMapController;
              controller.updateMapPosition(
                controller.current_latitude.value,
                controller.current_longitude.value,
                controller.compassValue.value,
              );
            },
            onMapTapped: (NPoint point, NLatLng latLng) {
              int meters = (controller.remain_distance.value * 1000).round();
              controller.speakText('다음 안내까지 ${meters}미터 남았습니다.');
              // 필요 시 추가 처리...
            },
          ),
          // 출발지 검색 입력창
          Positioned(
            top: 65.0,
            left: 20.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 190, 164, 164),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(
                onTap: () async {
                  // 출발지 검색 페이지로 이동
                  GeoLocation? newStart = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => StartSearch(searchValue: controller.searchLocation.value),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = 0.0;
                        const end = 1.0;
                        const curve = Curves.easeInOutQuart;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var fadeAnimation = animation.drive(tween);
                        return FadeTransition(opacity: fadeAnimation, child: child);
                      },
                    ),
                  );
                  if (newStart != null) {
                    debugPrint('@@@@@@@@@@@@@@');
                    debugPrint('newStart : $newStart');
                    controller.startSelectedLocation.value = newStart;
                    controller.isStart.value = true;

                    debugPrint('controller.startSelectedLocation.value : ${controller.startSelectedLocation.value}');
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.6),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      controller.searchLocation.value.isEmpty ?
                      Text(
                        '출발지를 입력하세요.',
                        style:
                        TextStyle(fontSize: 17, color: Colors.grey),
                      ) :
                      Text(
                        controller.searchLocation.value,
                        style: TextStyle(fontSize: 17, color: Colors.black),
                      ),
                      Spacer(),
                      Icon(Icons.search),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 목적지 검색 입력창
          Positioned(
            top: 118.0,
            left: 20.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 190, 164, 164),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(
                onTap: () async {
                  GeoLocation? newDest = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => DesSearch(destinationValue: controller.destinationLocation.value),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = 0.0;
                        const end = 1.0;
                        const curve = Curves.easeInOutQuart;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var fadeAnimation = animation.drive(tween);
                        return FadeTransition(opacity: fadeAnimation, child: child);
                      },
                    ),
                  );
                  if (newDest != null) {
                    controller.selectedLocation.value = newDest;
                    if (controller.isStart.value) {
                      await controller.getGeometry(controller.startSelectedLocation.value!.lat, controller.startSelectedLocation.value!.lng);
                    } else {
                      await controller.getGeometry(controller.current_latitude.value, controller.current_longitude.value);
                    }
                    // branchinfo의 bearing 값 업데이트
                    for (int i = 0; i < controller.branchinfo.length - 1; i++) {
                      double newBearingValue = controller.calculateBearing(
                        controller.branchinfo[i].point.latitude,
                        controller.branchinfo[i].point.longitude,
                        controller.branchinfo[i + 1].point.latitude,
                        controller.branchinfo[i + 1].point.longitude,
                      );
                      controller.branchinfo[i].bearingToPoint = newBearingValue;
                    }
                    controller.yawRate2 = controller.turnUpdate2(
                        controller.branchinfo[controller.targetIndex].bearingToPoint,
                        controller.compassValue.value) *
                        controller.angleToRadian;
                    // 타이머를 통한 경로 안내 시작
                    Timer.periodic(Duration(seconds: 2), (timer) async {
                      controller.checkBoundary();
                      controller.indexUpdate();
                      controller.remain_startpoint = controller.calculateDistance(
                        controller.current_latitude.value,
                        controller.current_longitude.value,
                        controller.branchinfo[0].point.latitude,
                        controller.branchinfo[0].point.longitude,
                      );
                      if (controller.remain_startpoint < 0.015) {
                        controller.isStart.value = false;
                      }
                      if (!controller.isStart.value) {
                        if (controller.branchinfo.isNotEmpty && controller.targetIndex < controller.branchinfo.length) {
                          controller.branchTargetIndex = controller.targetIndex;
                          while (controller.branchTargetIndex < controller.branchinfo.length &&
                              !controller.branchinfo[controller.branchTargetIndex].branch) {
                            controller.branchTargetIndex++;
                          }
                          if (controller.branchinfo[controller.branchTargetIndex].branch) {
                            controller.remain_distance.value = controller.calculateDistance(
                              controller.current_latitude.value,
                              controller.current_longitude.value,
                              controller.branchinfo[controller.branchTargetIndex].point.latitude,
                              controller.branchinfo[controller.branchTargetIndex].point.longitude,
                            );
                            controller.clock = controller.getGuidanceDirection(
                              controller.branchinfo[controller.currentIndex].point.longitude,
                              controller.branchinfo[controller.currentIndex].point.latitude,
                              controller.branchinfo[controller.targetIndex].point.longitude,
                              controller.branchinfo[controller.targetIndex].point.latitude,
                              controller.current_latitude.value,
                              controller.current_longitude.value,
                              controller.yawRateTurn2,
                              controller.branchinfo[controller.currentIndex].bearingToPoint,
                            );
                          }
                        } else {
                          debugPrint("branchinfo 리스트가 비어 있거나 targetIndex가 유효하지 않습니다.");
                        }
                        if (controller.remain_distance.value < 0.015) {
                          if (controller.branchinfo[controller.currentIndex].crosswalk == true) {
                            final result = await controller.flashOnWithWeather(NoParams());
                            if (result.isLeft()) {
                              debugPrint('안전 경광등을 사용할 수 없습니다.');
                            } else {
                              debugPrint('안전 경광등이 켜졌습니다.');
                            }
                            controller.speakText('잠시 후 횡단보도 입니다. 차량에 유의하세요!');
                          }
                          if (controller.branchinfo[controller.targetIndex].branch == true) {
                            controller.speakText('${controller.branchinfo[controller.targetIndex].description}하세요.');
                          }
                        }
                        if (controller.currentIndex > 0 &&
                            ((controller.branchinfo[controller.currentIndex].bearingToPoint - controller.compassValue.value).abs() <= 18 ||
                                (controller.branchinfo[controller.currentIndex].bearingToPoint - controller.compassValue.value).abs() >= 342)) {
                          Vibration.vibrate(duration: 200);
                          debugPrint("경로내 진동 베어링 값 ${(controller.branchinfo[controller.currentIndex].bearingToPoint - controller.compassValue.value)}");
                        }
                        if (controller.outOfBound) {
                          Vibration.vibrate(duration: 100);
                          debugPrint('경계이탈');
                          debugPrint('searchNewPath : ${controller.searchNewPath}');
                          controller.speakText(controller.clock);
                          if (controller.searchNewPath) {
                            controller.searchNewPathTime++;
                            if (controller.searchNewPathTime >= 5) {
                              await controller.getGeometry(controller.current_latitude.value, controller.current_longitude.value);
                              controller.speakText("경로를 이탈하여 새로운 경로로 안내합니다.");
                              controller.searchNewPathTime = 0;
                            }
                          } else {
                            controller.searchNewPathTime = 0;
                          }
                        }
                      } else if (controller.isStart.value) {
                        controller.speakText("출발지로 이동하세요.");
                      }
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.6),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      controller.destinationLocation.value.isEmpty ?
                      Text(
                        '목적지를 입력하세요.',
                        style:TextStyle(fontSize: 17, color: Colors.grey),
                      )
                          : Text(
                        controller.destinationLocation.value,
                        style:
                        TextStyle(fontSize: 17),
                      ),
                      Spacer(),
                      Icon(Icons.search),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}