// Tests del lanzador. Cada CHECK es un comportamiento concreto.
#include "check.hpp"

#include "args.hpp"
#include "config.hpp"
#include "fileio.hpp"
#include "utf8.hpp"
#include "validate.hpp"

#include <cstdio>
#include <filesystem>
#include <fstream>
#include <string>

namespace {

void write_empty(const std::filesystem::path& path) {
    std::ofstream file(path, std::ios::binary);
    file << "";
}

// La ruta tal y como la guarda el programa: UTF-8.
std::string utf8_of(const std::filesystem::path& path) {
    const std::u8string text = path.u8string();
    return std::string(text.begin(), text.end());
}

}  // namespace

int main() {
    CHECK(parse_config("iso=D:\\games\\a.iso\n").config.iso == "D:\\games\\a.iso");
    CHECK(parse_config("\xEF\xBB\xBFiso=C:\\x.iso\r\n").ok);  // BOM + CRLF
    CHECK(parse_config("; comentario\n# otro\niso=x\n").ok);   // comentarios
    CHECK(!parse_config("runtime=x\n").ok);                   // sin iso
    CHECK(parse_config("iso=x\nwidescreen=1\n").config.widescreen);
    CHECK(parse_config("iso=x\nwidescreen=0\n").config.widescreen == false);
    CHECK(parse_config("iso=x\npal=0\n").config.pal == false);
    CHECK(parse_config("iso=x\ntitle=Ape Escape 3\n").config.title == "Ape Escape 3");
    CHECK(parse_config("  iso = x  \n").config.iso == "x");   // espacios alrededor
    CHECK(parse_config("iso=x\ndesconocida=1\n").ok);         // clave ajena: se ignora

    // --- Tarea 2: la linea de comandos del runtime ---
    CHECK(quote_argument("simple") == "simple");
    CHECK(quote_argument("con espacio") == "\"con espacio\"");
    CHECK(quote_argument("A (B) (C,D)") == "\"A (B) (C,D)\"");
    CHECK(quote_argument("") == "\"\"");
    CHECK(quote_argument("C:\\dir\\") == "C:\\dir\\");               // sin espacios no se entrecomilla
    CHECK(quote_argument("C:\\dir\\ x") == "\"C:\\dir\\ x\"");       // la barra se queda como esta
    CHECK(quote_argument("C:\\dir x\\") == "\"C:\\dir x\\\\\"");     // la barra del final se duplica

    Config c;
    c.iso = "D:\\games\\Ape Escape 3 (Europe) (En,Fr,De,Es,It).iso";
    c.widescreen = true;
    c.pal = true;
    const auto a = build_arguments(c, "G:\\game\\disc\\SCES_536.42", "G:\\game");
    CHECK(a.at(0) == "G:\\game\\disc\\SCES_536.42");
    CHECK(a.at(1) == "--disc");
    CHECK(a.at(2) == c.iso);
    CHECK(a.at(3) == "--game-dir");
    CHECK(a.at(4) == "G:\\game");
    const std::string line = join_command_line("C:\\rt\\ps2run.exe", a);
    CHECK(line.find("\"D:\\games\\Ape Escape 3 (Europe) (En,Fr,De,Es,It).iso\"") != std::string::npos);
    CHECK(line.find("--widescreen") != std::string::npos);
    CHECK(line.find("--pal") != std::string::npos);

    // --- Tarea 3: rutas y comprobaciones antes de arrancar ---
    CHECK(resolve("C:\\a", "runtime") == "C:\\a\\runtime");
    CHECK(resolve("C:\\a\\", "runtime") == "C:\\a\\runtime");
    CHECK(resolve("C:\\a", "C:\\abs") == "C:\\abs");
    CHECK(resolve("C:\\a", "game\\disc\\SCES_536.42") == "C:\\a\\game\\disc\\SCES_536.42");

    const auto tmp = std::filesystem::temp_directory_path() / "ape3-launcher-tests";
    std::filesystem::remove_all(tmp);
    std::filesystem::create_directories(tmp / "runtime");
    std::filesystem::create_directories(tmp / "game" / "disc");
    write_empty(tmp / "a.iso");
    write_empty(tmp / "runtime" / "ps2run.exe");
    write_empty(tmp / "game" / "disc" / "SCES_536.42");

    Config ok;
    ok.iso = (tmp / "a.iso").string();
    CHECK(validate(ok, tmp.string()).empty());

    Config no_iso = ok;
    no_iso.iso = (tmp / "no-existe.iso").string();
    CHECK(validate(no_iso, tmp.string()).find("ISO") != std::string::npos);

    Config no_runtime = ok;
    std::filesystem::remove(tmp / "runtime" / "ps2run.exe");
    CHECK(validate(no_runtime, tmp.string()).find("runtime") != std::string::npos);

    Config no_elf = ok;
    write_empty(tmp / "runtime" / "ps2run.exe");  // lo quitamos antes: hay que volver a ponerlo
    no_elf.elf = "disc/NO-EXISTE.ELF";
    CHECK(validate(no_elf, tmp.string()).find("NO-EXISTE.ELF") != std::string::npos);

    // Un ISO relativo se resuelve contra la carpeta del .exe, no contra el
    // directorio desde el que se lanzo el programa.
    write_empty(tmp / "otra-imagen.iso");
    Config iso_relativo;
    iso_relativo.iso = "otra-imagen.iso";
    CHECK(validate(iso_relativo, tmp.string()).empty());

    // --- Tarea 4: conversion de UTF-8 a UTF-16 ---
    CHECK(to_wide("Programación") == L"Programación");
    CHECK(to_wide("D:\\games\\ñandú") == L"D:\\games\\ñandú");
    CHECK(from_wide(to_wide("Ape Escape 3")) == "Ape Escape 3");
    CHECK(from_wide(to_wide("")) == "");

    // --- Revision final: rutas con espacios y con acentos ---
    // El .exe puede estar en "D:\Proyectos Programacion": si su ruta no va
    // entrecomillada, Windows parte la linea y los argumentos se desplazan.
    const std::string spaced = join_command_line("C:\\carpeta con espacio\\ps2run.exe", a);
    CHECK(spaced.rfind("\"C:\\carpeta con espacio\\ps2run.exe\" ", 0) == 0);
    CHECK(join_command_line("C:\\rt\\ps2run.exe", a).rfind("C:\\rt\\ps2run.exe ", 0) == 0);

    // Las rutas internas son UTF-8; el sistema de archivos no entiende de ANSI.
    const auto acentos = tmp / "Programaci\u00f3n";
    std::filesystem::create_directories(acentos / "runtime");
    std::filesystem::create_directories(acentos / "game" / "disc");
    {
        std::ofstream file(acentos / "iso.txt", std::ios::binary);
        file << "hola";
    }
    write_empty(acentos / "runtime" / "ps2run.exe");
    write_empty(acentos / "game" / "disc" / "SCES_536.42");

    const std::string acentos_utf8 = utf8_of(acentos);
    CHECK(file_exists(acentos_utf8 + "\\iso.txt"));
    CHECK(!file_exists(acentos_utf8 + "\\no-existe.txt"));
    std::string content;
    CHECK(read_file(acentos_utf8 + "\\iso.txt", content));
    CHECK(content == "hola");
    CHECK(!read_file(acentos_utf8 + "\\no-existe.txt", content));

    Config acentuado;
    acentuado.iso = acentos_utf8 + "\\iso.txt";
    CHECK(validate(acentuado, acentos_utf8).empty());

    std::printf("tests: %d checks, %d failures\n", test::checks(), test::failures());
    return test::failures() == 0 ? 0 : 1;
}
