# Drug Product Database Tools

This repository contains code and tools for working with HPFB (Health Canada's) Drug Product Database. Included folders:

* Structure 
* Import/pgloader
* Postgrest REST API
* DPD Web application
* Elasticserch
* Analysis

# Structure

This folder has SQL scripts to set up a Postgresql database with a remote schema to an Oracle host using teh Oracle Foreign Data Wrapper for Postgresql extension: http://laurenz.github.io/oracle_fdw/

This is one example of a way to get data out of Oracle into Postgresql if you cannot do a complete migration for some reason. You'll have to find your own Oracle credentials.

# PGLoader

These are pgloader scripts for use with pgloader (v 3.5 or higher) https://pgloader.io/
The scripts will download DPD extracts directly from Health Canada's website and should be run in the following order:

* dpdload.pgload
* dpdload_ia.pgload
* dpdload_dr.pgload
* dpdload_ap.pgload

These scripts will use the environemtn variables PGHOST, PGUSER, PGDATABASE, and PGPASSWORD and will create a new schema called pgloader, that can then be renamed appropriately.

# Postgrest

This contains the SQL files that set up the dpd_current and dpd_api schemas, as well as a refresh script. The dpd_api schema is used by Postgrest (http://postgrest.org/en/v5.0/) to auto-generate a Swagger specification and a Rest API.

The dpd_api script also contains the definition for dpd_json, which denormalizes every drug_product into a single JSON object. 

The swagger subfolder contains the SwaggerUI files that read the auto-generated Swagger specification generated by postgrest.

# Elasticsearch

This folder contained the Elasticsearch mapping for drug_products (This has not yet been updated for Elasticsearch 6.4 which deprecated document types).

# DPD Web Application

This is a light-weight HTML5/javascript application that replicates the behaviour of the Drug Product Database web application. 

# Analysis

This is a folder for assorted analysis scripts 