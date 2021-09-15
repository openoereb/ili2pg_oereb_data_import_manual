# ili2pg_oereb_data_import_manual
Manual/tools for the table structur creation in PostGIS and for the oereb data import using ili2pg.

## Required software / relevant documents

### ili2pg

[Website](https://www.interlis.ch/downloads/ili2db) \
[Manual](https://github.com/claeis/ili2db/blob/master/docs/ili2db.rst) \
[Download](https://downloads.interlis.ch/ili2pg/)

###  Documents

- Rahmenmodell für den ÖREB-Kataster – Erläuterungen für die Umsetzung [PDF](Documents/Rahmenmodell-de.pdf)
- Documents on [https://models.geo.admin.ch/V_D/OeREB/](https://models.geo.admin.ch/V_D/OeREB/)

## Import of PLR data from the transfer structure (OeREBKRMtrsfr_V2_0)

### Import schema in database based on OeREBKRMtrsfr_V2_0

**Selected options for ili2pg**

```
ili2pg=ili2pg-4.5.0.jar

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
                  --models OeREBKRMtrsfr_V2_0          # name of the model
```

Options that are **not** used:
```
--strokeArcs              # surface / line in data model: GeometryCHLV95_V1.Surface / GeometryCHLV95_V1.Line
--coalesceMultiSurface    # surface in data model: GeometryCHLV95_V1.Surface
--coalesceMultiLine       # line in data model: GeometryCHLV95_V1.Line
--coalesceMultiPoint      # point in data model: GeometryCHLV95_V1.Coord2
```

### Data import

**Selected options for ili2pg**

```
java -jar $ili2pg --import \
                  --dbhost $PGHOST \
                  --dbport $PGPORT  \
                  --dbdatabase $PGDB \
                  --dbusr $PGUSER \
                  --dbpwd $PGPASSWORD \
                  --dbschema $SCHEMA_NAME \            # e.g. "motorways_project_planing_zones"
                  --defaultSrsAuth EPSG \
                  --defaultSrsCode 2056 \
                  --dataset var_dataset \              # dataset name
                  --replace var_xtf_file               # data in the database is replaced by data of the xtf-file by means of the dataset name
```