# ili2pg_oereb_data_import_manual
Manual/tools for the table structur creation in PostGIS and for the oereb data import using ili2pg.

## Required software / relevant documents

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
                  --strokeArcs \                       # Segmentation of arcs
                  --models OeREBKRMtrsfr_V2_0          # name of the model
```

Options that are **not** used:
```
--coalesceMultiSurface    # surface in data model: GeometryCHLV95_V1.Surface
--coalesceMultiLine       # line in data model: GeometryCHLV95_V1.Line
--coalesceMultiPoint      # point in data model: GeometryCHLV95_V1.Coord2
```

Options that are used bacause of pyramid_oereb:
```
--strokeArcs              # surface / line in data model: GeometryCHLV95_V1.Surface / GeometryCHLV95_V1.Line, but shapely 1.6.4 cannot cope with arcs
```

### XML import

- OeREBKRM_V2_0_Gesetze_20210414.xml must be imported prior to xtf-file for federal topics due to foreign key constraints.

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
                   --defaultSrsAuth EPSG \
                   --defaultSrsCode 2056 \
                   --dataset $law_xml_file \
                   OeREBKRM_V2_0_Gesetze_20210414.xml
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
                  --dataset var_dataset \              # dataset name
                  interlis.xtf
```

## Import model proposed for the office responsible for the cadastre

### Import model OeREBKRMkvs_V2_0 into database schema

**Selected options for ili2pg**

```
ili2pg=ili2pg-4.6.0.jar

java -jar $ili2pg --schemaimport \
                  --dbhost $PGHOST \
                  --dbport $PGPORT  \
                  --dbdatabase $PGDB \
                  --dbusr $PGUSER \
                  --dbpwd $PGPASSWORD \
                  --dbschema $SCHEMA_NAME \            # e.g. "pyramid_oereb_main"
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
                  --models OeREBKRMkvs_V2_0            # name of the model
```

### XML import

Order of import (foreign key constraints):
- OeREBKRM_V2_0_Gesetze_20210414.xml
- OeREBKRM_V2_0_Themen_20210714.xml
- OeREBKRM_V2_0_Texte_20210714.xml
- OeREBKRM_V2_0_Logos_20210414.xml

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
                   --defaultSrsAuth EPSG \
                   --defaultSrsCode 2056 \
                   --dataset OeREBKRM_V2_0_Gesetze_20210414.xml \   # dataset name
                   OeREBKRM_V2_0_Gesetze_20210414.xml               # xml file name