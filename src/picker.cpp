#include "picker.hpp"

#include "utf8.hpp"

#include <windows.h>

#include <commdlg.h>

#include <cstddef>
#include <string>

namespace {

// La carpeta del ISO actual, para que el dialogo se abra donde estaba. Si la ruta no
// tiene carpeta (o esta vacia), se deja que Windows elija.
std::wstring start_dir(const std::string& current_iso) {
    const std::size_t slash = current_iso.find_last_of("\\/");
    if (slash == std::string::npos) return {};
    return to_wide(current_iso.substr(0, slash));
}

}  // namespace

std::string choose_iso(const std::string& current_iso) {
    // Una ruta larga no cabe en MAX_PATH; el buffer se pide holgado y el dialogo no
    // cambia la carpeta de trabajo del proceso (OFN_NOCHANGEDIR).
    std::wstring file(32768, L'\0');
    OPENFILENAMEW ofn{};
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = nullptr;
    ofn.lpstrFilter = L"Imagenes de disco (*.iso;*.bin)\0*.iso;*.bin\0Todos los archivos (*.*)\0*.*\0";
    ofn.lpstrFile = file.data();
    ofn.nMaxFile = static_cast<DWORD>(file.size());
    ofn.lpstrTitle = L"Elige la imagen del disco de Ape Escape 3 (PAL)";
    const std::wstring start = start_dir(current_iso);
    ofn.lpstrInitialDir = start.empty() ? nullptr : start.c_str();
    ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_NOCHANGEDIR | OFN_EXPLORER;

    // El dialogo moderno es COM; si el hilo ya tenia otro modelo, se sigue igual.
    const HRESULT com = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    const BOOL picked = GetOpenFileNameW(&ofn);
    if (SUCCEEDED(com)) CoUninitialize();

    if (!picked) return {};
    return from_wide(file.c_str());
}
