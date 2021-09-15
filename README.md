# ili2pg_oereb_data_import_manual
Manual/tools for the table structur creation in PostGIS and for the oereb data import using ili2pg.

# Required software

## ili2pg

1. Information about the ili2db software tools:
   - [ili2db main page](https://www.interlis.ch/downloads/ili2db)
   - [ili2db manual](https://github.com/claeis/ili2db/blob/master/docs/ili2db.rst)
2. Download: [Versions of ili2pg](https://downloads.interlis.ch/ili2pg/)

#  Relevant Documents

- [Rahmenmodell für den ÖREB-Kataster – Erläuterungen für die Umsetzung](Documents/Rahmenmodell-de.pdf)
- Documents on [Model Repository](https://models.geo.admin.ch/V_D/OeREB/)

# Database import of PLR data from the transfer structure (OeREBKRMtrsfr_V2_0)

## Generation of tables structure in the database

```
ili2pg=ili2pg-4.5.0.jar

java -jar $ili2pg --schemaimport \
                  --dbhost var_dbhost \
                  --dbport var_dbport  \
                  --dbdatabase var_dbdatabase \
                  --dbusr var_dbusr \
                  --dbpwd var_dbpwd \
                  --dbschema var_dbschema \            # var_dbschema e.g. "motorways_project_planing_zones"
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

Options that are ** not ** used:
- ``` --strokeArcs ```              # surface / line in data model: GeometryCHLV95_V1.Surface / GeometryCHLV95_V1.Surface
- ``` --coalesceMultiSurface ```    # surface in data model: GeometryCHLV95_V1.Surface
- ``` --coalesceMultiLine ```       # line in data model: GeometryCHLV95_V1.Line
- ``` --coalesceMultiPoint ```      # point in data model: GeometryCHLV95_V1.Coord2

## Data import

```
java -jar $ili2pg --import \
                  --dbhost var_dbhost \
                  --dbport var_dbport  \
                  --dbdatabase var_dbdatabase \
                  --dbusr var_dbusr \
                  --dbpwd var_dbpwd \
                  --dbschema var_dbschema \            # var_dbschema e.g. "motorways_project_planing_zones"
                  --defaultSrsAuth EPSG \
                  --defaultSrsCode 2056 \
                  --dataset var_dataset \              # dataset name
                  --replace var_xtf_file               # data in the db are replaced by means of a dataset name
```