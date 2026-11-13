// Selector de archivos de Windows, para volver a preguntar por la imagen del disco
// cuando la ruta del config.ini ya no lleva a ninguna parte.
#pragma once

#include <string>

// Abre el dialogo de Windows para elegir la imagen. Devuelve la ruta UTF-8 elegida, o
// vacia si el usuario cancela. La carpeta de partida es la del ISO actual, si la hay.
std::string choose_iso(const std::string& current_iso);
