#!/usr/bin/env bash
set -e

cd ~/lodijke

echo "=== [1/4] Opschonen van per ongeluk aangemaakte stray files in de root ==="
rm -f ";" "Code," "chema);" "t(graphql_execution_handler)," \
      "tener = tokio::net::TcpListener::bind(addr).await.unwrap();" \
      "ync fn graphql_execution_handler(" \
      "ystemctl --user restart lodijke-cms-server.service"
# Verwijder ook het losse graphql-fragmentbestand als dat bestaat
find . -maxdepth 1 -name 'onParcelById*' -exec rm -f {} +

echo "=== [2/4] Cargo.toml opschonen (dubbele bytes entry voorkomen) ==="
# Zorg dat multipart aan staat en bytes netjes één keer onder [dependencies] staat
python3 - << 'PYEOF'
with open("Cargo.toml", "r") as f:
    content = f.read()

# Verwijder eventuele losse 'bytes = "1"' regels onderaan en voeg netjes toe indien nodig
lines = [l for l in content.splitlines() if l.strip() != 'bytes = "1"']
clean_content = "\n".join(lines) + "\n"

if 'bytes =' not in clean_content:
    clean_content = clean_content.replace('[dependencies]\n', '[dependencies]\nbytes = "1"\n', 1)

with open("Cargo.toml", "w") as f:
    f.write(clean_content)
PYEOF

echo "=== [3/4] Patchen van src/main.rs ==="
python3 - << 'PYEOF'
import re

with open("src/main.rs", "r") as f:
    code = f.read()

# 1. Voeg chrono::Datelike toe voor .year() (Error E0599)
if "use chrono::Datelike;" not in code:
    code = "use chrono::Datelike;\n" + code

# 2. Verwijder dubbele Path import uit std::path (Error E0252 & Warning)
code = code.replace("path::{Path, PathBuf}", "path::PathBuf")

# 3. Gebruik expliciet std::path::Path::new voor bestandsextensie (Error E0599)
code = code.replace("let ext = Path::new(&orig)", "let ext = std::path::Path::new(&orig)")

# 4. Voorkom partial move van query in match arm (Error E0382)
code = code.replace(
    "Some(q) if !q.trim().is_empty() =>",
    "Some(ref q) if !q.trim().is_empty() =>"
)

# 5. Verwijder ongebruikte 'delete' import uit axum::routing (Warning)
code = code.replace("routing::{get, post, delete}", "routing::{get, post}")

# 6. Fix unused variable warning op export_geojson (Warning)
code = code.replace(
    "fn export_geojson(State(state): State<AppState>)",
    "fn export_geojson(State(_state): State<AppState>)"
)

# 7. Fix fs::write met 4 argumenten (Error E0061)
# Als er {} placeholders in de HTML-string zitten gebruiken we format!(), anders laten we de extra args weg
pattern_fs = re.compile(
    r'(fs::write\(\s*[^,]+,\s*)(r#"[\s\S]*?</html>"#)\s*,\s*port\s*,\s*Utc::now\(\)\.to_rfc3339\(\)\s*,?\s*\)',
    re.MULTILINE
)

def repl_fs(match):
    prefix, html_str = match.group(1), match.group(2)
    if "{}" in html_str:
        return f"{prefix}format!({html_str}, port, Utc::now().to_rfc3339()))"
    else:
        return f"{prefix}{html_str})"

code = pattern_fs.sub(repl_fs, code)

with open("src/main.rs", "w") as f:
    f.write(code)

print("Alle patches succesvol toegepast op src/main.rs!")
PYEOF

echo "=== [4/4] Compileren in release-modus ==="
cargo build --release

echo "=== Klaar! Binary staat klaar in target/release/lodijke-cms-server ==="
