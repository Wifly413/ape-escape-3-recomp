// La linea de comandos que se le pasa al runtime (ps2run).
#pragma once

#include "config.hpp"

#include <string>
#include <string_view>
#include <vector>

// Entrecomilla un argumento con las reglas de Windows (CommandLineToArgvW):
// sin comillas si no hace falta, y duplicando las barras invertidas que
// precede a una comilla o a la comilla de cierre.
std::string quote_argument(std::string_view arg);

// Los argumentos del runtime, en orden: el ejecutable del juego, --disc con la
// imagen, --game-dir con la carpeta del juego, --window, y --widescreen y
// --pal o --ntsc segun la configuracion.
std::vector<std::string> build_arguments(const Config& c, std::string_view elf_path,
                                         std::string_view game_dir);

// La linea de comandos completa: el programa y sus argumentos entrecomillados.
std::string join_command_line(std::string_view exe, const std::vector<std::string>& args);
