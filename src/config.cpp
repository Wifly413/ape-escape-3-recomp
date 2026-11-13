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
        // 'scale' y cualquier clave desconocida se ignoran aqui.
    }

    if (result.config.iso.empty()) {
        result.ok = false;
        result.error = "config.ini: falta la clave iso";
    }
    return result;
}

std::string set_iso_line(std::string_view text, std::string_view iso_path) {
    std::string out;
    std::size_t pos = 0;

    // El BOM UTF-8 se conserva: Notepad lo pone y el parser lo acepta.
    if (text.size() >= 3 && static_cast<unsigned char>(text[0]) == 0xEF &&
        static_cast<unsigned char>(text[1]) == 0xBB && static_cast<unsigned char>(text[2]) == 0xBF) {
        out.append(text.substr(0, 3));
        pos = 3;
    }

    bool replaced = false;
    while (pos < text.size()) {
        const std::size_t newline = text.find('\n', pos);
        const std::size_t stop = newline == std::string_view::npos ? text.size() : newline + 1;
        const std::string_view raw = text.substr(pos, stop - pos);

        // Cuerpo de la linea sin el salto, para poder devolverlo tal cual si no es la
        // clave que buscamos.
        std::string_view body = raw;
        std::string eol;
        if (!body.empty() && body.back() == '\n') {
            body.remove_suffix(1);
            eol = "\n";
            if (!body.empty() && body.back() == '\r') {
                body.remove_suffix(1);
                eol = "\r\n";
            }
        }

        const std::string_view trimmed = trim(body);
        bool is_iso = false;
        if (!trimmed.empty() && trimmed.front() != ';' && trimmed.front() != '#') {
            const std::size_t sep = trimmed.find_first_of("=:");
            if (sep != std::string_view::npos && lower(trim(trimmed.substr(0, sep))) == "iso") {
                is_iso = true;
            }
        }

        if (is_iso && !replaced) {
            out += "iso=";
            out += iso_path;
            out += eol;
            replaced = true;
        } else {
            out.append(raw);
        }
        pos = stop;
    }

    if (!replaced) {
        if (!out.empty() && out.back() != '\n') out += "\r\n";
        out += "iso=";
        out += iso_path;
        out += "\r\n";
    }
    return out;
}
