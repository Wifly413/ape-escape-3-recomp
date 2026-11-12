// Arranque del runtime del juego.
#pragma once

#include "config.hpp"

#include <string>

// Lanza el runtime con la configuracion dada. Devuelve false si no se pudo arrancar,
// y deja el motivo en error.
bool launch(const Config& c, const std::string& base_dir, std::string& error);
