// Conversion entre UTF-8 (como se guardan los archivos) y UTF-16 (lo que usa Windows).
#pragma once

#include <string>
#include <string_view>

std::wstring to_wide(std::string_view utf8);
std::string from_wide(std::wstring_view wide);
