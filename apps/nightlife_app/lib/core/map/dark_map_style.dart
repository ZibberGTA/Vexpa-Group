class DarkMapStyle {
  static const String json = '''
[
  {"elementType":"geometry","stylers":[{"color":"#111218"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#F5F5F7"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#111218"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2A1841"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#F5F5F7"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#171A24"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#242B3A"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#B8B8C8"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#222A3A"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#44516B"},{"weight":0.35}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#F5F5F7"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1D2330"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#171923"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#07080D"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#6E5B8F"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#111218"}]},
  {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#15101F"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#0F1118"}]}
]
''';
}
