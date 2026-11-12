#include "config.hpp"

#include <algorithm>
#include <cctype>

namespace {

std::string_view trim(std::string_view s) {
    const auto is_space = [](unsigned char c) { return std::isspace(c) != 0; };
    while (!s.empty() && is_space(static_cast<unsigned char>(s.front()))) s.remove_prefix(1);
    while (!s.empty() && is_space(static_cast<unsigned char>(s.back()))) s.remove_suffix(1);
    return s;
}

std::string lower(std::string_view s) {
    std::string out(s);
    std::transform(out.begin(), out.end(), out.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return out;
}

bool to_bool(const std::string &value) {
    const std::string v = lower(value);
    return v == "1" || v == "true" || v == "yes" || v == "on" || v == "si";
}

}  // namespace

ConfigResult parse_config(std::string_view text) {
    ConfigResult result;
    result.ok = true;

    // El BOM UTF-8 que pone Notepad al principio.
    if (text.size() >= 3 && static_cast<unsigned char>(text[0]) == 0xEF &&
        static_cast<unsigned char>(text[1]) == 0xBB && static_cast<unsigned char>(text[2]) == 0xBF) {
        text.remove_prefix(3);
    }

    std::size_t pos = 0;
    while (pos <= text.size()) {
        const std::size_t end = text.find('\n', pos);
        const std::string_view line = trim(text.substr(pos, end == std::string_view::npos
                                                               ? std::string_view::npos
                                                               : end - pos));
        pos = end == std::string_view::npos ? text.size() + 1 : end + 1;

        if (line.empty() || line.front() == ';' || line.front() == '#') continue;

        const std::size_t sep = line.find_first_of("=:");
        if (sep == std::string_view::npos) continue;  // linea sin clave: se ignora

        const std::string key = lower(trim(line.substr(0, sep)));
        const std::string value(trim(line.substr(sep + 1)));

        if (key == "iso") {
            result.config.iso = value;
        } else if (key == "runtime") {
            result.config.runtime = value;
        } else if (key == "game") {
            result.config.game = value;
        } else if (key == "elf") {
            result.config.elf = value;
        } else if (key == "title") {
            result.config.title = value;
        } else if (key == "widescreen") {
            result.config.widescreen = to_bool(value);
        } else if (key == "pal") {
            result.config.pal = to_bool(value);
        }
        // 'scale' y cualquier clave que nohers no hacen nada aqui.
    }

    if (result.config.iso.empty()) {
        result.ok = false;
        result.error = "config.ini: falta la clave iso";
    }
    return result;
}
