* Encoding: windows-1252.

DEFINE werkbestanden () 'G:\OD_IF_AUD\2_04_Statistiek\2_04_01_Data_en_kaarten\kadaster_percelen\kadaster_gebouwdelen_2015\werkbestanden\' !ENDDEFINE.


GET FILE='' + werkbestanden + 'werkbestand_gebouwdelen.sav'.
DATASET NAME gebouwdelen WINDOW=FRONT.



* woonoppervlaktes.
if nuttige_oppervlakte/woningen < 60 wng_opp_k60=woningen.
if nuttige_oppervlakte/woningen >= 60 & nuttige_oppervlakte/woningen < 80  wng_opp_60_80=woningen.
if nuttige_oppervlakte/woningen >= 80 & nuttige_oppervlakte/woningen < 100  wng_opp_80_100=woningen.
if nuttige_oppervlakte/woningen >= 100 & nuttige_oppervlakte/woningen < 120  wng_opp_100_120=woningen.
if nuttige_oppervlakte/woningen >= 120 & nuttige_oppervlakte/woningen < 140  wng_opp_120_140=woningen.
if nuttige_oppervlakte/woningen >= 140 & nuttige_oppervlakte/woningen < 160  wng_opp_140_160=woningen.
if nuttige_oppervlakte/woningen >= 160  wng_opp_160p=woningen.


* aantal woningen volgens aantal verdiepen van het perceel.
if woningen>0 & missing(verdiepen_inc_dakverdiep) prc_wng_verdiep_onb=woningen.
if woningen>0 & verdiepen_inc_dakverdiep<3 prc_wng_verdiep_0_2=woningen.
if woningen>0 & verdiepen_inc_dakverdiep>2 & verdiepen_inc_dakverdiep<5 prc_wng_verdiep_3_4=woningen.
if woningen>0 & verdiepen_inc_dakverdiep>4 & verdiepen_inc_dakverdiep<10 prc_wng_verdiep_5_9=woningen.
if woningen>0 & verdiepen_inc_dakverdiep>9 prc_wng_verdiep_10plus=woningen.
if woningen>0 verdiepen_woningen=verdiepen_inc_dakverdiep.

* OUDERDOMSKLASSEN WONINGEN volgens oudste bouwjaar.
if missing(bouwjaar_cat) wng_bouwjaar_onbekend=woningen.
if bouwjaar_cat<4 wng_bouwjaar_v1900=woningen.
if bouwjaar_cat=4 wng_bouwjaar_1900_1918=woningen.
if bouwjaar_cat=5 wng_bouwjaar_1919_1930=woningen.
if bouwjaar_exact>=1930 & bouwjaar_exact<=1945 wng_bouwjaar_1931_1945=woningen.
if bouwjaar_exact>=1946 & bouwjaar_exact<=1960 wng_bouwjaar_1946_1960=woningen.
if bouwjaar_exact>=1961 & bouwjaar_exact<=1970 wng_bouwjaar_1961_1970=woningen.
if bouwjaar_exact>=1971 & bouwjaar_exact<=1980 wng_bouwjaar_1971_1980=woningen.
if bouwjaar_exact>=1981 & bouwjaar_exact<=1990 wng_bouwjaar_1981_1990=woningen.
if bouwjaar_exact>=1991 & bouwjaar_exact<=2000 wng_bouwjaar_1991_2000=woningen.
if bouwjaar_exact>=2001 & bouwjaar_exact<=2010 wng_bouwjaar_2001_2010=woningen.
if bouwjaar_exact>=2011 wng_bouwjaar_2011p=woningen.


* puur de wijzigingen per periode.

if jaar_wijziging>0 wng_gewijzigd_1983p=woningen.
if jaar_wijziging<=1990 wng_gewijzigd_1983_1990=woningen.
if jaar_wijziging >= 1991 & jaar_wijziging<=2000 wng_gewijzigd_1991_2000=woningen.
if jaar_wijziging >= 2001 & jaar_wijziging<=2010 wng_gewijzigd_2001_2010=woningen.
if jaar_wijziging >= 2011 wng_gewijzigd_2011p=woningen.

* idem, maar dan volgens recentste jaar wijziging/bouw.
* in geval één van de twee missing is, dan wordt de bekende waarde genomen.
compute recentste_jaar=max(bouwjaar_schatting,jaar_wijziging).
if missing(recentste_jaar) wng_wb_onbekend=woningen.
if recentste_jaar<1900 wng_wb_v1900=woningen.
if recentste_jaar=1908 wng_wb_1900_1918=woningen.
if recentste_jaar=1924 wng_wb_1919_1930=woningen.
if recentste_jaar>=1930 & recentste_jaar<=1945 wng_wb_1931_1945=woningen.
if recentste_jaar>=1946 & recentste_jaar<=1960 wng_wb_1946_1960=woningen.
if recentste_jaar>=1961 & recentste_jaar<=1970 wng_wb_1961_1970=woningen.
if recentste_jaar>=1971 & recentste_jaar<=1980 wng_wb_1971_1980=woningen.
if recentste_jaar>=1981 & recentste_jaar<=1990 wng_wb_1981_1990=woningen.
if recentste_jaar>=1991 & recentste_jaar<=2000 wng_wb_1991_2000=woningen.
if recentste_jaar>=2001 & recentste_jaar<=2010 wng_wb_2001_2010=woningen.
if recentste_jaar>=2011 wng_wb_2011p=woningen.



* kamers per woning.

* het is onmogelijk om kamers per woningen exact te tellen.
* gemiddeldes kunnen wel eenvoudig.
* maar een indeling van het aantal woningen volgens aantal kamers niet.
* immers is per perceeldeel enkel het aantal kamers en het aantal woningen beschikbaar.
* om toch een indeling te maken, maken we de assumptie dat eigendommen niet divers zijn. Ofwel: binnen een eigendom zijn de eigendommen allemaal ongeveer hetzelfde.
* onder deze assumptie verdelen we de kamers evenredig over alle woningen in het perceeldeel. Indien dit een kommagetal zou opleveren, dan houden we de rest over. Die rest wordt dan opnieuw evenredig over de woningen verdeeld.

* naar beneden afgeornde deling van kamers door woningen.
COMPUTE kamersperwoningtrunc=TRUNC(aantal_kamers/woningen).
* overschot aan kamers.
compute restkamers=aantal_kamers-(kamersperwoningtrunc*woningen).
* het overschot aan kamers is ook gelijk aan het aantal woningen dat nog een kamer extra moet krijgen om het totaal te doen kloppen.
* de "hoofdwoningen" zijn dan degene waarvoor onze deling van toepassing is.
compute hoofdwoning=woningen-restkamers.
* de "restwoningen" krijgen de overschot aan kamers, elk één kamer extra.
compute restwoningkamers=kamersperwoningtrunc+1.
compute restwoningen=restkamers.

* om nu te tellen hoeveel woningen er zijn met x kamers, moeten we zowel de "hoofdwoningen" als de "restwoningen" tellen.
if missing(aantal_kamers) kamers_onbekend=woningen.
if kamersperwoningtrunc=1 kamers1=hoofdwoning.
if restwoningkamers=1 kamers1=restwoningen+max(0,kamers1).
if kamersperwoningtrunc=2 kamers2=hoofdwoning.
if restwoningkamers=2 kamers2=restwoningen+max(0,kamers2).
if kamersperwoningtrunc=3 kamers3=hoofdwoning.
if restwoningkamers=3 kamers3=restwoningen+max(0,kamers3).
if kamersperwoningtrunc=4 kamers4=hoofdwoning.
if restwoningkamers=4 kamers4=restwoningen+max(0,kamers4).
if kamersperwoningtrunc=5 kamers5=hoofdwoning.
if restwoningkamers=5 kamers5=restwoningen+max(0,kamers5).
if kamersperwoningtrunc=6 kamers6=hoofdwoning.
if restwoningkamers=6 kamers6=restwoningen+max(0,kamers6).
if kamersperwoningtrunc=7 kamers7=hoofdwoning.
if restwoningkamers=7 kamers7=restwoningen+max(0,kamers7).
if kamersperwoningtrunc>7 kamers8plus=hoofdwoning.
if restwoningkamers>7 kamers8plus=restwoningen+max(0,kamers8plus).

EXECUTE.
delete variables kamersperwoningtrunc
restkamers
restwoningkamers
hoofdwoning
restwoningen.



recode NIS_hoofdgroep (7=9).

* teller maken om percelen maar één keer te tellen.
SORT CASES BY capakey(A) art_deelnr(A).
MATCH FILES
  /FILE=*
  /BY capakey art_deelnr
  /LAST=PrimaryLast.
EXECUTE.


DATASET ACTIVATE gebouwdelen.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /NIS_hoofdgroep_min=MIN(NIS_hoofdgroep).

if primarylast=0 NIS_hoofdgroep_min = 0.

value labels nis_hoofdgroep
1 '1. Appartementen en buildings'
2 '2. Huizen en hoeven en bijgebouwen'
3 '3. Industriele gebouwen'
4 '4. Opslaggebouwen'
5 '5. Kantoorgebouwen'
6 '6. Commerciele gebouwen'
7 '7. Andere'
8 'Onbebouwde percelen'
9 'Andere'.

if NIS_hoofdgroep_min=1 prc_appartementsgebouw=1.
if NIS_hoofdgroep_min=2 prc_huizen=1.
if NIS_hoofdgroep_min=3 prc_industrie=1.
if NIS_hoofdgroep_min=4 prc_opslag=1.
if NIS_hoofdgroep_min=5 prc_kantoor=1.
if NIS_hoofdgroep_min=6 prc_commercieel=1.
if NIS_hoofdgroep_min=8 prc_onbebouwd=1.
if NIS_hoofdgroep_min=9 prc_ander_onbekend=1.

if NIS_hoofdgroep_min=1 prc_oppappartementsgebouw=oppervlakte_perceel_gis.
if NIS_hoofdgroep_min=2 prc_opphuizen=oppervlakte_perceel_gis.
if NIS_hoofdgroep_min=3 prc_oppindustrie=oppervlakte_perceel_gis.
if NIS_hoofdgroep_min=4 prc_oppopslag=oppervlakte_perceel_gis.
if NIS_hoofdgroep_min=5 prc_oppkantoor=oppervlakte_perceel_gis.
if NIS_hoofdgroep_min=6 prc_oppcommercieel=oppervlakte_perceel_gis.
if NIS_hoofdgroep_min=8 prc_opponbebouwd=oppervlakte_perceel_gis.
if NIS_hoofdgroep_min=9 prc_oppander_onbekend=oppervlakte_perceel_gis.

* op buurtniveau.
DATASET DECLARE statsecprc.
AGGREGATE
  /OUTFILE='statsecprc'
  /BREAK=statsec
/wng_opp_k60=sum(wng_opp_k60)
/wng_opp_60_80=sum(wng_opp_60_80)
/wng_opp_80_100=sum(wng_opp_80_100)
/wng_opp_100_120=sum(wng_opp_100_120)
/wng_opp_120_140=sum(wng_opp_120_140)
/wng_opp_140_160=sum(wng_opp_140_160)
/wng_opp_160p=sum(wng_opp_160p)
/prc_wng_verdiep_onb=sum(prc_wng_verdiep_onb)
/prc_wng_verdiep_0_2=sum(prc_wng_verdiep_0_2)
/prc_wng_verdiep_3_4=sum(prc_wng_verdiep_3_4)
/prc_wng_verdiep_5_9=sum(prc_wng_verdiep_5_9)
/prc_wng_verdiep_10plus=sum(prc_wng_verdiep_10plus)
/prc_verdiep_woningen_som=sum(verdiepen_woningen)
/wng_bouwjaar_onbekend=sum(wng_bouwjaar_onbekend)
/wng_bouwjaar_v1900=sum(wng_bouwjaar_v1900)
/wng_bouwjaar_1900_1918=sum(wng_bouwjaar_1900_1918)
/wng_bouwjaar_1919_1930=sum(wng_bouwjaar_1919_1930)
/wng_bouwjaar_1931_1945=sum(wng_bouwjaar_1931_1945)
/wng_bouwjaar_1946_1960=sum(wng_bouwjaar_1946_1960)
/wng_bouwjaar_1961_1970=sum(wng_bouwjaar_1961_1970)
/wng_bouwjaar_1971_1980=sum(wng_bouwjaar_1971_1980)
/wng_bouwjaar_1981_1990=sum(wng_bouwjaar_1981_1990)
/wng_bouwjaar_1991_2000=sum(wng_bouwjaar_1991_2000)
/wng_bouwjaar_2001_2010=sum(wng_bouwjaar_2001_2010)
/wng_bouwjaar_2011p=sum(wng_bouwjaar_2011p)
/wng_gewijzigd_1983p=sum(wng_gewijzigd_1983p)
/wng_gewijzigd_1983_1990=sum(wng_gewijzigd_1983_1990)
/wng_gewijzigd_1991_2000=sum(wng_gewijzigd_1991_2000)
/wng_gewijzigd_2001_2010=sum(wng_gewijzigd_2001_2010)
/wng_gewijzigd_2011p=sum(wng_gewijzigd_2011p)
/wng_wb_onbekend=sum(wng_wb_onbekend)
/wng_wb_v1900=sum(wng_wb_v1900)
/wng_wb_1900_1918=sum(wng_wb_1900_1918)
/wng_wb_1919_1930=sum(wng_wb_1919_1930)
/wng_wb_1931_1945=sum(wng_wb_1931_1945)
/wng_wb_1946_1960=sum(wng_wb_1946_1960)
/wng_wb_1961_1970=sum(wng_wb_1961_1970)
/wng_wb_1971_1980=sum(wng_wb_1971_1980)
/wng_wb_1981_1990=sum(wng_wb_1981_1990)
/wng_wb_1991_2000=sum(wng_wb_1991_2000)
/wng_wb_2001_2010=sum(wng_wb_2001_2010)
/wng_wb_2011p=sum(wng_wb_2011p)
/wng_kamers_onbekend=sum(kamers_onbekend)
/prc_woonkamers1=sum(kamers1)
/prc_woonkamers2=sum(kamers2)
/prc_woonkamers3=sum(kamers3)
/prc_woonkamers4=sum(kamers4)
/prc_woonkamers5=sum(kamers5)
/prc_woonkamers6=sum(kamers6)
/prc_woonkamers7=sum(kamers7)
/prc_woonkamers8plus=sum(kamers8plus)
/prc_appartementsgebouw=sum(prc_appartementsgebouw)
/prc_huizen=sum(prc_huizen)
/prc_industrie=sum(prc_industrie)
/prc_opslag=sum(prc_opslag)
/prc_kantoor=sum(prc_kantoor)
/prc_commercieel=sum(prc_commercieel)
/prc_onbebouwd=sum(prc_onbebouwd)
/prc_ander_onbekend=sum(prc_ander_onbekend)
/prc_oppappartementsgebouw=sum(prc_oppappartementsgebouw)
/prc_opphuizen=sum(prc_opphuizen)
/prc_oppindustrie=sum(prc_oppindustrie)
/prc_oppopslag=sum(prc_oppopslag)
/prc_oppkantoor=sum(prc_oppkantoor)
/prc_oppcommercieel=sum(prc_oppcommercieel)
/prc_opponbebouwd=sum(prc_opponbebouwd)
/prc_oppander_onbekend=sum(prc_oppander_onbekend).
dataset activate statsecprc.
* de volgende aanpassingen zijn er om het bestand helemaal af te stemmen op het formaat van Swing.
rename variables statsec=geoitem.
alter type geoitem (a5).
recode geoitem (""="9999").
compute period=2015.
string geolevel (a5).
compute geolevel="buurt".


DATASET ACTIVATE gebouwdelen.
* om Swing-technische redenen.
recode wijkcode ("SCH01"="").
DATASET DECLARE wijkprc.
AGGREGATE
  /OUTFILE='wijkprc'
  /BREAK=wijkcode
/wng_opp_k60=sum(wng_opp_k60)
/wng_opp_60_80=sum(wng_opp_60_80)
/wng_opp_80_100=sum(wng_opp_80_100)
/wng_opp_100_120=sum(wng_opp_100_120)
/wng_opp_120_140=sum(wng_opp_120_140)
/wng_opp_140_160=sum(wng_opp_140_160)
/wng_opp_160p=sum(wng_opp_160p)
/prc_wng_verdiep_onb=sum(prc_wng_verdiep_onb)
/prc_wng_verdiep_0_2=sum(prc_wng_verdiep_0_2)
/prc_wng_verdiep_3_4=sum(prc_wng_verdiep_3_4)
/prc_wng_verdiep_5_9=sum(prc_wng_verdiep_5_9)
/prc_wng_verdiep_10plus=sum(prc_wng_verdiep_10plus)
/prc_verdiep_woningen_som=sum(verdiepen_woningen)
/wng_bouwjaar_onbekend=sum(wng_bouwjaar_onbekend)
/wng_bouwjaar_v1900=sum(wng_bouwjaar_v1900)
/wng_bouwjaar_1900_1918=sum(wng_bouwjaar_1900_1918)
/wng_bouwjaar_1919_1930=sum(wng_bouwjaar_1919_1930)
/wng_bouwjaar_1931_1945=sum(wng_bouwjaar_1931_1945)
/wng_bouwjaar_1946_1960=sum(wng_bouwjaar_1946_1960)
/wng_bouwjaar_1961_1970=sum(wng_bouwjaar_1961_1970)
/wng_bouwjaar_1971_1980=sum(wng_bouwjaar_1971_1980)
/wng_bouwjaar_1981_1990=sum(wng_bouwjaar_1981_1990)
/wng_bouwjaar_1991_2000=sum(wng_bouwjaar_1991_2000)
/wng_bouwjaar_2001_2010=sum(wng_bouwjaar_2001_2010)
/wng_bouwjaar_2011p=sum(wng_bouwjaar_2011p)
/wng_gewijzigd_1983p=sum(wng_gewijzigd_1983p)
/wng_gewijzigd_1983_1990=sum(wng_gewijzigd_1983_1990)
/wng_gewijzigd_1991_2000=sum(wng_gewijzigd_1991_2000)
/wng_gewijzigd_2001_2010=sum(wng_gewijzigd_2001_2010)
/wng_gewijzigd_2011p=sum(wng_gewijzigd_2011p)
/wng_wb_onbekend=sum(wng_wb_onbekend)
/wng_wb_v1900=sum(wng_wb_v1900)
/wng_wb_1900_1918=sum(wng_wb_1900_1918)
/wng_wb_1919_1930=sum(wng_wb_1919_1930)
/wng_wb_1931_1945=sum(wng_wb_1931_1945)
/wng_wb_1946_1960=sum(wng_wb_1946_1960)
/wng_wb_1961_1970=sum(wng_wb_1961_1970)
/wng_wb_1971_1980=sum(wng_wb_1971_1980)
/wng_wb_1981_1990=sum(wng_wb_1981_1990)
/wng_wb_1991_2000=sum(wng_wb_1991_2000)
/wng_wb_2001_2010=sum(wng_wb_2001_2010)
/wng_wb_2011p=sum(wng_wb_2011p)
/wng_kamers_onbekend=sum(kamers_onbekend)
/prc_woonkamers1=sum(kamers1)
/prc_woonkamers2=sum(kamers2)
/prc_woonkamers3=sum(kamers3)
/prc_woonkamers4=sum(kamers4)
/prc_woonkamers5=sum(kamers5)
/prc_woonkamers6=sum(kamers6)
/prc_woonkamers7=sum(kamers7)
/prc_woonkamers8plus=sum(kamers8plus)
/prc_appartementsgebouw=sum(prc_appartementsgebouw)
/prc_huizen=sum(prc_huizen)
/prc_industrie=sum(prc_industrie)
/prc_opslag=sum(prc_opslag)
/prc_kantoor=sum(prc_kantoor)
/prc_commercieel=sum(prc_commercieel)
/prc_onbebouwd=sum(prc_onbebouwd)
/prc_ander_onbekend=sum(prc_ander_onbekend)
/prc_oppappartementsgebouw=sum(prc_oppappartementsgebouw)
/prc_opphuizen=sum(prc_opphuizen)
/prc_oppindustrie=sum(prc_oppindustrie)
/prc_oppopslag=sum(prc_oppopslag)
/prc_oppkantoor=sum(prc_oppkantoor)
/prc_oppcommercieel=sum(prc_oppcommercieel)
/prc_opponbebouwd=sum(prc_opponbebouwd)
/prc_oppander_onbekend=sum(prc_oppander_onbekend).


dataset activate wijkprc.
rename variables wijkcode=geoitem.
alter type geoitem (a5).
recode geoitem (""="onb").
compute period=2015.
string geolevel (a5).
compute geolevel="wijk".


DATASET ACTIVATE wijkprc.
ADD FILES /FILE=*
  /FILE='statsecprc'.
EXECUTE.

dataset close statsecprc.

recode wng_opp_k60
wng_opp_60_80
wng_opp_80_100
wng_opp_100_120
wng_opp_120_140
wng_opp_140_160
wng_opp_160p
prc_wng_verdiep_onb
prc_wng_verdiep_0_2
prc_wng_verdiep_3_4
prc_wng_verdiep_5_9
prc_wng_verdiep_10plus
prc_verdiep_woningen_som
wng_bouwjaar_onbekend
wng_bouwjaar_v1900
wng_bouwjaar_1900_1918
wng_bouwjaar_1919_1930
wng_bouwjaar_1931_1945
wng_bouwjaar_1946_1960
wng_bouwjaar_1961_1970
wng_bouwjaar_1971_1980
wng_bouwjaar_1981_1990
wng_bouwjaar_1991_2000
wng_bouwjaar_2001_2010
wng_bouwjaar_2011p
wng_gewijzigd_1983p
wng_gewijzigd_1983_1990
wng_gewijzigd_1991_2000
wng_gewijzigd_2001_2010
wng_gewijzigd_2011p
wng_wb_onbekend
wng_wb_v1900
wng_wb_1900_1918
wng_wb_1919_1930
wng_wb_1931_1945
wng_wb_1946_1960
wng_wb_1961_1970
wng_wb_1971_1980
wng_wb_1981_1990
wng_wb_1991_2000
wng_wb_2001_2010
wng_wb_2011p
wng_kamers_onbekend
prc_woonkamers1
prc_woonkamers2
prc_woonkamers3
prc_woonkamers4
prc_woonkamers5
prc_woonkamers6
prc_woonkamers7
prc_woonkamers8plus
prc_appartementsgebouw
prc_huizen
prc_industrie
prc_opslag
prc_kantoor
prc_commercieel
prc_onbebouwd
prc_ander_onbekend
prc_oppappartementsgebouw
prc_opphuizen
prc_oppindustrie
prc_oppopslag
prc_oppkantoor
prc_oppcommercieel
prc_opponbebouwd
prc_oppander_onbekend
(missing=0).




SAVE TRANSLATE OUTFILE='\\Antwerpen.local\Doc\OD_IF_AUD\2_04_Statistiek\2_04_09_Ontwikkeling_website_DSPA\Swing_cijfers_interactief\bestanden_swing\Kadaster\kadaster_2015_extras.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.


