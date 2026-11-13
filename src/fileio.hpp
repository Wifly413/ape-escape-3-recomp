// Acceso a archivos con rutas UTF-8 (las que se guardan en config.ini).
#pragma once

#include <filesystem>
#include <string>
#include <string_view>

// Camino del sistema de archivos a partir de una ruta UTF-8.
std::filesystem::path to_path(std::string_view utf8);

// True si la ruta existe.
bool file_exists(const std::string& utf8_path);

// Lee el archivo entero. Devuelve false si no se puede abrir.
bool read_file(const std::string& utf8_path, std::string& out);

// Escribe el archivo entero (UTF-8 tal cual, sin BOM anadido). False si no se puede.
bool write_file(const std::string& utf8_path, std::string_view text);
