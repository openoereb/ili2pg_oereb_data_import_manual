#!/bin/bash

# URL_DATA_ZIP: URL of zip file that contains the theme's xtf file
# SCHEMA_NAME:  Name of the database schema 

# Example command:
# SCHEMA_NAME="pyramid_oereb_main" bash scripts/import_kvs_structure_and_data_V2_0.sh

if [ -z "SCHEMA_NAME" ]
then
    echo "SCHEMA not defined"
    exit 1
fi

# ili-pgms
illi2pg="ili2pg-4.6.0/ili2pg-4.6.0.jar"

# PostGIS database params
PGHOST="localhost" 
PGPORT=5432
PGUSER="federal_themes"
PGPASSWORD="federal_themes"
PGDB="federal_themes"

# models
model_repository='https://models.geo.admin.ch/V_D/OeREB/'
model_OeREBKRMkvs="OeREBKRMkvs_V2_0"

# law_xml_file
gesetze_xml="OeREBKRM_V2_0_Gesetze_20210414.xml"
themen_xml="OeREBKRM_V2_0_Themen_20210714.xml"
texte_xml="OeREBKRM_V2_0_Texte_20210714.xml"
logos_xml="OeREBKRM_V2_0_Logos_20210414.xml"


# import schema in database
echo "Import model ${model_OeREBKRMtrsfr} into schema ${SCHEMA_NAME} ..."
java -jar $illi2pg --schemaimport \
                   --dbhost $PGHOST \
                   --dbport $PGPORT  \
                   --dbdatabase $PGDB \
                   --dbusr $PGUSER \
                   --dbpwd $PGPASSWORD \
                   --dbschema $SCHEMA_NAME \
                   --defaultSrsAuth EPSG \
                   --defaultSrsCode 2056 \
                   --createFk \
                   --createFkIdx \
                   --createGeomIdx \
                   --createTidCol \
                   --createBasketCol \
                   --createDatasetCol \
                   --createTypeDiscriminator \
                   --createMetaInfo \
                   --createNumChecks \
                   --createUnique \
                   --expandMultilingual \
                   --expandLocalised \
                   --models $model_OeREBKRMkvs

# download and import xml files
tmp_data_dir="tmp_data_dir"
mkdir $tmp_data_dir

for xml_file in $themen_xml $gesetze_xml $texte_xml $logos_xml
do
    # delete data from datasets (if existing)
    echo "Delete data from dataset ${xml_file} in schema ${SCHEMA_NAME} ..."
    java -jar $illi2pg --delete \
                       --dbhost $PGHOST \
                       --dbport $PGPORT  \
                       --dbdatabase $PGDB \
                       --dbusr $PGUSER \
                       --dbpwd $PGPASSWORD \
                       --dbschema $SCHEMA_NAME \
                       --dataset $xml_file
done

for xml_file in $gesetze_xml $themen_xml $texte_xml $logos_xml
do
    echo "Download ${model_repository}${xml_file} ..."
    wget ${model_repository}${xml_file} -O "${tmp_data_dir}/${xml_file}"
    xml_file_full="${tmp_data_dir}/${xml_file}"

    if [ ! -f "${xml_file_full}" ]
    then
        echo "Not found: ${xml_file_full}"
        exit 1
    fi

    # import xml in database
    echo "Import data from ${xml_file} into schema ${SCHEMA_NAME} ..."
    java -jar $illi2pg --import \
                       --dbhost $PGHOST \
                       --dbport $PGPORT  \
                       --dbdatabase $PGDB \
                       --dbusr $PGUSER \
                       --dbpwd $PGPASSWORD \
                       --dbschema $SCHEMA_NAME \
                       --defaultSrsAuth EPSG \
                       --defaultSrsCode 2056 \
                       --dataset $xml_file \
                       $xml_file_full

done
                   

# add tables (municipality, real_estate and address) to schema that are required by pyramid_oereb
#echo "Add tables to schema that are required by pyramid_oereb ..."
#docker-compose exec db psql -d federal_themes -U federal_themes -v user=$PGUSER -v schema=$SCHEMA_NAME \
#    -f /scripts/sql/add_tables_to_kvs_structure.sql

# clean the place
echo "Clean the place ..."
rm -rf $tmp_data_dir
