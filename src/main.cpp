// Lanzador de Ape Escape 3 (recomp nativo).
//
// Lee el config.ini que esta a su lado, comprueba que esten el ISO, el runtime y el
// ejecutable del juego, y arranca el runtime. Si algo falta, lo dice con un cuadro de
// dialogo en vez de cerrarse en silencio.

#include "config.hpp"
#include "launch.hpp"
#include "utf8.hpp"
#include "validate.hpp"

#include <windows.h>

#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>

namespace {

const wchar_t* const kTitle = L"Ape Escape 3";

void show_error(const std::string& message) {
    MessageBoxW(nullptr, to_wide(message).c_str(), kTitle, MB_OK | MB_ICONERROR);
}

// La carpeta donde esta este programa, sin el nombre del ejecutable.
std::string base_dir() {
    wchar_t path[MAX_PATH] = {};
    const DWORD len = GetModuleFileNameW(nullptr, path, MAX_PATH);
    if (len == 0 || len >= MAX_PATH) return ".";
    std::wstring wide(path, len);
    const std::size_t slash = wide.find_last_of(L'\\');
    if (slash == std::wstring::npos) return ".";
    return from_wide(wide.substr(0, slash));
}

bool read_file(const std::string& path, std::string& out) {
    std::ifstream file(path, std::ios::binary);
    if (!file) return false;
    std::ostringstream buffer;
    buffer << file.rdbuf();
    out = buffer.str();
    return true;
}

}  // namespace

int WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int) {
    const std::string base = base_dir();

    std::string text;
    if (!read_file(base + "\\config.ini", text)) {
        show_error("Falta config.ini junto a ApeEscape3.exe.\n\nSe espera un archivo config.ini "
                   "en la misma carpeta que este programa.");
        return 1;
    }

    const ConfigResult parsed = parse_config(text);
    if (!parsed.ok) {
        show_error(parsed.error);
        return 1;
    }

    const std::string problem = validate(parsed.config, base);
    if (!problem.empty()) {
        show_error(problem);
        return 1;
    }

    std::string error;
    if (!launch(parsed.config, base, error)) {
        show_error(error);
        return 1;
    }
    return 0;
}
