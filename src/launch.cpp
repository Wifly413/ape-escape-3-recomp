#include "launch.hpp"

#include "args.hpp"
#include "utf8.hpp"
#include "validate.hpp"

#include <windows.h>

#include <algorithm>
#include <string>

namespace {

// El entorno del proceso con una variable mas: el titulo de la ventana del juego.
std::wstring environment_with_title(const std::string& title) {
    wchar_t* block = GetEnvironmentStringsW();
    if (block == nullptr) return {};

    std::size_t len = 0;
    while (block[len] != L'\0' || block[len + 1] != L'\0') ++len;
    std::wstring env(block, len);
    LocalFree(block);

    env.push_back(L'\0');
    env += L"PS2_WINDOW_TITLE=";
    env += to_wide(title);
    env.push_back(L'\0');
    env.push_back(L'\0');
    return env;
}

}  // namespace

bool launch(const Config& c, const std::string& base_dir, std::string& error) {
    const std::string exe = resolve(base_dir, c.runtime) + "\\ps2run.exe";
    const std::string game_dir = resolve(base_dir, c.game);
    std::string elf_rel = c.elf;
    std::replace(elf_rel.begin(), elf_rel.end(), '/', '\\');
    const std::string elf = game_dir + "\\" + elf_rel;

    std::wstring command = to_wide(join_command_line(exe, build_arguments(c, elf, game_dir)));
    std::wstring runtime_dir = to_wide(resolve(base_dir, c.runtime));
    std::wstring env = environment_with_title(c.title);

    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process{};

    const BOOL ok = CreateProcessW(to_wide(exe).c_str(), command.data(), nullptr, nullptr, FALSE,
                                    CREATE_UNICODE_ENVIRONMENT, env.data(), runtime_dir.c_str(), &startup,
                                    &process);
    if (!ok) {
        error = "No se pudo arrancar el juego (error de Windows " + std::to_string(GetLastError()) +
                ").";
        return false;
    }
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return true;
}
