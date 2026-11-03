class SesionLocal {
  static final Set<String> misionesCompletadas = {};
  

  static String? aliasJugador;
  static int? idParticipacionActual; 
  
  static void reiniciarSesion() {
    misionesCompletadas.clear();
    aliasJugador = null;
    idParticipacionActual = null;
  }
}