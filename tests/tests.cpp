// Tests del lanzador. Cada CHECK es un comportamiento concreto.
#include "check.hpp"

#include "args.hpp"
#include "config.hpp"

#include <cstdio>

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

    std::printf("tests: %d checks, %d failures\n", test::checks(), test::failures());
    return test::failures() == 0 ? 0 : 1;
}
