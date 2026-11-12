// Lectura del config.ini del lanzador.
#pragma once

#include <string>
#include <string_view>

// Lo que el lanzador necesita saber para arrancar el juego.
struct Config {
    std::string iso;                           // ruta absoluta al .iso del juego
    std::string runtime = "runtime";           // relativa a la carpeta del .exe
    std::string game = "game";                 // relativa a la carpeta del .exe
    std::string elf = "disc/SCES_536.42";      // relativa a la carpeta del juego
    std::string title = "Ape Escape 3";        // titulo de la ventana del juego
    bool widescreen = false;
    bool pal = true;
};

struct ConfigResult {
    bool ok = false;
    std::string error;  // vacio si todo esta bien
    Config config;
};

// Lee un config.ini. Acepta BOM UTF-8, CRLF, lineas vacias y comentarios con ';' o '#'.
// Las claves se pueden escribir con '=' o ':', y no distinguen mayusculas.
ConfigResult parse_config(std::string_view text);
