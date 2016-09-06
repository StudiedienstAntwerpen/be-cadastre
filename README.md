# be-cadastre
This repository provides you with scripts to turn the dumps of the Belgian Cadastre (as provided to every municipality in Belgium) into some nice statistics about ownership, number of residences et cetera.

The dumps have been provided in the same way for a rather long period. However, the essential "construction code" seems to be provided from 2013 only. From 2016 onwards, new dumps will be in a slightly different format. An adapted version shouldn't present any real issues. A different procedure (probably xsave) will be implemented to create a file with all owner-parcel combinations. The current script is hardcoded for 4 potential owners.

The scripts available here are written in SPSS. You can get a free one month trial version of this software. 
The programming is quite simple, so it shouldn't be too difficult to translate the scripts into the language of your choice. The SPS file extension is associated with SPSS, but can be opened in any text editor.

The scripts assume your SPSS is set to Locale text encoding. Using unicode will probably pose no problems. Do avoid switching between encodings within one project. You can set your encoding at Edit>Options>Language before you opened any data.

The scripts depend on each other: you can only run number 06 if you ran all the lower numbers in order.

At Stad Antwerpen, we use the generated data in our Stad in Cijfers web-portal. Though the techniques are still in development, you can already [consult them there](https://stadincijfers.antwerpen.be/databank/?cat_open=Wonen%20en%20ruimte/Kadaster/Eigenaars&var=prcp_eigenaarswoning&view=map&geolevel=wijk&geocompare=antwerpen).



## Analyzing Cadastre

Before you start you will need:
- the geometry of parcels (you can use either the dataset provided by the Kadaster, or the cleaned version provided by AGIV, if you're in Flanders)
- the data about parcels. This is provided to municipalities as txt files. The two main files you need are pe.txt and prc.txt. They do not contain variable names and are ; separated flatfiles.
- a way to convert either DAA (a field in one of the txt's) or your territory devisions into postal codes. You will need those to complete the address of parcels.
- a list of owners you consider government. This is optional, but you will have to adapt the scripts if you do not have this.
- a dataset with a division of your territory of interest. We assume this to be statistical sectors. If you don't have them yet, there's [a national open dataset available](http://www.geopunt.be/catalogus/datasetfolder/cb7113a3-58db-498c-89b7-24cb509b002d).
- a table linking parcels to your territory division (usually [statistical sector](http://www.geopunt.be/catalogus/datasetfolder/cb7113a3-58db-498c-89b7-24cb509b002d)). This is not straightforward, as parcels might be spread out over two or more sectors. A method taking into account geographical area and CRAB adress positions by parcel and sector is explained in these [step by step instructions (Dutch)](https://drive.google.com/file/d/0BzkGrg-2Kbc9OUlST1F0WFFmRGc/view?usp=sharing). So you will need a GIS layer with CRAB adresses at their "adrespositie".

The scripts (starting with 00_ etc) assume you know how to use SPSS syntax or have read [this short explanation (Dutch)](https://drive.google.com/file/d/0BzkGrg-2Kbc9aEhhb1UwQklGb2c/view?usp=sharing).



Scripts:
- 00: making sure you can count properly at higher geographical aggregations
- 01: convert the base data to .sav files
- 02: create a usable ownership dataset and make property level variables
- 03: classify ownership, including finding people who live in their own property
- 04: finish ownership data, prepare measures at housing unit and parcel level
- 05: turn into a handy dataset of parcels and statistical sectors
- 06: expanded set of statistical sector indicators

## Using results

The output for GIS use is written to a DBF file because ArcGIS likes those.

The output at the neighborhood level are written to an Excel file. This is formatted for use with [Swing](http://swing.eu/), a geostatistical data platform. For those using the platform, [an Excel file is provided](https://github.com/joostschouppe/be-cadastre/blob/master/metadata_swing.xls) with metadata and settings for the created variables. It seems to work best if you load the data first, only then the metadata.


## Get help and contribute

Did you use the script and something went wrong? 

If you need help, please post a new [issue](https://github.com/joostschouppe/be-cadastre/issues/new).

If you found a solution: create a Branch, adapt and make a Pull request to get your fix into the main scripts. 

If you don't know how to Github, a good place to start is [here](https://guides.github.com/activities/hello-world/).

Sharing is caring.
