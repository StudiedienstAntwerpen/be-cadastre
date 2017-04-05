* Encoding: windows-1252.
DEFINE werkbestanden () 'C:\Users\sa59772\Desktop\kadasterlokaal\kadaster2016\werkbestanden\' !ENDDEFINE.
* vergeet de backslash op het einde niet!

GET FILE='' + werkbestanden + 'werkbestand_gebouwdelen.sav'.
DATASET NAME gebouwdelen WINDOW=FRONT.

* basics uit woningeigenaars: tel woningen volgens type eigenaar.
GET
  FILE=
    '' + werkbestanden + 'eigenaars_woningen.sav'.
DATASET NAME woningeigenaars WINDOW=FRONT.
match files
/file=*
/keep=
propertySituationIdf
eigenaarswoning
niet_inwonend_antwerps_wng
niet_antwerps_persoon_wng
sociale_eigendom_wng
overheidseigendom_wng
privaat_rechtspersoon_wng.
EXECUTE.
sort cases propertySituationIdf (a).

DATASET ACTIVATE gebouwdelen.
sort cases propertySituationIdf (a).
MATCH FILES /FILE=*
  /TABLE='woningeigenaars'
  /BY propertySituationIdf.
EXECUTE.
dataset close woningeigenaars.


* dummies maken om gemakkelijker te kunnen tellen.
if type_constructie=1 gesloten_bebouwing=1.
if type_constructie=2 halfopen_bebouwing=1.
if type_constructie=3 open_bebouwing=1.

* berekening woon en totale beschikbare oppervlakte.
RECODE nuttige_oppervlakte (0=SYSMIS) (else=copy) into nuttige_opp.
if woningen>0 woonoppervlakte=nuttige_opp.
* belachelijk grote en belachelijk kleine woningen beschouwen we als fout.
if woonoppervlakte/woningen > 1000 | woonoppervlakte/woningen < 20 woonoppervlakte=$sysmis.
* oppervlaktes voor andere dingen dan woningen.
if missing(woningen) | woningen=0  nietwoonnuttigeoppervlakte=nuttige_oppervlakte.
if missing(woningen) | woningen=0  nietwoonbebouwdeoppervlakte=bebouwde_oppervlakte.



* telonderwerp voor arbitrair gedefinieerde "oude woningen".
if woningen>0 & bouwjaar_schatting < 1990 prc_oudewoning=woningen.
if prc_oudewoning>0 & jaar_wijziging >= 1990 prc_oudewoning=$sysmis.




compute prc_sombouwjaren_woningen=woningen*bouwjaar_schatting.
if woningen>0 & bouwjaar_schatting>0 prc_woningen_met_bouwjaar=woningen.

* nis indeling.
if NIS_hoofdgroep =1 nis_app_building=1.
if NIS_hoofdgroep =2 nis_huis_hoeve=1.
if NIS_hoofdgroep =3 nis_industrie=1.
if NIS_hoofdgroep =4 nis_opslag=1.
if NIS_hoofdgroep =5 nis_kantoor=1.
if NIS_hoofdgroep =6 nis_commercieel=1.
if NIS_hoofdgroep =7 nis_ander=1.
if NIS_hoofdgroep =8 nis_onbebouwd=1.
if NIS_hoofdgroep =8 nis_niettoegekend=1.






DATASET DECLARE basic.
AGGREGATE
  /OUTFILE='basic'
  /BREAK=capakey statsec wijkcode
/aantal_perceeldelen=N
/oppervlakte_perceel_gis=max(oppervlakte_perceel_gis)
/juridische_oppervlakte_perceel=max(juridische_oppervlakte_perceel)
/woningen=SUM(woningen)
/eigenaarswoning=sum(eigenaarswoning)
/niet_inwonend_antwerps_wng=sum(niet_inwonend_antwerps_wng)
/niet_antwerps_persoon_wng=sum(niet_antwerps_persoon_wng)
/sociale_eigendom_wng=sum(sociale_eigendom_wng)
/overheidseigendom_wng=sum(overheidseigendom_wng)
/privaat_rechtspersoon_wng=sum(privaat_rechtspersoon_wng)
/woonkamers=sum(aantal_kamers)
/kamers_niet_woning=sum(kamers_niet_woning)
/bebouwde_oppervlakte=sum(bebouwde_oppervlakte)
/nuttige_oppervlakte=sum(nuttige_oppervlakte)
/woonoppervlakte=sum(woonoppervlakte)
/nietwoonnuttigeoppervlakte=sum(nietwoonnuttigeoppervlakte)
/nietwoonbebouwdeoppervlakte=sum(nietwoonbebouwdeoppervlakte)
/bebouwde_oppervlakte_origineel=sum(bebouwde_oppervlakte_origineel)
/nuttige_oppervlakte_origineel=sum(nuttige_oppervlakte_origineel)
/gesloten_bebouwing=max(gesloten_bebouwing)
/halfopen_bebouwing=max(halfopen_bebouwing)
/open_bebouwing=max(open_bebouwing)
/oudste_bouwjaar=min(bouwjaar_schatting)
/recentste_bouwjaar=max(bouwjaar_schatting)
/bouwjaar_origineel_recentst=max(bouwjaar_ruw)
/prc_oudewoning=sum(prc_oudewoning)
/prc_sombouwjaren_woningen=sum(prc_sombouwjaren_woningen)
/prc_woningen_met_bouwjaar=sum(prc_woningen_met_bouwjaar)
/recentste_jaar_wijziging=max(jaar_wijziging)
/verdiepen=max(verdiepen_inc_dakverdiep)
/perceel_gebruik=first(perceel_gebruik)
/NIS_hoofdgroep=min(nis_hoofdgroep)
/nis_app_building=max(nis_app_building)
/nis_huis_hoeve=max(nis_huis_hoeve)
/nis_industrie=max(nis_industrie)
/nis_opslag=max(nis_opslag)
/nis_kantoor=max(nis_kantoor)
/nis_commercieel=max(nis_commercieel)
/nis_ander=max(nis_ander)
/nis_onbebouwd=max(nis_onbebouwd)
/nis_niettoegekend=max(nis_niettoegekend)
/parkeerplaatsen=sum(aantal_parkeerplaatsen).
DATASET ACTIVATE basic.


DATASET ACTIVATE gebouwdelen.
string adresnotatie (a120).
compute adresnotatie = concat(ltrim(rtrim(street_situation))," ",ltrim(rtrim(number))).
DATASET DECLARE adressen.
AGGREGATE
  /OUTFILE='adressen'
  /BREAK=capakey adresnotatie
  /N_BREAK=N.
DATASET DECLARE adressen.
AGGREGATE
  /OUTFILE='adressen'
  /BREAK=capakey street_situation number
  /N_BREAK=N.
dataset activate adressen.

if $casenum=1 volgnummer=1.
if capakey~=lag(capakey) volgnummer=1.
if capakey=lag(capakey) volgnummer=lag(volgnummer)+1.


AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /uniekadressen=N.

string huisnummers (a50).
if volgnummer=1 huisnummers=number.
if capakey=lag(capakey) & street_situation~=lag(street_situation) huisnummers=number. 
if capakey=lag(capakey) & street_situation=lag(street_situation) huisnummers=concat(ltrim(rtrim(lag(huisnummers))),"; ",number). 

AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey street_situation
  /aantalkeerstraat=N.

string tussenadres (a300).
compute tussenadres = concat(ltrim(rtrim(street_situation))," ",ltrim(rtrim(huisnummers))).

if $casenum=1 volgnummer_str=1.
if capakey~=lag(capakey) volgnummer_str=1.
if capakey=lag(capakey) & street_situation~=lag(street_situation) volgnummer_str=1.
if capakey=lag(capakey) & street_situation=lag(street_situation) volgnummer_str=lag(volgnummer_str)+1.


FILTER OFF.
USE ALL.
SELECT IF (volgnummer_str = aantalkeerstraat).
EXECUTE.

string adressen (a300).
if capakey~=lag(capakey) adressen=tussenadres.
if capakey=lag(capakey) & tussenadres=lag(tussenadres) adressen=lag(adressen). 
if capakey=lag(capakey) & tussenadres~=lag(tussenadres) adressen=concat(ltrim(rtrim(lag(adressen))),", ",tussenadres). 


FILTER OFF.
USE ALL.
SELECT IF (volgnummer = uniekadressen).
EXECUTE.

* als er heel veel adressen zijn, geef dan aan dat niet alles weergegeven is met [...].
if length(ltrim(rtrim(adressen)))=300 adressen=concat("[...]",adressen).

match files
/file=*
/keep=capakey adressen.





* tot hier nagekeken.





DATASET ACTIVATE basic.
MATCH FILES /FILE=*
  /TABLE='adressen'
  /BY capakey.
EXECUTE.
dataset close adressen.


GET
  FILE='' + werkbestanden + 'eigenaars_perceelniveau.sav'.
DATASET NAME perceeleigenaars WINDOW=FRONT.
sort cases capakey (a).
MATCH FILES
/file=*
/keep=capakey KI_belastbaar
KI_onbelastbaar aantal_inwonendantwerps_persoon_perceel
aantal_antwerps_persoon_perceel
aantal_nietantwerps_persoon_perceel
aantal_sociale_eigendom_perceel
aantal_ander_overheid_perceel
aantal_privaat_rechtspersoon_perceel
aantal_eigenaars_perceel
type_eigenaars_perceel.

DATASET ACTIVATE basic.
MATCH FILES /FILE=*
  /TABLE='perceeleigenaars'
  /BY capakey.
EXECUTE.
dataset close perceeleigenaars.

* onbebouwde percelen.
if nis_onbebouwd = 1 & nvalid(nis_app_building,nis_huis_hoeve,nis_industrie,nis_opslag,nis_kantoor,nis_commercieel,nis_ander,nis_niettoegekend)=0 bebouwingstype=1.
if nis_onbebouwd = 1 & nvalid(nis_app_building,nis_huis_hoeve,nis_industrie,nis_opslag,nis_kantoor,nis_commercieel,nis_ander,nis_niettoegekend)>0 bebouwingstype=2.
if missing(nis_onbebouwd) bebouwingstype=3.
value labels bebouwingstype
1 'compleet onbebouwd'
2 'deels onbebouwd'
3 'geen onbebouwd deel'.

* geheel onbebouwde percelen oppervlakte.
if bebouwingstype=1 onbebouwd_perceel=1.
*if bebouwingstype=1 prc_onbebouwd_opp=prc_opp_gis.

* juridische oppervlakte van onbebouwde percelen.
if bebouwingstype=1 prc_onbebouwd_opp=juridische_oppervlakte_perceel.

* aantal percelen.
compute aantal_percelen=1.


recode verdiepen
(lowest thru 0=0) (0 thru 0.99=0) (missing=-9999).
missing values verdiepen (-9999).
value labels verdiepen '-9999' missing.


* Totale vloeroppervlakte.
compute prc_vloeroppervlakte=nuttige_oppervlakte.
if missing(nuttige_oppervlakte) | nuttige_oppervlakte=0 prc_vloeroppervlakte=bebouwde_oppervlakte*(verdiepen+1).
if missing(prc_vloeroppervlakte) prc_vloeroppervlakte=bebouwde_oppervlakte.



* verdiepen van percelen met bekende, niet-industriele functie.
compute verdiep_relevant=0.
if perceel_gebruik~=6 & perceel_gebruik~=14 verdiep_relevant=1.
if missing(verdiepen) & verdiep_relevant=1 verdiep_onb=1.
if verdiep_relevant=1 & verdiepen<3 verdiep_0_2=1.
if verdiep_relevant=1 & verdiepen>2 & verdiepen<5 verdiep_3_4=1.
if verdiep_relevant=1 & verdiepen>4 & verdiepen<10 verdiep_5_9=1.
if verdiep_relevant=1 & verdiepen>9 verdiep_10plus=1.
if verdiep_relevant=0 verdiepen=-9999.



* gesloten/halfopen/open bebouwing is enkel relevant voor woonhuizen.
* we tellen het enkel indien het een perceel betreft met één woning waar een huis of handelshuis staat.
if gesloten_bebouwing = 1 & woningen=1 & (perceel_gebruik=1 | perceel_gebruik=5) prc_woning_rijhuis=1.
if halfopen_bebouwing = 1 & woningen=1 & (perceel_gebruik=1 | perceel_gebruik=5) prc_woning_halfopenhuis=1.
if open_bebouwing = 1 & woningen=1 & (perceel_gebruik=1 | perceel_gebruik=5) prc_woning_openhuis=1.


* eengezinswoningen/meergezinswoningen.
* HIER: enkel een eengezinswoning indien het één woning is op een huizenperceel.
* HIER: een meergezinswoning als er meerdere woningen op het perceel zijn OF het is een appartementenperceel)

* het onderscheid appartement/huis is absoluut niet hetzelfde als het onderscheid appartement/woonhuis.
* de meeste meergezinswoningen zitten in appartementen (duh!).
* MAAR: er zijn heel wat huizen met meerdere woningen (10000 percelen met in totaal 30000 woningen).
* MAAR: er zijn heel wat handelshuizen met meerdere woningen (4000 prc met 8000 wng). 
* MAAR: er zijn enkele appartementsgebouwen met maar één woning (500 prc).
*KEUZE HIER:
>-	Het perceel is een eengezinswoning op voorwaarde dat er een huis staat met maximaal 1 woning
>-	Het perceel is een meergezinswoning als er meerdere woningen zijn en ook als het geclassificeerd is als appartementsgebouw met minstens een woning

* eengezin/meergezinswoning.
if woningen=1 & (perceel_gebruik=1 | perceel_gebruik=5) prc_eengezinswoning=1.
if woningen>1 | ((perceel_gebruik=2 | perceel_gebruik=3 | perceel_gebruik=4) & woningen=1) prc_meergezinswoningen=woningen.

* platte variabelen om zelf een keuze te maken:
* eengezin/meergezinswoning.
*if woningen=1 eenmeergezin=1.
*if woningen>1 eenmeergezin=2.
* appartement/huis.
*if perceel_gebruik=1 | (perceel_gebruik=5 & woningen>0) huisapp=1.
*if (perceel_gebruik=2 |  perceel_gebruik=3 |  perceel_gebruik=4) & woningen>0 huisapp=2.

if prc_eengezinswoning=1 & eigenaarswoning=1 prc_eengezins_eigenaarswoning=1.

* parkeren.
if woningen>0 prc_woon_parkeren=parkeerplaatsen.
if prc_woon_parkeren=0 & woningen>0 prc_woningen_geenparking=woningen.
if prc_woon_parkeren>0 & prc_woon_parkeren<woningen prc_woningen_teweinigparking=woningen.
if prc_woon_parkeren=woningen prc_woningen_netgenoegparking=woningen.
if prc_woon_parkeren>woningen prc_woningen_parkeeroverschot=woningen.



* kamers.
rename variables woonkamers=prc_woonkamers.


RENAME VARIABLES eigenaarswoning=eigenaarswoningen.
rename variables prc_onbebouwd_opp=onbebouwd_opp.
rename variables prc_vloeroppervlakte=vloeroppervlakte.

rename variables prc_woonkamers=woonkamers.
rename variables prc_eengezinswoning=eengezinswoning.
rename variables prc_meergezinswoningen=meergezinswoningen.


match files
/file=* 
keep=capakey
statsec
WijkCode
adressen
aantal_perceeldelen
oppervlakte_perceel_gis
juridische_oppervlakte_perceel
bebouwde_oppervlakte_origineel
nuttige_oppervlakte_origineel
bebouwde_oppervlakte
onbebouwd_opp
nuttige_oppervlakte
woonoppervlakte
vloeroppervlakte
verdiepen
woningen
eigenaarswoningen
eengezinswoning
meergezinswoningen
woonkamers
bouwjaar_origineel_recentst
oudste_bouwjaar
recentste_bouwjaar
recentste_jaar_wijziging
prc_sombouwjaren_woningen
prc_woningen_met_bouwjaar
parkeerplaatsen
type_eigenaars_perceel
bebouwingstype.



SAVE OUTFILE='' + werkbestanden + 'dataset_percelen.sav'
  /COMPRESSED.


* op buurtniveau.
DATASET DECLARE statsecprc.
AGGREGATE
  /OUTFILE='statsecprc'
  /BREAK=statsec
  /prc_woningen=SUM(woningen) 
  /prc_aantal=N
  /prc_opp_gis=SUM(oppervlakte_perceel_gis) 
  /prc_juridische_oppervlakte=sum(juridische_oppervlakte_perceel)
  /prc_verdiep_relevant=SUM(verdiep_relevant)
  /prc_verdiep_som=sum(verdiepen)
  /prc_verdiep_0_2=SUM(verdiep_0_2) 
  /prc_verdiep_3_4=SUM(verdiep_3_4) 
  /prc_verdiep_5_9=SUM(verdiep_5_9) 
  /prc_verdiep_10plus=SUM(verdiep_10plus)
/prc_n_woonkamers=sum(prc_woonkamers)
  /prc_woning_rijhuis=SUM(prc_woning_rijhuis) 
  /prc_woning_halfopenhuis=SUM(prc_woning_halfopenhuis) 
  /prc_woning_openhuis=SUM(prc_woning_openhuis) 
  /prc_eengezinswoning=SUM(prc_eengezinswoning) 
  /prc_meergezinswoningen=SUM(prc_meergezinswoningen) 
  /prc_woon_parkeren=SUM(prc_woon_parkeren) 
  /prc_woningen_geenparking=SUM(prc_woningen_geenparking) 
  /prc_woningen_teweinigparking=SUM(prc_woningen_teweinigparking) 
  /prc_woningen_netgenoegparking=SUM(prc_woningen_netgenoegparking) 
  /prc_woningen_parkeeroverschot=SUM(prc_woningen_parkeeroverschot)
  /prc_vloeroppervlakte=SUM(prc_vloeroppervlakte)
   /prc_woonoppervlakte=SUM(woonoppervlakte)
   /prc_door_eigenaar_bewoonde_woning=sum(eigenaarswoning)
/prc_eengezins_eigenaarswoning=sum(prc_eengezins_eigenaarswoning)
/prc_oudewoning=sum(prc_oudewoning)
/prc_sombouwjaren_woningen=sum(prc_sombouwjaren_woningen)
/prc_woningen_met_bouwjaar=sum(prc_woningen_met_bouwjaar).
dataset activate statsecprc.
* de volgende aanpassingen zijn er om het bestand helemaal af te stemmen op het formaat van Swing.
rename variables statsec=geoitem.
alter type geoitem (a5).
recode geoitem (""="9999").
compute period=2015.
string geolevel (a5).
compute geolevel="buurt".

*op wijkniveau.
* deze extra aggregatie is nodig omdat niet alle wijkgrenzen exact samenvallen met sectorgrenzen. Als jouw wijken wel mooi gebouwd zijn op sectorgrenzen, is een eenmalige aggregatie voldoende.
DATASET ACTIVATE basic.
* om Swing-technische redenen.
recode wijkcode ("SCH01"="").
DATASET DECLARE wijkprc.
AGGREGATE
  /OUTFILE='wijkprc'
  /BREAK=wijkcode
  /prc_woningen=SUM(woningen) 
  /prc_aantal=N
  /prc_opp_gis=SUM(oppervlakte_perceel_gis) 
  /prc_juridische_oppervlakte=sum(juridische_oppervlakte_perceel)
  /prc_verdiep_relevant=SUM(verdiep_relevant)
  /prc_verdiep_som=sum(verdiepen)
  /prc_verdiep_0_2=SUM(verdiep_0_2) 
  /prc_verdiep_3_4=SUM(verdiep_3_4) 
  /prc_verdiep_5_9=SUM(verdiep_5_9) 
  /prc_verdiep_10plus=SUM(verdiep_10plus)
/prc_n_woonkamers=sum(prc_woonkamers)
  /prc_woning_rijhuis=SUM(prc_woning_rijhuis) 
  /prc_woning_halfopenhuis=SUM(prc_woning_halfopenhuis) 
  /prc_woning_openhuis=SUM(prc_woning_openhuis) 
  /prc_eengezinswoning=SUM(prc_eengezinswoning) 
  /prc_meergezinswoningen=SUM(prc_meergezinswoningen) 
  /prc_woon_parkeren=SUM(prc_woon_parkeren) 
  /prc_woningen_geenparking=SUM(prc_woningen_geenparking) 
  /prc_woningen_teweinigparking=SUM(prc_woningen_teweinigparking) 
  /prc_woningen_netgenoegparking=SUM(prc_woningen_netgenoegparking) 
  /prc_woningen_parkeeroverschot=SUM(prc_woningen_parkeeroverschot)
  /prc_vloeroppervlakte=SUM(prc_vloeroppervlakte)
   /prc_woonoppervlakte=SUM(woonoppervlakte)
   /prc_door_eigenaar_bewoonde_woning=sum(eigenaarswoning)
/prc_eengezins_eigenaarswoning=sum(prc_eengezins_eigenaarswoning)
/prc_oudewoning=sum(prc_oudewoning)
/prc_sombouwjaren_woningen=sum(prc_sombouwjaren_woningen)
/prc_woningen_met_bouwjaar=sum(prc_woningen_met_bouwjaar).
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


recode prc_woningen
prc_aantal
prc_opp_gis
prc_juridische_oppervlakte
prc_verdiep_relevant
prc_verdiep_som
prc_verdiep_0_2
prc_verdiep_3_4
prc_verdiep_5_9
prc_verdiep_10plus
prc_n_woonkamers
prc_woning_rijhuis
prc_woning_halfopenhuis
prc_woning_openhuis
prc_eengezinswoning
prc_meergezinswoningen
prc_woon_parkeren
prc_woningen_geenparking
prc_woningen_teweinigparking
prc_woningen_netgenoegparking
prc_woningen_parkeeroverschot
prc_vloeroppervlakte
prc_woonoppervlakte
prc_door_eigenaar_bewoonde_woning
prc_eengezins_eigenaarswoning
 (missing=0).


EXECUTE.

SAVE TRANSLATE OUTFILE='\\Antwerpen.local\Doc\OD_IF_AUD\2_04_Statistiek\2_04_09_Ontwikkeling_website_DSPA\Swing_cijfers_interactief\bestanden_swing\Kadaster\kadaster_2015.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.

