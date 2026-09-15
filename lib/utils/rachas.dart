/// Días de racha o de Reto 21 que se consideran un hito real y merecen
/// celebrarse. Se usa tanto en "Hoy" (Reto 21) como en "Progreso" (racha de
/// días registrados) para no repetir el mismo número mágico en dos lados.
///
/// Investigación: los momentos de celebración retienen más cuando son
/// escasos y están ligados a hitos reales, no a cada registro.
const List<int> hitosRacha = [3, 7, 14, 21];

bool esHitoRacha(int dias) => hitosRacha.contains(dias);
