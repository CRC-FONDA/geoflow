# Neuer B5 Workflow

## Auf die Plätze, fertig, los!

Mit den nötigen Berechtigungen:

```bash
git clone https://scm.cms.hu-berlin.de/katerndf/geoflow.git
cd geoflow
```

## Docker

Im Dockerfile sind die einzelnen Schritte nicht in einem großen Block, damit die ge-cached werden können.
Was eine sinnvolle Aufteilung/Zusammenführung wäre weiß ich nicht. Es funktioniert (vorerst), das reicht
erstmal. Wie das mit Cache-Invalidation in Verbindung mit dem Git-Repo aussieht weiß ich nicht.

`docker build` läuft nicht ohne Warnungen durch, das ist aber eine Sache für die Enmap-Box-Entwickler.

```bash
# -f Dockerfile braucht es eigentlich nicht
docker build -t emb_docker:v0.0.1 -f Dockerfile .

docker run --rm emb_docker:v0.0.1

#> QGIS Processing Executor - 3.23.0-Master 'Master' (3.23.0-Master)
#> Usage: qgis_process [--help] [--version] [--json] [--verbose] [command] [algorithm id or path to model file] [parameters]
#>
#> Options:
#>         --help or -h            Output the help
#>         --version or -v         Output all versions related to QGIS Process
#>         --json          Output results as JSON objects
#>         --verbose       Output verbose logs
# [...]
```

## Beispiele

Da die verwendeten Daten prinzipiell egal sind, werden diese auch nicht "mitgeliefert".

NDVI für Sentinel-2 A/B berechnen:

```bash
docker run \
  --rm \
  -v /mnt/h/git-repos/geoflow/external/data:/home/data \
  emb_docker:v0.0.1 \
  qgis_process run enmapbox:RasterMath -- \
  code="(R1@8 - R1@3) / (R1@8 + R1@3)" \
  R1=/home/data/20180216_LEVEL2_SEN2B_BOA.tif \
  outputRaster=/home/data/NDVI.tif \
  monolithic=True
```

EVI für Landsat-8 berechnen:

```bash
docker run \
  --rm \
  -v /mnt/h/git-repos/geoflow/external/data:/home/data \
  emb_docker:v0.0.1 \
  qgis_process run enmapbox:RasterMath -- \
  code="2.5 * ((R1@4 - R1@3) / (R1@4 + 6 * R1@3 - 7.5 * R1@1 + 1))" \
  R1=/home/data/20180909_LEVEL2_LND08_BOA.tif \
  outputRaster=/home/data/EVI.tif \
  monolithic=True
```

## Ein wenig Zukunftsmusik

Gut möglich, dass das Dockerimage noch optimiert werden oder an manchen Stellen
umgestaltet werden könnte/sollte. Ein paar Ansatzpunkte (ohne Ahnung von Docker zu haben):
- "Docker User" um die Kiste nicht als `root` laufen lassen
- Speicherplatz/Image-Größe optimieren (aktuell: ~9 Gb)
  - Nicht auf `qgis/qgis:XXX` aufbauen, sondern selber kompilieren. Wie das geht und was es
  zu beachten gibt, kann auf [GitHub Repo von qgis](https://github.com/qgis/QGIS/blob/master/INSTALL.md)
  nachgelesen werden. In deren Dockerfile auf Anregung (?) welche
  Argumente/Build-Targets da übergeben werden sollten.
  - Alpine Linux (Container-Gr. ca. 180 Mb?) verwenden, wenn möglich.
- Das betrifft vielleicht auch eher die Enmap-Box als uns direkt: Einen ähnlichen Ansatz wie David,
der sich ein *baseimage* gebastelt hat um die ganzen Abhängigkeiten nicht immer neu installieren
und kompilieren zu müssen.
