#include "validate.hpp"

#include "fileio.hpp"

namespace {

bool is_absolute(const std::string& path) {
    if (path.size() >= 2 && path[1] == ':') return true;   // C:\algo
    if (!path.empty() && (path[0] == '\\' || path[0] == '/')) return true;  // \\servidor o \raiz
    return false;
}

std::string join(const std::string& base, const std::string& path) {
    if (base.empty()) return path;
    std::string out = base;
    while (!out.empty() && (out.back() == '\\' || out.back() == '/')) out.pop_back();
    out.push_back('\\');
    out += path;
    return out;
}

bool exists(const std::string& path) {
    return file_exists(path);
}

}  // namespace

std::string resolve(const std::string& base_dir, const std::string& path) {
    if (path.empty()) return base_dir;
    if (is_absolute(path)) return path;
    return join(base_dir, path);
}

std::string validate(const Config& c, const std::string& base_dir) {
    if (c.iso.empty()) return "config.ini: falta la clave iso";
    const std::string iso = resolve(base_dir, c.iso);
    if (!exists(iso)) {
        return "No se encuentra el ISO del juego:\n" + iso +
               "\n\nAl arrancar, el lanzador pregunta por la imagen con un dialogo: si lo has "
               "cancelado, vuelve a abrirlo con doble clic. Tambien puedes poner la ruta en la "
               "clave 'iso' del config.ini.";
    }

    const std::string runtime = resolve(base_dir, c.runtime) + "\\ps2run.exe";
    if (!exists(runtime)) {
        return "No se encuentra el runtime del juego:\n" + runtime +
               "\n\nLa carpeta 'runtime' tiene que estar junto a este programa.";
    }

    const std::string elf = join(resolve(base_dir, c.game), c.elf);
    if (!exists(elf)) {
        return "No se encuentra el ejecutable del juego:\n" + elf +
               "\n\nLa carpeta 'game' tiene que estar junto a este programa.";
    }
    return "";
}
