// Tests del lanzador. Cada CHECK es un comportamiento concreto.
#include "check.hpp"

#include "args.hpp"
#include "config.hpp"
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

    std::printf("tests: %d checks, %d failures\n", test::checks(), test::failures());
    return test::failures() == 0 ? 0 : 1;
}
