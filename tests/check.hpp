// CHECK para los tests: cuenta los fallos y dice donde esta cada uno.
#pragma once

#include <cstdio>

namespace test {

inline int &checks() {
    static int n = 0;
    return n;
}

inline int &failures() {
    static int n = 0;
    return n;
}

inline void report(bool ok, const char *expr, const char *file, int line) {
    ++checks();
    if (!ok) {
        ++failures();
        std::printf("FALLO %s:%d: %s\n", file, line, expr);
    }
}

}  // namespace test

#define CHECK(cond) test::report(static_cast<bool>(cond), #cond, __FILE__, __LINE__)
