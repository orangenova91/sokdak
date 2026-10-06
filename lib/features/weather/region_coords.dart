/// 프로필 지역 코드별 대표 좌표(시·도청/중심 근처). Open-Meteo 조회용.
class RegionCoords {
  const RegionCoords({required this.lat, required this.lon});

  final double lat;
  final double lon;
}

const regionCoordsByCode = <String, RegionCoords>{
  'seoul': RegionCoords(lat: 37.5665, lon: 126.9780),
  'busan': RegionCoords(lat: 35.1796, lon: 129.0756),
  'daegu': RegionCoords(lat: 35.8714, lon: 128.6014),
  'incheon': RegionCoords(lat: 37.4563, lon: 126.7052),
  'gwangju': RegionCoords(lat: 35.1595, lon: 126.8526),
  'daejeon': RegionCoords(lat: 36.3504, lon: 127.3845),
  'ulsan': RegionCoords(lat: 35.5384, lon: 129.3114),
  'sejong': RegionCoords(lat: 36.4800, lon: 127.2890),
  'gyeonggi': RegionCoords(lat: 37.2636, lon: 127.0286),
  'gangwon': RegionCoords(lat: 37.8813, lon: 127.7298),
  'chungbuk': RegionCoords(lat: 36.6424, lon: 127.4890),
  'chungnam': RegionCoords(lat: 36.5184, lon: 126.8000),
  'jeonbuk': RegionCoords(lat: 35.8242, lon: 127.1480),
  'jeonnam': RegionCoords(lat: 34.8161, lon: 126.4629),
  'gyeongbuk': RegionCoords(lat: 36.5760, lon: 128.5056),
  'gyeongnam': RegionCoords(lat: 35.2383, lon: 128.6924),
  'jeju': RegionCoords(lat: 33.4996, lon: 126.5312),
};
