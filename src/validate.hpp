// Comprobaciones de las rutas antes de arrancar el juego.
#pragma once

#include "config.hpp"

#include <string>

// Junta una ruta con la carpeta base. Si la ruta ya es absoluta, se queda como esta.
std::string resolve(const std::string& base_dir, const std::string& path);

// Mira que esten el ISO, el runtime y el ejecutable del juego. Devuelve una cadena
// vacia si esta todo, o el mensaje en español de lo que falta.
std::string validate(const Config& c, const std::string& base_dir);
