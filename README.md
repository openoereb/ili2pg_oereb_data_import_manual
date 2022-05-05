# ili2pg_oereb_data_import_manual
Manual for using ili2pg to import OEREB data provided in the transfer structure (OeREBKRMtrsfr_V2_0) to a PostGIS database.

The model OeREBKRMkvs_V2_0 is not supported by pyramid_oereb. Consult the pyramid_oereb [main-schema](https://github.com/openoereb/pyramid_oereb/blob/master/pyramid_oereb/standard/models/main.py) regarding the information that is required for running the application.

### ili2pg

[Website](https://www.interlis.ch/downloads/ili2db) \
[Manual](https://github.com/claeis/ili2db/blob/master/docs/ili2db.rst) \
[Download](https://downloads.interlis.ch/ili2pg/)

###  Documents

- Rahmenmodell für den ÖREB-Kataster – Erläuterungen für die Umsetzung [PDF](Documents/Rahmenmodell-de.pdf)
- Models/xml-files on [https://models.geo.admin.ch/V_D/OeREB/](https://models.geo.admin.ch/V_D/OeREB/)

## Import of PLR data provided in the transfer structure

### Import model OeREBKRMtrsfr_V2_0 into database schema

**Selected options for ili2pg**

```
ili2pg=ili2pg-4.6.0.jar

java -jar $ili2pg --schemaimport \
                  --dbhost $PGHOST \
                  --dbport $PGPORT  \
                  --dbdatabase $PGDB \
                  --dbusr $PGUSER \
                  --dbpwd $PGPASSWORD \
                  --dbschema $SCHEMA_NAME \            # e.g. "motorways_project_planing_zones"
                  --defaultSrsAuth EPSG \
                  --defaultSrsCode 2056 \
                  --createFk \                         # creates foreign keys
                  --createFkIdx \                      # creates index for foreign key columns
                  --createGeomIdx \                    # creates index for every geometry column
                  --createTidCol \                     # creates column t_ili_tid in every table
                  --createBasketCol \                  # creates column t_basket in every table to identify basket
                  --createDatasetCol \                 # creates column t_datasetname in every table to identify dataset
                  --createTypeDiscriminator \          # creates column t_type in every table for the type discriminator
                  --createMetaInfo \                   # creates additional tables with information from the interlis model
                  --createNumChecks \                  # creates constraints for numerical data types
                  --createUnique \                     # creates unique constraints in the db for Interlis unique constraints
                  --expandMultilingual \               # LocalisationCH_V1.MultilingualText/MText --> additional columns in table
                  --expandLocalised \                  # LocalisationCH_V1.LocalisedText/MText --> additional columns in table
                  --setupPgExt \                       # PostGIS: erstellt postgreql Erweiterungen 'uuid-ossp' und 'postgis' (falls noch nicht vorhanden)
                  --strokeArcs \                       # Segmentation of arcs
                  --models OeREBKRMtrsfr_V2_0          # name of the model
```

Options that are **not** used:
```
--coalesceMultiSurface    # surface in data model: GeometryCHLV95_V1.Surface
--coalesceMultiLine       # line in data model: GeometryCHLV95_V1.Line
--coalesceMultiPoint      # point in data model: GeometryCHLV95_V1.Coord2
```

Options that are used because of pyramid_oereb:
```
--strokeArcs              # surface / line in data model: GeometryCHLV95_V1.Surface / GeometryCHLV95_V1.Line, but shapely 1.6.4 cannot cope with arcs
```

Options that might be relevant dependent on individual settings:
```
--proxy host              # Name of host that is used for access to model repositories.
--proxyPort port          # Port of proxy that should be used.
```

**Note concerning the validity of geometries**

It is possible that geometries provided based on the Interlis model OeREBKRMtrsfr_V2_0 are not valid OGC geometries. This can potentially cause problems when the geometries are processed in pyramid_oereb. It is recommended to check the imported data by a SQL statement and, if possible, to resolve the issue.

Example SQL statement:
```
SELECT t_id FROM schema_name.geometrie WHERE ST_IsValid("punkt") IS False OR ST_IsValid("linie") IS False OR ST_IsValid("flaeche") IS False;
```

### XML import

- OeREBKRM_V2_0_Gesetze_YYYYMMDD.xml - if available in data.zip - must be imported prior to xtf-file for federal topics due to foreign key constraints.

**Selected options for ili2pg**

```
ili2pg=ili2pg-4.6.0.jar

java -jar $illi2pg --import \
                   --dbhost $PGHOST \
                   --dbport $PGPORT  \
                   --dbdatabase $PGDB \
                   --dbusr $PGUSER \
                   --dbpwd $PGPASSWORD \
                   --dbschema $SCHEMA_NAME \
                   --dataset $law_xml_file \
                   OeREBKRM_V2_0_Gesetze_YYYYMMDD.xml
```

### Data import

**Selected options for ili2pg**

```
ili2pg=ili2pg-4.6.0.jar

java -jar $ili2pg --import \
                  --dbhost $PGHOST \
                  --dbport $PGPORT  \
                  --dbdatabase $PGDB \
                  --dbusr $PGUSER \
                  --dbpwd $PGPASSWORD \
                  --dbschema $SCHEMA_NAME \            # e.g. "motorways_project_planing_zones"
                  --defaultSrsAuth EPSG \
                  --defaultSrsCode 2056 \
                  --strokeArcs \
                  --dataset $var_dataset \             # dataset name
                  interlis.xtf
```

### Additional tables required for pyramid_oereb which are not part of OeREBKRMtrsfr_V2_0

**add_tables_to_trsf_structure.sql**

```
/* TABLE datenintegration*/

CREATE TABLE IF NOT EXISTS :schema.datenintegration
(
    t_id bigint NOT NULL,
    datum timestamp without time zone NOT NULL,
    amt bigint NOT NULL,
    checksum character varying COLLATE pg_catalog."default",
    CONSTRAINT datenintegration_pkey PRIMARY KEY (t_id),
    CONSTRAINT datenintegration_amt_fkey FOREIGN KEY (amt)
        REFERENCES :schema.amt (t_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE :schema.datenintegration
    OWNER to :user;


/* TABLE verfuegbarkeit */

CREATE TABLE IF NOT EXISTS :schema.verfuegbarkeit
(
    bfsnr int NOT NULL,
    verfuegbar boolean NOT NULL,
    CONSTRAINT verfuegbarkeit_pkey PRIMARY KEY (bfsnr)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE :schema.verfuegbarkeit
    OWNER to :user;
```

**update_availability.sql**

```
INSERT INTO :schema.verfuegbarkeit (bfsnr, verfuegbar) VALUES
(2854, TRUE);
```

**psql**

```
psql -d $PGDB -U $PGUSER -v "usr=$PGUSER" -v "schema=$SCHEMA_NAME" -f add_tables_to_trsf_structure.sql
psql -d $PGDB -U $PGUSER -v "schema=$SCHEMA_NAME" -f update_availability.sql

```

## Example configuration for a federal topic in pyramid_oereb.yml

Note these differences compared to a standard theme:
- class: pyramid_oereb.contrib.data_sources.interlis_2_3.sources.plr.DatabaseSource
- model_factory: pyramid_oereb.contrib.data_sources.interlis_2_3.models.theme.model_factory_integer_pk
- get_symbol: pyramid_oereb.contrib.data_sources.interlis_2_3.hook_methods.get_symbol

In addition, have a look at https://github.com/openoereb/pyramid_oereb/blob/master/dev/config/pyramid_oereb.yml.mako. The file on the master branch can differ from the one in a specific beta version (e.g. hooks).


```
    - code: ch.BelasteteStandorteZivileFlugplaetze
      geometry_type: GEOMETRYCOLLECTION
      thresholds:
        length:
          limit: 1.0
          unit: 'm'
          precision: 2
        area:
          limit: 1.0
          unit: 'm2'
          precision: 2
        percentage:
          precision: 1
      text:
        de: Kataster der belasteten Standorte im Bereich der zivilen Flugplätze
      language: de
      federal: true
      standard: false
      view_service:
        layer_index: 1
        layer_opacity: 0.75
      source:
        class: pyramid_oereb.contrib.data_sources.interlis_2_3.sources.plr.DatabaseSource
        params:
          db_connection: ${data_base_connection}
          model_factory: pyramid_oereb.contrib.data_sources.interlis_2_3.models.theme.model_factory_integer_pk
          schema_name: contaminated_civil_aviation_sites
      hooks:
        get_symbol: pyramid_oereb.contrib.data_sources.interlis_2_3.hook_methods.get_symbol
        get_symbol_ref: pyramid_oereb.core.hook_methods.get_symbol_ref
      law_status_lookup:
        - data_code: inKraft
          transfer_code: inKraft
          extract_code: inForce
        - data_code: AenderungMitVorwirkung
          transfer_code: AenderungMitVorwirkung
          extract_code: changeWithPreEffect
        - data_code: AenderungOhneVorwirkung
          transfer_code: AenderungOhneVorwirkung
          extract_code: changeWithoutPreEffect
      document_types_lookup:
        - data_code: Rechtsvorschrift
          transfer_code: Rechtsvorschrift
          extract_code: LegalProvision
        - data_code: GesetzlicheGrundlage
          transfer_code: GesetzlicheGrundlage
          extract_code: Law
        - data_code: Hinweis
          transfer_code: Hinweis
          extract_code: Hint
```
