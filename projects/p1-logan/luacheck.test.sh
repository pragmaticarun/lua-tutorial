# host: luacheck
# Lint everything with the project's .luacheckrc; luacheck exits 0 when clean.
luacheck --no-color src bin/logan spec steps exercises logan-1.0.0-1.rockspec | tail -1
echo "[exit ${PIPESTATUS[0]}]"
