// Lanzador de Ape Escape 3 (recomp nativo).
//
// Lee el config.ini que esta a su lado, comprueba que esten el ISO, el runtime y el
// ejecutable del juego, y arranca el runtime. Si algo falta, lo dice con un cuadro de
// dialogo en vez de cerrarse en silencio.

#include "config.hpp"
#include "fileio.hpp"
#include "launch.hpp"
#include "picker.hpp"
#include "utf8.hpp"
#include "validate.hpp"

#include <windows.h>

#include <string>

namespace {

const wchar_t* const kTitle = L"Ape Escape 3";

void show_error(const std::string& message) {
    MessageBoxW(nullptr, to_wide(message).c_str(), kTitle, MB_OK | MB_ICONERROR);
}

// La carpeta donde esta este programa, sin el nombre del ejecutable. El buffer
// crece si la ruta no cabe: con MAX_PATH fijo, una ruta larga acababa usando la
// carpeta de trabajo en vez de la del .exe sin avisar.
std::string base_dir(bool& ok) {
    std::wstring wide(MAX_PATH, L'\0');
    for (;;) {
        const DWORD len = GetModuleFileNameW(nullptr, wide.data(), static_cast<DWORD>(wide.size()));
        if (len == 0) {
            ok = false;
            return {};
        }
        if (len < wide.size()) {
            wide.resize(len);
            break;
        }
        wide.resize(wide.size() * 2);  // no cabia: se pide el doble
    }

    const std::size_t slash = wide.find_last_of(L'\\');
    if (slash == std::wstring::npos) {
        ok = false;
        return {};
    }
    ok = true;
    return from_wide(std::wstring(wide.data(), slash));
}

}  // namespace

int WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int) {
    bool located = false;
    const std::string base = base_dir(located);
    if (!located) {
        show_error("No se pudo averiguar la carpeta donde esta ApeEscape3.exe "
                   "(error de Windows " + std::to_string(GetLastError()) + ").");
        return 1;
    }

    std::string text;
    const std::string config_path = base + "\\config.ini";
    if (!read_file(config_path, text)) {
        if (file_exists(config_path)) {
            show_error("No se puede leer config.ini:\n" + config_path +
                       "\n\nExiste, pero Windows no deja abrirlo. Comprueba que no lo tenga "
                       "abierto otro programa y que tengas permiso para leerlo.");
        } else {
            show_error("Falta config.ini junto a ApeEscape3.exe.\n\nSe espera un archivo "
                       "config.ini en la misma carpeta que este programa.");
        }
        return 1;
    }

    const ConfigResult parsed = parse_config(text);
    if (!parsed.ok) {
        show_error(parsed.error);
        return 1;
    }

    // La ruta del ISO se resuelve ya contra la carpeta del .exe para que
    // valga igual desde el Explorador que desde un acceso directo.
    Config config = parsed.config;
    config.iso = resolve(base, config.iso);

    // Si la imagen ya no esta donde decia el config.ini (la movieron, la renombraron o
    // cambio la letra de la unidad), se pregunta por ella en vez de rendirse, y la ruta
    // nueva se guarda para la proxima vez: nadie tiene que editar el archivo a mano.
    if (!config.iso.empty() && !file_exists(config.iso)) {
        const std::string chosen = choose_iso(config.iso);
        if (!chosen.empty()) {
            config.iso = chosen;
            // Si no se puede escribir (carpeta de solo lectura) se juega igual y se
            // volvera a preguntar la proxima vez; no se molesta con otro cuadro.
            static_cast<void>(write_file(config_path, set_iso_line(text, chosen)));
        }
    }

    const std::string problem = validate(config, base);
    if (!problem.empty()) {
        show_error(problem);
        return 1;
    }

    std::string error;
    if (!launch(config, base, error)) {
        show_error(error);
        return 1;
    }
    return 0;
}
