#include "args.hpp"

namespace {

bool needs_quotes(std::string_view arg) {
    return arg.empty() || arg.find_first_of(" \t\n\v\"") != std::string_view::npos;
}

}  // namespace

std::string quote_argument(std::string_view arg) {
    if (!needs_quotes(arg)) return std::string(arg);

    std::string out;
    out.push_back('"');
    std::size_t bars = 0;  // barras invertidas pendientes
    for (const char c : arg) {
        if (c == '\\') {
            ++bars;
            continue;
        }
        if (c == '"') {
            out.append(bars * 2 + 1, '\\');  // duplica las barras y escapa la comilla
            out.push_back('"');
            bars = 0;
            continue;
        }
        out.append(bars, '\\');
        bars = 0;
        out.push_back(c);
    }
    out.append(bars * 2, '\\');  // las barras del final se duplican antes de cerrar
    out.push_back('"');
    return out;
}

std::vector<std::string> build_arguments(const Config& c, std::string_view elf_path,
                                         std::string_view game_dir) {
    std::vector<std::string> args;
    args.emplace_back(elf_path);
    args.emplace_back("--disc");
    args.emplace_back(c.iso);
    args.emplace_back("--game-dir");
    args.emplace_back(game_dir);
    args.emplace_back("--window");
    if (c.widescreen) args.emplace_back("--widescreen");
    args.emplace_back(c.pal ? "--pal" : "--ntsc");
    return args;
}

std::string join_command_line(std::string_view exe, const std::vector<std::string>& args) {
    // El programa tambien se entrecomilla: si la carpeta tiene espacios
    // ("D:\Proyectos Programacion"), Windows partiria la ruta y desplazaria
    // todos los argumentos.
    std::string line = quote_argument(exe);
    for (const std::string& arg : args) {
        line.push_back(' ');
        line += quote_argument(arg);
    }
    return line;
}
