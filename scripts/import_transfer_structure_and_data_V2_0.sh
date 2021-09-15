#!/bin/bash

# URL_DATA_ZIP: URL of zip file that contains the theme's xtf file
# SCHEMA_NAME:  Name of the database schema 

# Example command:
# 

if [ -z "URL_DATA_ZIP" ]
then
    echo "URL_DATA_ZIP not defined"
    exit 1
fi

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
model_OeREBKRMtrsfr="OeREBKRMtrsfr_V2_0"

# law_xml_file
law_xml_file="OeREBKRM_V2_0_Gesetze_20210414.xml"

# download and unzip data of theme
echo "Download and extract ${URL_DATA_ZIP} ..."
tmp_data_dir="tmp_data_dir"
mkdir $tmp_data_dir
wget $URL_DATA_ZIP -O "${tmp_data_dir}/data.zip"
unzip "${tmp_data_dir}/data.zip" -d "tmp_data_dir"
xtf_file=`ls ${tmp_data_dir}/*.xtf`

if [ ! -f "${xtf_file}" ]
then
    echo "Not found: ${xtf_file}"
    exit 1
fi

# download law xml file
echo "Download ${model_repository}${law_xml_file} ..."
wget ${model_repository}${law_xml_file} -O "${tmp_data_dir}/${law_xml_file}"
law_xml_file_full="${tmp_data_dir}/${law_xml_file}"

if [ ! -f "${law_xml_file_full}" ]
then
    echo "Not found: ${law_xml_file_full}"
    exit 1
fi

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
                   --models $model_OeREBKRMtrsfr

# delete data from datasets (if existing)
echo "Delete data from dataset ${SCHEMA_NAME} in schema ${SCHEMA_NAME} ..."
java -jar $illi2pg --delete \
                   --dbhost $PGHOST \
                   --dbport $PGPORT  \
                   --dbdatabase $PGDB \
                   --dbusr $PGUSER \
                   --dbpwd $PGPASSWORD \
                   --dbschema $SCHEMA_NAME \
                   --dataset ${SCHEMA_NAME}

echo "Delete data from dataset ${law_xml_file} in schema ${SCHEMA_NAME} ..."
java -jar $illi2pg --delete \
                   --dbhost $PGHOST \
                   --dbport $PGPORT  \
                   --dbdatabase $PGDB \
                   --dbusr $PGUSER \
                   --dbpwd $PGPASSWORD \
                   --dbschema $SCHEMA_NAME \
                   --dataset ${law_xml_file}

# import laws in database
echo "Import data from ${xtf_file} into schema ${SCHEMA_NAME} ..."
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
                   $law_xml_file_full
                   

# import plr data in database
echo "Import data from ${xtf_file} into schema ${SCHEMA_NAME} ..."
java -jar $illi2pg --import \
                   --dbhost $PGHOST \
                   --dbport $PGPORT  \
                   --dbdatabase $PGDB \
                   --dbusr $PGUSER \
                   --dbpwd $PGPASSWORD \
                   --dbschema $SCHEMA_NAME \
                   --defaultSrsAuth EPSG \
                   --defaultSrsCode 2056 \
                   --dataset $SCHEMA_NAME \
                   $xtf_file

# add tables to schema that are required by pyramid_oereb
echo "Add tables to schema that are required by pyramid_oereb ..."
docker-compose exec db psql -d federal_themes -U federal_themes -v user=$PGUSER -v schema=$SCHEMA_NAME \
    -f /scripts/sql/add_tables_to_trsf_structure.sql

# update table availability
echo "Update table availability ..."
docker-compose exec db psql -d federal_themes -U federal_themes -v schema=$SCHEMA_NAME \
    -f /scripts/sql/update_availability.sql

# clean the place
echo "Clean the place ..."
rm -rf $tmp_data_dir
