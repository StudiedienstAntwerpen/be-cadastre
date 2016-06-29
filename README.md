# be-cadastre
This repository provides you with scripts to turn the dumps of the Belgian Cadastre (as provided to every municipality in Belgiu ) into some nice statistics about ownership, number of residences et cetera.

The dumps have been provided in the same way for a rather long period. However, the essential "construction code" seems to be provided from 2013 only. From 2016 onwards, new dumps will be in a slightly different format.

The scripts available here are written in SPSS. You can get a free one month trial version of this software. 
The programming is quite simple, so it shouldn't be too difficult to translate the scripts into the language of your choice.

At Stad Antwerpen, we use the generated data in our Stad in Cijfers web-portal. Though the techniques are still in development, you can already [consult them there](https://stadincijfers.antwerpen.be/databank/?cat_open=Wonen%20en%20ruimte/Kadaster/Eigenaars&var=prcp_eigenaarswoning&view=map&geolevel=wijk&geocompare=antwerpen).



## Analyzing Cadastre

Before you start: you will need:
- the geometry of parcels (you can use either the dataset provided by the Kadaster, or the cleaned version provided by AGIV, if you're in Flanders)
- the data about parcels. This is provided to municipalities as txt files.
- a dataset with a division of your territory of interest. We assume this to be statistical sectors. If you don't have them yet, there's a national open dataset available.
- a way to convert either DAA (a field in one of the txt's) or your territory devisions into postal codes. You will need those to complete the address of parcels.

The scripts (starting with 00_ etc) assume you know how to use SPSS syntax or have read [this short explanation (Dutch)](https://drive.google.com/file/d/0BzkGrg-2Kbc9aEhhb1UwQklGb2c/view?usp=sharing).

They also assume you have made a table linking parcels to their most likely [statistical sector](http://www.geopunt.be/catalogus/datasetfolder/cb7113a3-58db-498c-89b7-24cb509b002d). This is not straightforward, as parcels might be spread out over two or more sectors. A method taking into account geographical area and CRAB adress positions by parcel and sector is explained in these [step by step instructions (Dutch)](https://drive.google.com/file/d/0BzkGrg-2Kbc9OUlST1F0WFFmRGc/view?usp=sharing)

Scripts:
- 00: making sure you can count properly at higher geographical aggregations
- 01: convert the base data to .sav files
- 02: create a usable ownership dataset and make property level variables
- 03: classify ownership, including finding people who live in their own property
- 04: (work in progress) turn into a handy dataset of parcels and statistical sectors
