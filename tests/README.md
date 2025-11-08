# Tests für CachyOS Multi-Updater

Dieses Verzeichnis enthält automatisierte Tests für das Update-Script.

## Voraussetzungen

### BATS (Bash Automated Testing System)

BATS ist ein Testing-Framework für Bash-Scripts.

**Installation auf Arch/CachyOS:**
```bash
sudo pacman -S bats
```

**Installation auf anderen Systemen:**
```bash
# Via NPM
npm install -g bats

# Via Git
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

## Tests ausführen

### Alle Tests ausführen

```bash
cd /pfad/zum/cachyos-multi-updater
bats tests/
```

### Einzelne Test-Datei ausführen

```bash
bats tests/test-config.bats
```

### Einzelnen Test ausführen

```bash
bats tests/test-config.bats --filter "validate_config_value: gültiger boolean-Wert"
```

## Test-Struktur

```
tests/
├── README.md              # Diese Datei
├── test-config.bats       # Tests für Config-Validierung
└── test-snapshots.bats    # Tests für Snapshot/Rollback
```

## Test-Dateien

### test-config.bats

Testet die Konfigurationsdatei-Funktionalität:
- Validierung von Boolean-Werten (true/false)
- Validierung von Zahlen-Werten
- Laden von Konfigurationsdateien
- Ignorieren von Kommentaren
- Fehlerbehandlung bei ungültigen Werten

### test-snapshots.bats

Testet die Snapshot/Rollback-Funktionalität:
- Erstellung von Snapshots
- Wiederherstellung von Snapshots
- Cleanup alter Snapshots
- Fehlerbehandlung

## Neue Tests hinzufügen

1. Erstelle eine neue `.bats` Datei in `tests/`
2. Verwende das BATS-Format:

```bash
#!/usr/bin/env bats

setup() {
    # Wird vor jedem Test ausgeführt
}

teardown() {
    # Wird nach jedem Test ausgeführt
}

@test "Beschreibung des Tests" {
    # Test-Code
    run command
    [ "$status" -eq 0 ]
}
```

## CI/CD Integration

Die Tests werden automatisch bei jedem Push via GitHub Actions ausgeführt.
Siehe [.github/workflows/test.yml](../.github/workflows/test.yml)

## Probleme?

Wenn Tests fehlschlagen:

1. **Prüfe BATS-Installation:**
   ```bash
   bats --version
   ```

2. **Prüfe Berechtigungen:**
   ```bash
   chmod +x tests/*.bats
   ```

3. **Prüfe temporäre Verzeichnisse:**
   ```bash
   df -h /tmp
   ```

4. **Logs anzeigen:**
   Tests erstellen temporäre Dateien in `/tmp/bats-test.*`

## Best Practices

- **Isolierung:** Jeder Test sollte unabhängig sein
- **Cleanup:** Immer temporäre Dateien in `teardown()` aufräumen
- **Descriptive Namen:** Test-Namen sollten klar beschreiben was getestet wird
- **Schnell:** Tests sollten schnell ausführen (< 1s pro Test)
- **Deterministisch:** Tests sollten immer das gleiche Ergebnis liefern
