* Encoding: windows-1252.

* deze syntax focust op het classificeren van eigendommen volgens type eigenaars.

* we werken hier volledig in de map werkbestanden.
* locatie werkbestanden.

DEFINE werkbestanden ()
 'C:\Users\sa59772\Desktop\kadasterlokaal\kadaster2016\werkbestanden\' 
!ENDDEFINE.

dataset activate prc.
GET
  FILE=
    '' + werkbestanden + 'werkbestand_gebouwdelen.sav'.
DATASET NAME gebouwdelen WINDOW=FRONT.


* EIGENAARS.
* afhankelijk van wat je wil bekomen (per woning, per perceel) moet je hier op een andere manier mee omgaan.

* vooral door inwonende eigenaars:
- op perceelniveau: je bent inwonende eigenaar van alles op dat perceel dat van jou is.
* op woningniveau: je bent enkel inwonende eigenaar van één woning die in jouw bezit is.

* hier: percelen classificeren.

GET
  FILE=
    '' + werkbestanden + 'eigenaars_gebouwdeel_verwerkt.sav'.
DATASET NAME eigenaars WINDOW=FRONT.
* eigenaarschap op perceelniveau is niet hetzelfde als op woningniveau.
* op woningniveau telt een inwonende eigenaar enkel voor de woning die hij zelf betrekt
* op perceelniveau telt de eigenaar als inwonend, niet alleen voor de woningen die hij er bezit, maar zelfs ook voor de
onbebouwde delen of garages.

* inwonend is nul in de typologie, dus onderstaande syntax maakt een variabele die steeds inwonend aangeeft,
zolang de eigenaar op zijn eigen perceel blijft, maar ongeacht het artikel dat hij er bezit.
* dit heeft een impact op bijna 20.000 perceeldelen.

* minimum type_eigenaar is enkel afwijkend van gewoon type eigenaar bij inwonende eigenaars indien ze op hun eigen perceel zitten.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey officialId
  /type_eigenaar_min=MIN(type_eigenaar).


* MODULE OM EIGENAARS PER TYPE PER PERCEEL TE TELLEN.
DATASET DECLARE temp.
AGGREGATE
  /OUTFILE='temp'
  /BREAK=capakey officialId type_eigenaar_min
  /N_BREAK=N.
dataset activate temp.
if type_eigenaar_min=0 aantal_inwonendantwerps_persoon=1.
if type_eigenaar_min=1 aantal_antwerps_persoon=1.
if type_eigenaar_min=2 aantal_nietantwerps_persoon=1.
if type_eigenaar_min=3 aantal_sociale_eigendom=1.
if type_eigenaar_min=4 aantal_ander_overheid=1.
if type_eigenaar_min=5 aantal_privaat_rechtspersoon=1.


DATASET ACTIVATE temp.
DATASET DECLARE aantaleigenaars.
AGGREGATE
  /OUTFILE='aantaleigenaars'
  /BREAK=capakey
  /aantal_inwonendantwerps_persoon_perceel=SUM(aantal_inwonendantwerps_persoon) 
  /aantal_antwerps_persoon_perceel=SUM(aantal_antwerps_persoon) 
  /aantal_nietantwerps_persoon_perceel=SUM(aantal_nietantwerps_persoon) 
  /aantal_sociale_eigendom_perceel=SUM(aantal_sociale_eigendom) 
  /aantal_ander_overheid_perceel=SUM(aantal_ander_overheid) 
  /aantal_privaat_rechtspersoon_perceel=SUM(aantal_privaat_rechtspersoon)
  /aantal_eigenaars_perceel=N.





* module om het aandeel per perceel te berekenen volgens onze typologie.
* wel degelijk bedoeld voor tellen op niveau van het perceel: een inwonende eigenaar is hier opnieuw geteld als inwonend op al zijn bezittingen op dit perceel.
DATASET ACTIVATE eigenaars.
if type_eigenaar_min=0 aandeel_inwonendantwerps_persoon=breuk_verdeling.
if type_eigenaar_min=1 aandeel_antwerps_persoon=breuk_verdeling.
if type_eigenaar_min=2 aandeel_nietantwerps_persoon=breuk_verdeling.
if type_eigenaar_min=3 aandeel_sociale_eigendom=breuk_verdeling.
if type_eigenaar_min=4 aandeel_ander_overheid=breuk_verdeling.
if type_eigenaar_min=5 aandeel_privaat_rechtspersoon=breuk_verdeling.

* we aggregeren naar perceeldelen.
* voor de aandelen kunnen we de som nemen (want dit zijn steeds delen van dezelfde eigendom).
* voor KI moeten we het maximum nemen (of het eerste, het laatste) want deze waarde is gedefinieerd op niveau van het perceeldeel, niet van de eigenaar.
DATASET ACTIVATE eigenaars.
DATASET DECLARE andereeigenaars.
AGGREGATE
  /OUTFILE='andereeigenaars'
  /BREAK=capakey propertySituationIdf
/aandeel_inwonendantwerps_persoon=SUM(aandeel_inwonendantwerps_persoon)
/aandeel_antwerps_persoon=SUM(aandeel_antwerps_persoon)
/aandeel_nietantwerps_persoon=SUM(aandeel_nietantwerps_persoon)
/aandeel_sociale_eigendom=SUM(aandeel_sociale_eigendom)
/aandeel_ander_overheid=SUM(aandeel_ander_overheid)
/aandeel_privaat_rechtspersoon=SUM(aandeel_privaat_rechtspersoon)
/KI_belastbaar=max(KI_belastbaar)
/KI_onbelastbaar=max(KI_onbelastbaar).
dataset activate andereeigenaars.

recode aandeel_inwonendantwerps_persoon aandeel_antwerps_persoon
aandeel_nietantwerps_persoon
aandeel_sociale_eigendom
aandeel_ander_overheid
aandeel_privaat_rechtspersoon (missing=0).

* hier gaan we na of we in het vorige script de verdeling van de eigendom goed hebben afgehandeld.
compute test= aandeel_inwonendantwerps_persoon+
aandeel_antwerps_persoon+
aandeel_nietantwerps_persoon+
aandeel_sociale_eigendom+
aandeel_ander_overheid+
aandeel_privaat_rechtspersoon.
freq test.
* zowat alle waarden zouden hier dicht bij de 1 moeten liggen. Missing of 0 betekent dat voor dit perceel geen goede verdeelsleutel werd gevonden.


* vereenvoudiging.
* arbitrair: om mengvormen van eigendom niet te dominant te maken, definiëren we iets als eigendom van één type indien minstens 95% van dat type is.
if aandeel_inwonendantwerps_persoon>=0.95 aandeel_inwonendantwerps_persoon=1.
if aandeel_inwonendantwerps_persoon<=0.05 aandeel_inwonendantwerps_persoon=0.
if aandeel_antwerps_persoon>=0.95 aandeel_antwerps_persoon=1.
if aandeel_antwerps_persoon<=0.05 aandeel_antwerps_persoon=0.
if aandeel_nietantwerps_persoon>=0.95 aandeel_nietantwerps_persoon=1.
if aandeel_nietantwerps_persoon<=0.05 aandeel_nietantwerps_persoon=0.
if aandeel_sociale_eigendom>=0.95 aandeel_sociale_eigendom=1.
if aandeel_sociale_eigendom<=0.05 aandeel_sociale_eigendom=0.
if aandeel_ander_overheid>=0.95 aandeel_ander_overheid=1.
if aandeel_ander_overheid<=0.05 aandeel_ander_overheid=0.
if aandeel_privaat_rechtspersoon>=0.95 aandeel_privaat_rechtspersoon=1.
if aandeel_privaat_rechtspersoon<=0.05 aandeel_privaat_rechtspersoon=0.

* eigendomsstructuur perceel voorbereiden.
compute KI_b_aandeel_inwonendantwerps_persoon=aandeel_inwonendantwerps_persoon*KI_belastbaar.
compute KI_b_aandeel_antwerps_persoon=aandeel_antwerps_persoon*KI_belastbaar.
compute KI_b_aandeel_nietantwerps_persoon=aandeel_nietantwerps_persoon*KI_belastbaar.
compute KI_b_aandeel_sociale_eigendom=aandeel_sociale_eigendom*KI_belastbaar.
compute KI_b_aandeel_ander_overheid=aandeel_ander_overheid*KI_belastbaar.
compute KI_b_aandeel_privaat_rechtspersoon=aandeel_privaat_rechtspersoon*KI_belastbaar.
compute KI_onb_aandeel_inwonendantwerps_persoon=aandeel_inwonendantwerps_persoon*KI_onbelastbaar.
compute KI_onb_aandeel_antwerps_persoon=aandeel_antwerps_persoon*KI_onbelastbaar.
compute KI_onb_aandeel_nietantwerps_persoon=aandeel_nietantwerps_persoon*KI_onbelastbaar.
compute KI_onb_aandeel_sociale_eigendom=aandeel_sociale_eigendom*KI_onbelastbaar.
compute KI_onb_aandeel_ander_overheid=aandeel_ander_overheid*KI_onbelastbaar.
compute KI_onb_aandeel_privaat_rechtspersoon=aandeel_privaat_rechtspersoon*KI_onbelastbaar.

match files
/file=*
/keep=capakey
KI_belastbaar
KI_onbelastbaar
KI_b_aandeel_inwonendantwerps_persoon
KI_b_aandeel_antwerps_persoon
KI_b_aandeel_nietantwerps_persoon
KI_b_aandeel_sociale_eigendom
KI_b_aandeel_ander_overheid
KI_b_aandeel_privaat_rechtspersoon
KI_onb_aandeel_inwonendantwerps_persoon
KI_onb_aandeel_antwerps_persoon
KI_onb_aandeel_nietantwerps_persoon
KI_onb_aandeel_sociale_eigendom
KI_onb_aandeel_ander_overheid
KI_onb_aandeel_privaat_rechtspersoon.
EXECUTE.






* AANMAAK BESTAND OP PERCEELNIVEAU.
DATASET DECLARE perceel.
AGGREGATE
  /OUTFILE='perceel'
  /BREAK=capakey
  /KI_belastbaar=sum(KI_belastbaar)
  /KI_onbelastbaar=sum(KI_onbelastbaar)
  /KI_b_aandeel_inwonendantwerps_persoon=sum(KI_b_aandeel_inwonendantwerps_persoon) 
  /KI_b_aandeel_antwerps_persoon=sum(KI_b_aandeel_antwerps_persoon) 
  /KI_b_aandeel_nietantwerps_persoon=sum(KI_b_aandeel_nietantwerps_persoon) 
  /KI_b_aandeel_sociale_eigendom=sum(KI_b_aandeel_sociale_eigendom) 
  /KI_b_aandeel_ander_overheid=sum(KI_b_aandeel_ander_overheid) 
  /KI_b_aandeel_privaat_rechtspersoon=sum(KI_b_aandeel_privaat_rechtspersoon) 
  /KI_onb_aandeel_inwonendantwerps_persoon=sum(KI_onb_aandeel_inwonendantwerps_persoon) 
  /KI_onb_aandeel_antwerps_persoon=sum(KI_onb_aandeel_antwerps_persoon) 
  /KI_onb_aandeel_nietantwerps_persoon=sum(KI_onb_aandeel_nietantwerps_persoon) 
  /KI_onb_aandeel_sociale_eigendom=sum(KI_onb_aandeel_sociale_eigendom) 
  /KI_onb_aandeel_ander_overheid=sum(KI_onb_aandeel_ander_overheid) 
  /KI_onb_aandeel_privaat_rechtspersoon=sum(KI_onb_aandeel_privaat_rechtspersoon).

dataset activate perceel.
MATCH FILES /FILE=*
  /TABLE='aantaleigenaars'
  /BY capakey.
EXECUTE.

dataset close aantaleigenaars.


* om esthetische redenen.
alter type KI_b_aandeel_antwerps_persoon
KI_b_aandeel_nietantwerps_persoon
KI_b_aandeel_sociale_eigendom
KI_b_aandeel_ander_overheid
KI_b_aandeel_privaat_rechtspersoon
KI_onb_aandeel_antwerps_persoon
KI_onb_aandeel_nietantwerps_persoon
KI_onb_aandeel_sociale_eigendom
KI_onb_aandeel_ander_overheid
KI_onb_aandeel_privaat_rechtspersoon (f8.0).

* om  te kunnen optellen.
recode
KI_b_aandeel_antwerps_persoon
KI_b_aandeel_nietantwerps_persoon
KI_b_aandeel_sociale_eigendom
KI_b_aandeel_ander_overheid
KI_b_aandeel_privaat_rechtspersoon
KI_onb_aandeel_antwerps_persoon
KI_onb_aandeel_nietantwerps_persoon
KI_onb_aandeel_sociale_eigendom
KI_onb_aandeel_ander_overheid
KI_onb_aandeel_privaat_rechtspersoon (missing=0).


* eigendomsstructuur perceel aanmaken.

* enkel indien KI belastbaar onbekend is, gebruiken we onbelastbaar deel.
* OPMERKING: dat is niet echt ergens op gebaseerd, ik weet eigenlijk niet goed wat het onbelastbaar KI juist is.
compute sum_bel=KI_b_aandeel_inwonendantwerps_persoon+KI_b_aandeel_antwerps_persoon+
KI_b_aandeel_nietantwerps_persoon+
KI_b_aandeel_sociale_eigendom+
KI_b_aandeel_ander_overheid+
KI_b_aandeel_privaat_rechtspersoon.
compute sum_onb=KI_onb_aandeel_inwonendantwerps_persoon+
KI_onb_aandeel_antwerps_persoon+
KI_onb_aandeel_nietantwerps_persoon+
KI_onb_aandeel_sociale_eigendom+
KI_onb_aandeel_ander_overheid+
KI_onb_aandeel_privaat_rechtspersoon.
compute sum_ki=sum_bel+sum_onb.
if sum_ki=0 type=0.
if sum_onb~=0 type=1.
if sum_bel~=0 type=2.
value labels type
0 'geen ki'
1 'enkel onbelastbaar ki'
2 'belastbaar ki'.
do if type=1.
compute KI_b_aandeel_antwerps_persoon=KI_b_aandeel_antwerps_persoon+KI_onb_aandeel_antwerps_persoon.
compute KI_b_aandeel_nietantwerps_persoon=KI_b_aandeel_nietantwerps_persoon+KI_onb_aandeel_nietantwerps_persoon.
compute KI_b_aandeel_sociale_eigendom=KI_b_aandeel_sociale_eigendom+KI_onb_aandeel_sociale_eigendom.
compute KI_b_aandeel_ander_overheid=KI_b_aandeel_ander_overheid+KI_onb_aandeel_ander_overheid.
compute KI_b_aandeel_privaat_rechtspersoon=KI_b_aandeel_privaat_rechtspersoon+KI_onb_aandeel_privaat_rechtspersoon.
end if.

compute sum_bel=KI_b_aandeel_inwonendantwerps_persoon+
KI_b_aandeel_antwerps_persoon+
KI_b_aandeel_nietantwerps_persoon+
KI_b_aandeel_sociale_eigendom+
KI_b_aandeel_ander_overheid+
KI_b_aandeel_privaat_rechtspersoon.

* het "echte" aandeel.
compute prc_aandeel_inwonendantwerps_persoon=KI_b_aandeel_inwonendantwerps_persoon/sum_bel.
compute prc_aandeel_antwerps_persoon=KI_b_aandeel_antwerps_persoon/sum_bel.
compute prc_aandeel_nietantwerps_persoon=KI_b_aandeel_nietantwerps_persoon/sum_bel.
compute prc_aandeel_sociale_eigendom=KI_b_aandeel_sociale_eigendom/sum_bel.
compute prc_aandeel_ander_overheid=KI_b_aandeel_ander_overheid/sum_bel.
compute prc_aandeel_privaat_rechtspersoon=KI_b_aandeel_privaat_rechtspersoon/sum_bel.

* vereenvoudiging omwille van classificatie.
* opmerking: variabelen met # verdwijnen automatisch uit het bestand eens er een execute loopt. Als je dus tussenstappen wil zien, moet je de # overal verwijderen.
recode 
prc_aandeel_inwonendantwerps_persoon
prc_aandeel_antwerps_persoon
prc_aandeel_nietantwerps_persoon
prc_aandeel_sociale_eigendom
prc_aandeel_ander_overheid
prc_aandeel_privaat_rechtspersoon (0=0) (1=1) (else=2)
into
#aandeel_inwonendantwerps_persoon_cat
#aandeel_antwerps_persoon_cat
#aandeel_nietantwerps_persoon_cat
#aandeel_sociale_eigendom_cat
#aandeel_ander_overheid_cat
#aandeel_privaat_rechtspersoon_cat.

compute #som_cat=
#aandeel_inwonendantwerps_persoon_cat+
#aandeel_antwerps_persoon_cat+
#aandeel_nietantwerps_persoon_cat+
#aandeel_sociale_eigendom_cat+
#aandeel_ander_overheid_cat+
#aandeel_privaat_rechtspersoon_cat.

if #aandeel_inwonendantwerps_persoon_cat=1 type_eigenaars_perceel=0.
if #aandeel_antwerps_persoon_cat=1 type_eigenaars_perceel=1.
if #aandeel_nietantwerps_persoon_cat=1 type_eigenaars_perceel=2.
if (#aandeel_nietantwerps_persoon_cat=2 | #aandeel_antwerps_persoon_cat=2 | #aandeel_inwonendantwerps_persoon_cat=2) 
& (#aandeel_sociale_eigendom_cat + #aandeel_ander_overheid_cat + #aandeel_privaat_rechtspersoon_cat=0) type_eigenaars_perceel=3.
if #aandeel_sociale_eigendom_cat=1 type_eigenaars_perceel=4.
if #aandeel_ander_overheid_cat=1 type_eigenaars_perceel=5.
if #aandeel_privaat_rechtspersoon_cat=1 type_eigenaars_perceel=6.
if missing(type_eigenaars_perceel) & #som_cat>1 type_eigenaars_perceel=7.

VALUE LABELS type_eigenaars_perceel
0 'inwonend Antwerps persoon'
1 'Antwerps persoon'
2 'niet-Antwerps persoon'
3 'zowel Antwerps als niet-Antwerps persoon'
4 'sociale eigenaar'
5 'andere overheid'
6 'privaat rechtspersoon'
7 'complexe eigenaarsstructuur'.

freq type_eigenaars_perceel.
EXECUTE.

delete variables sum_bel
sum_onb
sum_ki
type
prc_aandeel_inwonendantwerps_persoon
prc_aandeel_antwerps_persoon
prc_aandeel_nietantwerps_persoon
prc_aandeel_sociale_eigendom
prc_aandeel_ander_overheid
prc_aandeel_privaat_rechtspersoon.



SAVE OUTFILE='' + werkbestanden + 'eigenaars_perceelniveau.sav'
  /COMPRESSED.



* alternatieve benadering van eigenaarschap: op niveau van de woningen.
*- opgelet: maximaal 1 woning per rij kan een eigenaarswoning zijn
-* opgelet: wat met een inwonende + niet inwonende eigenaar > hier: voorrangsregels toegepast
*- is verdeling eigenaarschap van woningen relevant op perceelniveau?


* dit refresht de dataset met eigenaarsgegevens.
GET
  FILE=
    '' + werkbestanden + 'eigenaars_gebouwdeel_verwerkt.sav'.
DATASET NAME eigenaars WINDOW=FRONT.

dataset close perceel.
dataset close andereeigenaars.
dataset close temp.

DATASET COPY  woningeigenaars.
DATASET ACTIVATE  woningeigenaars.
FILTER OFF.
USE ALL.
SELECT IF (woningen > 0).
EXECUTE.




* in Antwerpen is slechts een minimaal aandeel van de woningen in mengbezit (vb Antwerps/niet-Antwerps = 3%; complex=1,3%).
* Maar wel 13% is "onbekend" omwille van ontbreken KI. Dus gaan we voor een eenvoudiger benadering dan voor percelen. 

if type_eigenaar=0 inwonendantwerps_persoon=1.
if type_eigenaar=1 antwerps_persoon=1.
if type_eigenaar=2 nietantwerps_persoon=1.
if type_eigenaar=3 sociale_eigendom=1.
if type_eigenaar=4 ander_overheid=1.
if type_eigenaar=5 privaat_rechtspersoon=1.

* dit kan eenvoudig uitgebreid worden met telonderwerpjes voor andere types eigenaars.
* zoals bijvoorbeeld:.
* if type_eigenaar=0 & leeftijd>75 oud_inwonendantwerps_persoon=1 .


DATASET DECLARE wooneigendom.
AGGREGATE
  /OUTFILE='wooneigendom'
  /BREAK=propertySituationIdf
  /inwonendantwerps_persoon_wng_eig=SUM(inwonendantwerps_persoon) 
  /antwerps_persoon_wng_eig=SUM(antwerps_persoon) 
  /nietantwerps_persoon_wng_eig=SUM(nietantwerps_persoon) 
  /sociale_eigendom_wng_eig=SUM(sociale_eigendom) 
  /ander_overheid_wng_eig=SUM(ander_overheid) 
  /privaat_rechtspersoon_wng_eig=SUM(privaat_rechtspersoon) 
/woningen=max(woningen).
dataset activate wooneigendom.

* nog steeds opletten met tellen en definieren.
*- in de wng_eig zit een aantal eigenaars van een bepaald type
*- een rij kan meerdere woningen hebben
*- een rij kan steeds slechts maximaal 1 eigenaarswoning hebben, ongeacht of het over meerdere woningen en/of meerdere inwonende eigenaars gaat
*- een eigenaarswoning wellicht ongeacht of er nog andere soorten eigenaars in het spel zijn.

* ongeveer 10% in mengeigendom.
*> voorrang inwonend > 5%
*> voorang A'pen > 1-2%
*> voorrang persoon > minder dan 1%
*> voorrang sociaal
*> voorrang overheid
*> rest: zuiver andere rechtspersonen.

if inwonendantwerps_persoon_wng_eig>0 woning_eigendom_type=1.
if missing(woning_eigendom_type) & antwerps_persoon_wng_eig>0 woning_eigendom_type=2.
if missing(woning_eigendom_type) & nietantwerps_persoon_wng_eig>0 woning_eigendom_type=3.
if missing(woning_eigendom_type) & sociale_eigendom_wng_eig>0 woning_eigendom_type=4.
if missing(woning_eigendom_type) & ander_overheid_wng_eig>0 woning_eigendom_type=5.
if missing(woning_eigendom_type) & privaat_rechtspersoon_wng_eig>0 woning_eigendom_type=6.
value labels woning_eigendom_type
1 'inwonend eigenaar'
2 'Antwerpse eigenaar'
3 'niet-Antwerpse eigenaar'
4 'sociale eigendom'
5 'andere overheid'
6 'andere rechtspersoon'.
FREQUENCIES woning_eigendom_type.

if woning_eigendom_type = 1 eigenaarswoning=1.
if woning_eigendom_type = 1 niet_inwonend_antwerps_wng=woningen-1.
if woning_eigendom_type = 2 niet_inwonend_antwerps_wng=woningen.
if woning_eigendom_type = 3 niet_antwerps_persoon_wng=woningen.
if woning_eigendom_type = 4 sociale_eigendom_wng=woningen.
if woning_eigendom_type = 5 overheidseigendom_wng=woningen.
if woning_eigendom_type = 6 privaat_rechtspersoon_wng=woningen.



SAVE OUTFILE='' + werkbestanden + 'eigenaars_woningen.sav'
  /COMPRESSED.

dataset activate gebouwdelen.
dataset close eigenaars.
dataset close wooneigendom.
dataset close woningeigenaars.
