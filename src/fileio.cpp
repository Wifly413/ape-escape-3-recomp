#include "fileio.hpp"

#include <fstream>
#include <sstream>

std::filesystem::path to_path(std::string_view utf8) {
    // libc++ interpreta std::string como la pagina ANSI del sistema; con
    // std::u8string la ruta se toma como UTF-8, que es como la guardamos.
    const std::u8string text(reinterpret_cast<const char8_t*>(utf8.data()), utf8.size());
    return std::filesystem::path(text);
}

bool file_exists(const std::string& utf8_path) {
    std::error_code ec;
    return std::filesystem::exists(to_path(utf8_path), ec);
}

bool read_file(const std::string& utf8_path, std::string& out) {
    std::ifstream file(to_path(utf8_path), std::ios::binary);
    if (!file) return false;
    std::ostringstream buffer;
    buffer << file.rdbuf();
    out = buffer.str();
    return true;
}

bool write_file(const std::string& utf8_path, std::string_view text) {
    std::ofstream file(to_path(utf8_path), std::ios::binary | std::ios::trunc);
    if (!file) return false;
    file.write(text.data(), static_cast<std::streamsize>(text.size()));
    return file.good();
}
