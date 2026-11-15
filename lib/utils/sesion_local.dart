class SesionLocal {
  static final Set<String> misionesCompletadas = {};
  
  static String? aliasJugador;
  static int? idParticipacionActual; 
  static String? idStandActual; 
  
  // Limpia solo los datos del jugador (cuando pasa el celular al siguiente turno)
  static void reiniciarJugador() {
    misionesCompletadas.clear();
    aliasJugador = null;
    idParticipacionActual = null;
  }

  // Limpia absolutamente todo (solo cuando tocamos el botón rojo de apagar)
  static void desconectarStand() {
    reiniciarJugador();
    idStandActual = null; 
  }
}