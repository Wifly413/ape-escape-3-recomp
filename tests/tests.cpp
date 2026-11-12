// Tests del lanzador. Cada CHECK es un comportamiento concreto.
#include "check.hpp"

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

    std::printf("tests: %d checks, %d failures\n", test::checks(), test::failures());
    return test::failures() == 0 ? 0 : 1;
}
