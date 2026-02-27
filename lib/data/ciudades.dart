// data/ciudades.dart
// Datos estáticos de regiones, ciudades y líneas de transporte

/// Lista de ciudades con su región y código
const List<Map<String, dynamic>> CIUDADES = [
  {
    "id": 1,
    "nombre": "Antofagasta",
    "region": "Antofagasta",
    "codigo_region": "II"
  },
  {"id": 2, "nombre": "Calama", "region": "Antofagasta", "codigo_region": "II"},
  {
    "id": 3,
    "nombre": "Tocopilla",
    "region": "Antofagasta",
    "codigo_region": "II"
  },
  {
    "id": 4,
    "nombre": "Mejillones",
    "region": "Antofagasta",
    "codigo_region": "II"
  },
  {"id": 5, "nombre": "Taltal", "region": "Antofagasta", "codigo_region": "II"},
  {"id": 6, "nombre": "Copiapó", "region": "Atacama", "codigo_region": "III"},
  {"id": 7, "nombre": "Vallenar", "region": "Atacama", "codigo_region": "III"},
  {"id": 8, "nombre": "Chañaral", "region": "Atacama", "codigo_region": "III"},
  {"id": 9, "nombre": "Caldera", "region": "Atacama", "codigo_region": "III"},
  {
    "id": 10,
    "nombre": "Tierra Amarilla",
    "region": "Atacama",
    "codigo_region": "III"
  },
  {
    "id": 11,
    "nombre": "La Serena",
    "region": "Coquimbo",
    "codigo_region": "IV"
  },
  {"id": 12, "nombre": "Coquimbo", "region": "Coquimbo", "codigo_region": "IV"},
  {"id": 13, "nombre": "Ovalle", "region": "Coquimbo", "codigo_region": "IV"},
  {"id": 14, "nombre": "Illapel", "region": "Coquimbo", "codigo_region": "IV"},
  {"id": 15, "nombre": "Vicuña", "region": "Coquimbo", "codigo_region": "IV"},
  {
    "id": 16,
    "nombre": "Monte Patria",
    "region": "Coquimbo",
    "codigo_region": "IV"
  },
  {
    "id": 17,
    "nombre": "Andacollo",
    "region": "Coquimbo",
    "codigo_region": "IV"
  },
];

/// Lista de regiones (para dropdown)
const List<Map<String, String>> REGIONES = [
  {"codigo": "II", "nombre": "Antofagasta"},
  {"codigo": "III", "nombre": "Atacama"},
  {"codigo": "IV", "nombre": "Coquimbo"},
];

/// Mapa de líneas por ciudad (usando nombre normalizado)
const Map<String, List<Map<String, String>>> LINEAS_POR_CIUDAD = {
  "antofagasta": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Centro - Bonilla"},
    {"id": "2", "nombre": "Línea 2", "descripcion": "Centro - La Portada"},
    {"id": "3", "nombre": "Línea 3", "descripcion": "Centro - Villa Exótica"},
    {
      "id": "4",
      "nombre": "Línea 4",
      "descripcion": "Centro - Ruinas de Huanchaca"
    },
    {"id": "5", "nombre": "Línea 5", "descripcion": "Centro - Norte Grande"},
    {"id": "101", "nombre": "Línea 101", "descripcion": "Troncal Norte-Sur"},
  ],
  "calama": [
    {"id": "A", "nombre": "Línea A", "descripcion": "Centro - Villa Ayquina"},
    {"id": "B", "nombre": "Línea B", "descripcion": "Centro - Villa Exótica"},
    {
      "id": "C",
      "nombre": "Línea C",
      "descripcion": "Centro - Valle de la Luna"
    },
    {"id": "D", "nombre": "Línea D", "descripcion": "Centro - Chuquicamata"},
  ],
  "tocopilla": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Centro - Población Norte"},
    {"id": "2", "nombre": "Línea 2", "descripcion": "Centro - Caleta Boy"},
  ],
  "mejillones": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Centro - Sector Norte"},
    {"id": "2", "nombre": "Línea 2", "descripcion": "Centro - Sector Sur"},
  ],
  "taltal": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Centro - Alto Taltal"},
  ],
  "copiapo": [
    {"id": "1", "nombre": "Línea 1", "descripcion": ""},
    {"id": "2", "nombre": "Línea 2", "descripcion": ""},
    {"id": "02", "nombre": "Línea 02", "descripcion": ""},
    {"id": "4", "nombre": "Línea 4", "descripcion": ""},
    {"id": "5", "nombre": "Línea 5", "descripcion": ""},
    {"id": "6", "nombre": "Línea 6", "descripcion": ""},
    {"id": "07", "nombre": "Línea 07", "descripcion": "", "color": "amarillo"},
    {"id": "07B", "nombre": "Línea 07B", "descripcion": "", "color": "blanco"},
    {"id": "11", "nombre": "Línea 11", "descripcion": ""},
    {"id": "20", "nombre": "Línea 20", "descripcion": ""},
    {"id": "21", "nombre": "Línea 21", "descripcion": ""},
    {"id": "22", "nombre": "Línea 22", "descripcion": ""},
    {"id": "23", "nombre": "Línea 23", "descripcion": ""},
    {"id": "24", "nombre": "Línea 24", "descripcion": ""},
    {"id": "26", "nombre": "Línea 26", "descripcion": ""},
    {"id": "66", "nombre": "Línea 66", "descripcion": ""},
    {"id": "076", "nombre": "Línea 076", "descripcion": "", "color": "verde"},
    {
      "id": "077",
      "nombre": "Línea 077",
      "descripcion": "",
      "color": "amarillo"
    },
    {"id": "77", "nombre": "Línea 77", "descripcion": ""},
  ],
  "vallenar": [
    {"id": "A", "nombre": "Línea A", "descripcion": "Centro - Alto del Carmen"},
    {
      "id": "B",
      "nombre": "Línea B",
      "descripcion": "Centro - Población Kennedy"
    },
    {"id": "C", "nombre": "Línea C", "descripcion": "Centro - Villa del Sol"},
  ],
  "chanaral": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Centro - Barrio Norte"},
  ],
  "caldera": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Centro - Playa Brava"},
    {"id": "2", "nombre": "Línea 2", "descripcion": "Centro - Bahía Inglesa"},
  ],
  "tierraamarilla": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Circuito Urbano"},
  ],
  "laserena": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Centro - Las Compañías"},
    {"id": "2", "nombre": "Línea 2", "descripcion": "Centro - Peñuelas"},
    {"id": "3", "nombre": "Línea 3", "descripcion": "Centro - San Joaquín"},
    {"id": "4", "nombre": "Línea 4", "descripcion": "Centro - Universidad"},
    {"id": "5", "nombre": "Línea 5", "descripcion": "Centro - La Antena"},
    {"id": "10", "nombre": "Línea 10", "descripcion": "La Serena - Coquimbo"},
  ],
  "coquimbo": [
    {"id": "C1", "nombre": "Línea C1", "descripcion": "Centro - Parte Alta"},
    {"id": "C2", "nombre": "Línea C2", "descripcion": "Centro - La Herradura"},
    {"id": "C3", "nombre": "Línea C3", "descripcion": "Centro - Guayacán"},
    {"id": "10", "nombre": "Línea 10", "descripcion": "Coquimbo - La Serena"},
  ],
  "ovalle": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Centro - La Chimba"},
    {"id": "2", "nombre": "Línea 2", "descripcion": "Centro - Limarí"},
    {"id": "3", "nombre": "Línea 3", "descripcion": "Centro - Tuquí"},
  ],
  "illapel": [
    {"id": "A", "nombre": "Línea A", "descripcion": "Centro - Alto Norte"},
    {"id": "B", "nombre": "Línea B", "descripcion": "Centro - Alto Sur"},
  ],
  "vicuna": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Centro - Peralillo"},
  ],
  "montepatria": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Circuito Urbano"},
  ],
  "andacollo": [
    {"id": "1", "nombre": "Línea 1", "descripcion": "Circuito Urbano"},
  ],
};

/// Normaliza un nombre de ciudad para usarlo como clave en LINEAS_POR_CIUDAD
String normalizeCityName(String name) {
  return name
      .toLowerCase()
      .replaceAll(' ', '')
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');
}
