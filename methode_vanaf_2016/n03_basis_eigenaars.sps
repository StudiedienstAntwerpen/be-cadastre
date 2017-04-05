* Encoding: windows-1252.

* om dit script te laten werken voor je eigen gemeente, moet je dit nog doen:
- geschreven op Antwerpen: er wordt onderscheid gemaakt ts Antwerpenaren en niet-Antwerpenaren
Je kan dus de naamgeving wijzigen en de postcodes aanpassen naar die van jouw gemeente
- Er wordt gerefereerd naar een lijst overheidseigenaars. Die wordt hier intern in elkaar geknutseld voor overheidseigenaars die iets in Antwerpen hebben
Als je dit soort eigenaars zelf wil kunnen identificeren, moet je dus iets gelijkaardigs maken.

* we werken hier volledig in de map werkbestanden.
* locatie werkbestanden.
DEFINE werkbestanden () 'C:\Users\sa59772\Desktop\kadasterlokaal\kadaster2016\werkbestanden\' !ENDDEFINE.
DEFINE basisbestanden () 'C:\Users\sa59772\Desktop\kadasterlokaal\kadaster2016\legger\' !ENDDEFINE.


*eigenaars gebouwdeel (bestand dat we eerder maakten waar elk perceeldeel aan elk van zijn vier potentiële eigenaars is gekoppeld als rijen onder elkaar).

* GET FILE enkel nodig indien je de dataset "eigenaars" uit script 02 hebt afgesloten.
GET
  FILE=
    '' + basisbestanden + 'basisbestand_owner.sav'.
DATASET NAME eigenaars WINDOW=FRONT.
DATASET ACTIVATE eigenaars.


* apen/napen.
compute eig_pc=number(zipcode,f10.0).
alter type eig_pc (f4.0).
recode eig_pc
(2000=1)
(2018=1)
(2020=1)
(2030=1)
(2040=1)
(2050=1)
(2060=1)
(2100=1)
(2140=1)
(2170=1)
(2180=1)
(2600=1)
(2610=1)
(2660=1)
(else=0) into antwerpenaar.


* deze module voegt een variabele toe aan het bestand overheidseigenaar=1 indien het een overheidseigenaar betreft (en missing in andere gevallen). 
GET
  FILE=
    '' + werkbestanden + 'overheidseigenaars.sav'.
DATASET NAME overheid WINDOW=FRONT.

* dit stuk herbekijken als de overheidseigenaars opnieuw gedefinieerd zijn.

sort cases Eig_code (a).
string officialid (a15).
compute #begin=char.index(upcase(eig_code),"0123456789",1).
compute officialid=char.substr(eig_code,#begin,15).
compute #einde=char.index(upcase(officialid),"ABCDEFGHIJKLMNOPQRSTUVWXYZ",1).
if #einde>0 officialid=char.substr(officialid,1,#einde-1).
alter type officialid (f12.0).
sort cases officialid (a).

DATASET ACTIVATE overheid.
* Identify Duplicate Cases.
SORT CASES BY officialid(A).
MATCH FILES
  /FILE=*
  /BY officialid
  /LAST=PrimaryLast.
VARIABLE LABELS  PrimaryLast 'Indicator of each last matching case as Primary'.
VALUE LABELS  PrimaryLast 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryLast (ORDINAL).
EXECUTE.

FILTER OFF.
USE ALL.
SELECT IF (PrimaryLast = 1).
EXECUTE.

delete variables eig_code primarylast.
SORT CASES BY officialid(A).

DATASET ACTIVATE eigenaars.
sort cases officialid (a).
MATCH FILES /FILE=*
  /TABLE='overheid'
  /BY officialid.
EXECUTE.
dataset close overheid.

* hoofdclassificatie eigenaars.
compute type_eigenaar=5.
if ltrim(rtrim(birthdate))~="" | ltrim(rtrim(firstname))~="" type_eigenaar=2.
if antwerpenaar=1 & type_eigenaar=2 type_eigenaar=1.
if overheidseigenaar=1 type_eigenaar=4.
IF (officialid=403795657 | officialid=404710724 | officialid=404688354 | 
    officialid=421111543 | officialid=207500123) type_eigenaar=3.
* OCMW en Stad Antwerpen niet opgenomen als sociale eigenaar.
* opgelet DB207500123EABN is de stad Antwerpen: woningen van de stad zijn allicht sociale woningen, maar ze hebben ook enkele duizenden percelen die niet sociale woningen zijn.
* OCMW is niet opgenomen, omdat zij veel "woningen" hebben die wellicht eerder serviceflats of ziekenhuiskamers zijn.


* mens/bedrijf.
recode type_eigenaar (1=1) (2=1) (else=0) into natuurlijk_rechtspersoon.
value labels natuurlijk_rechtspersoon
0 'rechtspersoon'
1 'natuurlijk persoon'.
if natuurlijk_rechtspersoon=0 rechtspersoon=1.

recode type_eigenaar (3=1) into sociale_woning_eigenaar.




* maak tekstvariabele met rijksregisternummer.
* leeg indien we denken dat het om een bedrijf gaat, als het op nul uitkomt, niet numeriek kan gemaakt worden of een "E" bevat bij conversie 
(die E komt van de conversie naar een numeriek veld van 11 tekens - indien het meer tekens heeft switcht SPSS naar wetenschappelijke notatie
En een rijksregisternummer kan natuurlijk maar 11 tekens hebben).

string rr (a11).
compute rr= replace(string(officialid,f11.0)," ","0").
if natuurlijk_rechtspersoon~=1 | number(rr,f11.0)=0 | missing(number(rr,f11.0)) | CHAR.INDEX(rr,"E")>0  rr="".

* rijksregister = geboortedatum + volgnummer + controlecode.
* als volgnummer even is, dan is het een vrouw.
* is het oneven, dan is het een man.
* dus is de rest (mod) van dit getal bij een natuurlijk deling door 2 = 1 , dan betreft het een man.
compute geslacht=mod(number(char.substr(rr,9,1),f1.0),2).
value labels geslacht
0 'vrouw'
1 'man'.
*compute persoonscode_num=number(char.substr(persoonscode,3),F11.0).

compute geboortejaar = number(char.substr(birthdate,7,4),F4.0).











* einde basisverwerking, over naar module om eigenaarswoningen te bepalen.

* mogelijke verfijning: pachters worden niet uitgeselecteerd, volle eigenaars/versus blote eigenaars etc.

* eerst gaan we het bestand lichter maken:
- verwijderen van perceeldelen die geen woning zijn
- enkel overhouden van natuurlijke personen die in Antwerpen wonen.

* we werken met een subset van potentiële inwonende eigenaars: enkel mensen die in Antwerpen wonen.
* pas later houden we enkel de woningen over.
DATASET COPY inwonendeeigenaars.
DATASET ACTIVATE inwonendeeigenaars.
FILTER OFF.
USE ALL.
SELECT IF (antwerpenaar = 1 & natuurlijk_rechtspersoon = 1).
EXECUTE.


* wat staat er op het perceeldeel: gaan we ophalen in ons werkbestand met gebouwdelen.
* open het bestand of activeer het nog openstaande bestand.
GET
  FILE=
    ''+ werkbestanden + 'werkbestand_gebouwdelen.sav'.
DATASET NAME prc WINDOW=FRONT.
dataset activate prc.


dataset copy gebouwdelen0.
dataset activate gebouwdelen0.

DATASET ACTIVATE gebouwdelen0.
FILTER OFF.
USE ALL.
SELECT IF (order = 1).
EXECUTE.

match files
/file=*
/keep=
propertySituationIdf
capakey
postzone_statsec
postcode_da
street_situation street_code
number
nature
classificatiecode
aard
verdiep
woningen.
rename variables number=number_prc.

* order in prc en eigenaars heeft niets met elkaar te maken.
* er zijn slechts enkele gevallen waar order in prc relevant is.
* in het geval van propertySituationIdf met woningen, kunnen we de volgende onderdelen als dubbels beschouwen.


sort cases propertySituationIdf (a).

DATASET ACTIVATE inwonendeeigenaars.
sort cases propertySituationIdf (a).
MATCH FILES /FILE=*
  /TABLE='gebouwdelen0'
  /BY propertySituationIdf.
EXECUTE.
dataset close gebouwdelen0.

FILTER OFF.
USE ALL.
SELECT IF (woningen > 0).
EXECUTE.






* straatnamen, huisnummers en postcodes van eigenaar en perceeldeel klaarzetten.

* links: de eigenaarsgegevens, rechts de eigendomsgegevens.
compute postcode_links=number(zipcode,f4.0).
compute postcode_rechts=postzone_statsec.

*gaat ervan uit dat beide enkel Antwerpen kunnen zijn.
* je zou ook strenger kunnen zijn: je kan enkel inwonend zijn als pand en adres eigenaar in zelfde postzone liggen. Maar het is courant dat postcodes fout zijn.
if postcode_links=postcode_rechts zelfde_postcode=1.
recode zelfde_postcode (missing=0).


* verwijderen van alle speciale tekens uit de propere straatnamen van de eigenaars.
string straatnaam_links (a100).
compute straatnaam_links=upcase(street_nl).
compute straatnaam_links=replace(straatnaam_links,'Ä','A').
compute straatnaam_links=replace(straatnaam_links,'Ë','E').
compute straatnaam_links=replace(straatnaam_links,'È','E').
compute straatnaam_links=replace(straatnaam_links,'É','E').
compute straatnaam_links=replace(straatnaam_links,'Ï','I').
compute straatnaam_links=replace(straatnaam_links,'Ö','O').
compute straatnaam_links=replace(straatnaam_links,'Ü','U').
compute straatnaam_links=replace(straatnaam_links,'Ç','C').

* manuele correcties.


string huisnummer_string_links (a10).
compute huisnummer_links=number(number,f10.0).
compute huisnummer_string_links=number.
if char.index(huisnummer_string_links,"/-ABCDEFGHIJKLMNOPQRSTUVWXYZ",1)>0 huisnummer_links=number(char.substr(huisnummer_string_links,1,char.index(huisnummer_string_links,"/-ABCDEFGHIJKLMNOPQRSTUVWXYZ",1)-1),f10.0).


* perceelgegevens.
string straatnaam_rechts (a100).
compute straatnaam_rechts=upcase(street_situation).

* enkele foute straatnamen in Antwerpen gecorrigeerd.
recode straatnaam_rechts ("EUTERPASTR"="EUTERPESTRAAT") ("FORT VII STR"="FORT 7-STRAAT") ("ONZE LIEVE VROUWESTR"="ONZE-LIEVE-VROUWSTRAAT").

string huisnummer_string_rechts (a10).
compute huisnummer_rechts=number(number_prc,f10.0).
compute huisnummer_string_rechts=number_prc.
if char.index(huisnummer_string_rechts,"/-ABCDEFGHIJKLMNOPQRSTUVWXYZ",1)>0 huisnummer_rechts=number(char.substr(huisnummer_string_rechts,1,char.index(huisnummer_string_rechts,"/-ABCDEFGHIJKLMNOPQRSTUVWXYZ",1)-1),f10.0).



* op zoek naar ongeveer dezelfde straatnaam.

* je kan dit proces best goed bestuderen, met andere data komen hier mogelijk vreemde resultaten uit.
* hierbij werd gekeken welke straatnaamcombinaties vaak voorkomen, om zo veel voorkomende soorten fouten op te sporen.
* sommige types correcties kunnen in een andere context meer problemen veroorzaken dan ze oplossen.
* of sommige soorten fouten kunnen in Antwerpen heel zeldzaam zijn, maar ergens anders veel voorkomen.

* beide naar lowercase.
compute straatnaam_rechts=lower(straatnaam_rechts).
compute straatnaam_links=lower(straatnaam_links).



* straten gewoon identiek (type 1).
if straatnaam_links=straatnaam_rechts zelfde_straatnaam=1.

* we kennen nu al de labels toe, uiteraard zijn deze hier nog niet van toepassing.
value labels zelfde_straatnaam
0 'naam van de ene straat minstens dubbel zo lang als naam andere straat'
1 'identieke schrijfwijze'
2 'corrigeren sinten, verwijderen +, en kortste straatnaam als referentie maakt identiek'
3 'verwijderen -, weglatingsteken en spatie, vervangen ij>y en ae>aa maakt identiek'
4 'laatste drie letters verwijderen maakt identiek'
5 'deel na punt komt voor in andere straatnaam'
6 'fonetisering maakt identiek'
7 'eerste acht tekens van de straat zijn identiek'
8 'manueel gekoppelde straten'.

* type 0.
* uitsluiten van te hard verschillende straatnamen bij verdere verwerking.
* opmerking: trimmen omdat SPSS soms onverwachte dingen doet met ongebruikte tekens.
compute length_straat_links=length(ltrim(rtrim(straatnaam_links))).
compute length_straat_rechts=length(ltrim(rtrim(straatnaam_rechts))).
if length_straat_links/length_straat_rechts>2 | length_straat_rechts/length_straat_links>2 zelfde_straatnaam=0.
if straatnaam_rechts="" | straatnaam_links="" zelfde_straatnaam=0.


* type 2.

* verwijderen + (overbodige stap).
string straatnaam_links_verkort (a100).
string straatnaam_rechts_verkort (a100).
compute straatnaam_links_verkort=REPLACE(straatnaam_links,"+","").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts,"+","").

* vervang weglatingsteken door spatie, verwijder leidende spatie.
compute straatnaam_links_verkort=ltrim(REPLACE(straatnaam_links_verkort,"'"," ")).

* overal sint vervangen door st.
if char.index(straatnaam_links_verkort,"sint")=1 straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"sint","st").
if char.index(straatnaam_rechts_verkort,"sint")=1 straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"sint","st").
if char.index(straatnaam_links_verkort,"sint-")>0 straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"sint-","st-").
if char.index(straatnaam_rechts_verkort,"sint-")>0 straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"sint-","st-").

* kap beide straatnamen af op de lengte van de kortste.
compute length_straat_links=length(ltrim(rtrim(straatnaam_links_verkort))).
compute length_straat_rechts=length(ltrim(rtrim(straatnaam_rechts_verkort))).
compute straatnaam_links_verkort=CHAR.SUBSTR(straatnaam_links_verkort,1,MIN(length_straat_links,length_straat_rechts)).
compute straatnaam_rechts_verkort=CHAR.SUBSTR(straatnaam_rechts_verkort,1,MIN(length_straat_links,length_straat_rechts)).
if missing(zelfde_straatnaam) & straatnaam_links_verkort=straatnaam_rechts_verkort zelfde_straatnaam=2.


* type 3.

* verwijder streepjes, weglatingstekens en spaties.
* vervang ij door y.
* vervang AE door AA.
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"-","").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"'","").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort," ","").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"ae","aa").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"ij","y").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"-","").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"'","").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort," ","").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"ae","aa").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"ij","y").
compute length_straat_links1=length(ltrim(rtrim(straatnaam_links_verkort))).
compute length_straat_rechts1=length(ltrim(rtrim(straatnaam_rechts_verkort))).
compute straatnaam_links_verkort=CHAR.SUBSTR(straatnaam_links_verkort,1,MIN(length_straat_links1,length_straat_rechts1)).
compute straatnaam_rechts_verkort=CHAR.SUBSTR(straatnaam_rechts_verkort,1,MIN(length_straat_links1,length_straat_rechts1)).

if missing(zelfde_straatnaam) & straatnaam_links_verkort=straatnaam_rechts_verkort zelfde_straatnaam=3.


* type 4.

* anders afgekort? drie letters laten vallen op basis van lengte kortste straatnaam.
compute straatnaam_links_verkort=CHAR.SUBSTR(straatnaam_links_verkort,1,MIN(length_straat_links1,length_straat_rechts1)-3).
compute straatnaam_rechts_verkort=CHAR.SUBSTR(straatnaam_rechts_verkort,1,MIN(length_straat_links1,length_straat_rechts1)-3).
if missing(zelfde_straatnaam) & straatnaam_links_verkort=straatnaam_rechts_verkort zelfde_straatnaam=4.



* type 5.

* zoek binnen de ene straatnaam naar het deel na de laatste punt in de andere straatnaam.
compute length_straat_links=length(ltrim(rtrim(straatnaam_links))).
compute length_straat_rechts=length(ltrim(rtrim(straatnaam_rechts))).
compute punt_links=CHAR.RINDEX(straatnaam_links,".")+1.
compute punt_rechts=CHAR.RINDEX(straatnaam_rechts,".")+1.
string straatnaam_links_vk (a50).
string straatnaam_rechts_vk (a50).
if punt_links > 1 & length_straat_links-punt_links>5 straatnaam_links_vk=char.subst(straatnaam_links,punt_links,punt_links+8).
if missing(zelfde_straatnaam) & CHAR.INDEX(straatnaam_rechts,ltrim(rtrim(straatnaam_links_vk)))>0 zelfde_straatnaam=5.
if punt_rechts > 1 & length_straat_rechts-punt_rechts>5 straatnaam_rechts_vk=char.subst(straatnaam_rechts,punt_rechts,punt_rechts+8).
if missing(zelfde_straatnaam) & CHAR.INDEX(straatnaam_links,ltrim(rtrim(straatnaam_rechts_vk)))>0 zelfde_straatnaam=5.



* type 6.
* typische schrijffouten oplossen door gelijk klinkende letters te vervangen door meest eenvoudige schrijfwijze.

* fonetiseer en verwijder punt.
compute straatnaam_links_verkort=REPLACE(straatnaam_links,"straat","str").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts,"straat","str").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"-","").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"'","").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort," ","").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"ae","aa").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"ij","y").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"-","").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"'","").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort," ","").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"ae","aa").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"ij","y").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"th","t").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"x","s").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"ci","ti").

compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,".","").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"ss","s").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"tt","t").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"sch","ch").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"kleine","klein").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"gene","geen").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"oo","o").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"k","c").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"d","t").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"cq","q").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"aa","a").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"ee","e").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"gh","g").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"th","t").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"x","s").
compute straatnaam_links_verkort=REPLACE(straatnaam_links_verkort,"ci","ti").

compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,".","").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"ss","s").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"tt","t").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"sch","ch").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"kleine","klein").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"gene","geen").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"oo","o").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"k","c").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"d","t").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"cq","q").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"aa","a").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"ee","e").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts_verkort,"gh","g").

compute length_straat_links=length(ltrim(rtrim(straatnaam_links_verkort))).
compute length_straat_rechts=length(ltrim(rtrim(straatnaam_rechts_verkort))).
compute straatnaam_links_verkort=CHAR.SUBSTR(straatnaam_links_verkort,1,MIN(length_straat_links,length_straat_rechts)).
compute straatnaam_rechts_verkort=CHAR.SUBSTR(straatnaam_rechts_verkort,1,MIN(length_straat_links,length_straat_rechts)).

if missing(zelfde_straatnaam) & straatnaam_links_verkort=straatnaam_rechts_verkort zelfde_straatnaam=6.


* type 7.
* eerste acht tekens van de straatnaam.
if missing(zelfde_straatnaam) & char.substr(straatnaam_links,1,8)=char.substr(straatnaam_rechts,1,8) zelfde_straatnaam=7.

* type 8.
* manuele toevoegingen.
* in sommige gevallen is het heel duidelijk dat het adres van het perceeldeel fout is, hier bijvoorbeeld omdat er een nieuwe straatnaam werd ingevoerd.
* het is NIET voorzien dat in deze situaties het huisnummer mag genegeerd worden.
* overigens gaat het hier maar om 8 gevallen... 
if straatnaam_links='zuidervelodroom' & straatnaam_rechts='st-laureisstr' zelfde_straatnaam=8.
if straatnaam_links='zuidervelodroom' & straatnaam_rechts='haantjeslei' zelfde_straatnaam=8.
if straatnaam_links='charlesdecosterlaan' & straatnaam_rechts='micheletstr' zelfde_straatnaam=8.


recode zelfde_straatnaam (missing=99).
frequencies zelfde_straatnaam.

* tussenvariabelen verwijderen.
delete variables straatnaam_links
straatnaam_rechts
length_straat_links
length_straat_rechts
straatnaam_links_verkort
straatnaam_rechts_verkort
length_straat_links1
length_straat_rechts1
punt_links
punt_rechts
straatnaam_links_vk
straatnaam_rechts_vk.



* huisnummers vergelijken.

* is er uberhaupt iets zinvol? (type=0).
recode huisnummer_string_links
huisnummer_string_rechts (""=0) (else=1) into hnr_links_waarde hnr_rechts_waarde.


* er is geen perceel huisnummer.
if hnr_rechts_waarde=0 zelfde_huisnummer=0.
value labels zelfde_huisnummer
0 'huisnummer perceel ontbreekt'
1 'huisnummers zelfde string'
2 'huisnummer zelfde numerieke waarde'
3 'huisnummerdeel is gelijk'
4 'huisnummer van de buren'
99 'zelfde straat, maar toch ander huisnummer'.

* identieke tekst (type=1).
if missing(zelfde_huisnummer) & huisnummer_string_links=huisnummer_string_rechts zelfde_huisnummer=1.

* identiek numeriek (type=2).
if missing(zelfde_huisnummer) & huisnummer_links=huisnummer_rechts zelfde_huisnummer=2.

* type=3.
* indien huisnummer "/" bevat en een deel van de huisnummers komt ook voor in een ander deel van het huisnummer wellicht ook gelijk.
* OPMERKING: het is enkel nodig het deel NA slash te testen, want ons eerdere script om huisnummers af te splitsen neemt al enkel het deel VOOR de slash mee.
string huisnummer_links_naslash (a50).
if CHAR.INDEX(huisnummer_string_links,"/")>0 huisnummer_links_naslash=ltrim(rtrim(char.substr(huisnummer_string_links,CHAR.INDEX(huisnummer_string_links,"/")+1))).
string huisnummer_rechts_naslash (a50).
if CHAR.INDEX(huisnummer_string_rechts,"/")>0 huisnummer_rechts_naslash=ltrim(rtrim(char.substr(huisnummer_string_rechts,CHAR.INDEX(huisnummer_string_rechts,"/")+1))).
if missing(zelfde_huisnummer) & (huisnummer_string_links=huisnummer_rechts_naslash | huisnummer_string_rechts=huisnummer_links_naslash) zelfde_huisnummer=3.

* type 4: het huisnummer van de eigendom ligt naast dat van de eigenaar.
if missing(zelfde_huisnummer) & ABS(huisnummer_links-huisnummer_rechts)<3 zelfde_huisnummer=4.

* speciale gevallen: woont elders in de straat - betwijfelbaar of dit in werkelijkheid zo vaak kan voorkomen.
if missing(zelfde_huisnummer) & zelfde_straatnaam>0 & zelfde_straatnaam<10 zelfde_huisnummer=99.

* even checken wat eruit komt.
frequencies zelfde_huisnummer.

* verwijderen tussenvariabelen.
delete variables huisnummer_links
huisnummer_string_links
huisnummer_rechts
huisnummer_string_rechts
hnr_links_waarde
hnr_rechts_waarde
huisnummer_links_naslash
huisnummer_rechts_naslash.


match files
/file=*
/keep=
propertySituationIdf
order
capakey
street_nl
number
street_situation
number_prc
officialId
right
antwerpenaar
natuurlijk_rechtspersoon
zelfde_postcode
zelfde_straatnaam
zelfde_huisnummer
woningen.

sort cases propertySituationIdf (a) order (a).



recode zelfde_straatnaam (1 thru 8=1) (else=0) into zelfde_straatnaam_dummy.

compute kwalimatch=0.
if zelfde_postcode=1 & zelfde_straatnaam_dummy=1 & (zelfde_huisnummer=1 | zelfde_huisnummer=2) kwalimatch=1.
if zelfde_postcode=0 & zelfde_straatnaam_dummy=1 & (zelfde_huisnummer<5) kwalimatch=2.
if zelfde_postcode=1 & zelfde_straatnaam_dummy=1 & (zelfde_huisnummer=3 | zelfde_huisnummer=4) kwalimatch=3.
if kwalimatch=0 & zelfde_straatnaam_dummy=1 kwalimatch=4.

value labels kwalimatch
0 'zeker verschillend adres'
1 'zeker zelfde adres'
2 'enkel postcode verkeerd'
3 'huisnummer hoogstwaarschijnlijk gelijk'
4 'straatnaam is gelijk, maar twijfel over postcode en/of kwaliteit huisnummer'.
freq kwalimatch.
freq zelfde_straatnaam zelfde_huisnummer zelfde_postcode.


* we gaan op zoek naar de best passen woning voor onze eigenaars.
compute in_te_vullen_woningen=woningen.
compute potentiele_eigenaar=1.
compute bewoond_door_eigenaar=$sysmis.

* als je meer wil experimenteren, zet even een kopie opzij. Want het voorgaande deel is nogal zwaar.
*dataset copy backup.

* verwijder potentiele eigenaars die het zeker niet zijn uit bestand.
* wijs eigenaars toe aan een woning indien ze zeker daar wonen.

* deze eigenaars komen sowieso niet in aanmerking.
FILTER OFF.
USE ALL.
SELECT IF ( kwalimatch~= 0).
EXECUTE.

* sorteer eigenaars volgens het meest overeenkomstige adres.
* ken toe aan het eerste adres, onder voorwaarde dat het wellicht over hetzelfde huisnummer en straat gaat.

sort cases officialId (a) kwalimatch(a).
if $casenum=1 volgnummer=1.
if lag(officialId)~=officialId volgnummer=1.
if lag(officialId)=officialId volgnummer=lag(volgnummer)+1.

if volgnummer=1 & kwalimatch<4 bewoond_door_eigenaar=1.
if volgnummer > 1 | kwalimatch=4 bewoond_door_eigenaar=0.
if volgnummer > 1 | kwalimatch=4 potentiele_eigenaar=0.

freq bewoond_door_eigenaar.
* hou enkel de eigenaarswoningen over.
FILTER OFF.
USE ALL.
SELECT IF (bewoond_door_eigenaar = 1).
EXECUTE.

* verwijder balast.
match files
/file=*
/keep=propertySituationIdf
order officialId
bewoond_door_eigenaar.
RENAME VARIABLES bewoond_door_eigenaar=inwonende_eigenaar.
sort cases propertySituationIdf (a) order (a) officialId (a).


* voeg de nieuwe variable toe aan het eigenaarsbestand.
DATASET ACTIVATE eigenaars.
sort cases propertySituationIdf (a) order (a) officialId (a).
MATCH FILES /FILE=*
  /TABLE='inwonendeeigenaars'
  /BY propertySituationIdf
order officialId.
EXECUTE.

* indien matchen gelukt is.
dataset close inwonendeeigenaars.


* afwerken verdeling in soorten eigenaars.

if type_eigenaar=1 & inwonende_eigenaar=1 type_eigenaar=0.
value labels type_eigenaar
0 'inwonende eigenaar'
1 'niet-inwonende Antwerps persoon'
2 'niet-Antwerps persoon'
3 'sociale eigenaar'
4 'andere overheid'
5 'private rechtspersoon'.
freq type_eigenaar.




* EINDE MODULE INWONENDE EIGENAARS.

* TO DO: vanaf hier verder doen.

* VERDELING EIGENDOM.
DATASET ACTIVATE eigenaars.

* DIT STUK RETROACTIEF BEKIJKEN.
* retro-actief toe te passen: franstalige codes in right hier mee verwerkt!
* TO DO RETROACTIEF: dit was een foute veronderstelling: als er niets staat is het bijna altijd een "manager"' (managedBy=1), dus geen eigenaar. Breuk verdeling moet hier 0 zijn, kreeg vroeger 1.

* de variabele right bevat een verdeelsleutel van het eigendom. Daarnaast bevat het ook informatie over verpachting, blote eigendom of volle eigendom. En bovendien nog info over het einde van het recht.
* identiek dezelfde info zit in right_trad. Maar hier is de code vaker (steeds?) in het Nederlands verwerkt.
* aan de hand van die variabele, kunnen we een verdeling maken van hoeveel bezit er bij wat voor eigenaars zit.
* Om dit te kunnen aggregren naar percelen of hogere niveaus, zullen we die verdeelsleutel toepassen op het Kadastraal Inkomen.


* Franstalige codes in bestand:
*PP -> VE
NP -> BE
US -> VG
EMPH -> ERFP
SUPERF -> OPSTAL

* NIEUWE METHODE.
* opsplisten in tekstdeel 1, breuk 1, tekstdeel 2, breuk 2.



* stap 1: splits op in een deel verdeelsleutel en een deel over het einde van het recht.

string right_verdeelsleutel (a50).
string right_einderecht (a50).

* einde recht wordt aangegeven met een > , behalve als ze dit fout hebben ingevuld. De volgende regel corrigeert.
compute right_trad =replace(right_trad,"<",">").
if right_trad="-" right_trad=right.
* isoleer de verdeelsleutel.
* meestal geeft dit het resultaat.
compute right_verdeelsleutel=right_trad.
* indien er ook een einde recht is, verwijder dan die info.
if char.index(right_trad,">")>0 right_verdeelsleutel=char.substr(right_trad,1,char.index(right_trad,">")-1).
* verwijder liggende streepjes aan begin en einde van de verdeelsleutel.
compute right_verdeelsleutel=ltrim(rtrim(rtrim(replace(right_verdeelsleutel,"(","")),"-"),"-").
* vul einderecht in indien dit voor handen is.
if char.index(right_trad,">")>0 right_einderecht=char.substr(right_trad,char.index(right_trad,">")).
if char.index(right_einderecht,")")>0 right_einderecht=char.substr(right_einderecht,1,char.index(right_einderecht,")")-1).

* we werken met een tijdelijke kopie van de verdeelsleutel (eig_deel1) voor de verwerking tot omschrijvingen van de verdeling.
STRING  eig_deel1 (A70).
COMPUTE eig_deel1=right_verdeelsleutel.

* we identificeren de eerste breuk en zijn omschrijving.
* op zoek naar de positie van het eerste nummer.
COMPUTE nummer1=CHAR.INDEX(eig_deel1,"1234567890",1).
* op zoek naar de positie van de eerste / na het eerste nummer (er kunnen immers ook / staan in de tekst).
COMPUTE slash1=char.index(char.substr(eig_deel1,nummer1),"/").
* nul ("niets gevonden") op missing zetten, zodat in verdere stappen er geen false positives ontstaan.
recode slash1 nummer1 (0=sysmis).
* we berekenen de absolute positie van de eerste slash.
COMPUTE slash1=slash1+nummer1-1.
* op zoek naar de eerste spatie na een slash, dus het einde van de eerste breuk. Opgelet, dit is het aantal tekens te rekenen vanaf de slash, niet vanaf het begin.
compute spatie_na_slash1=char.index(char.substr(eig_deel1,slash1+1)," ").
* maak de eerste omschrijving aan en vul op met het eerste niet-numeriek deel.
string omschrijving1 (a50).
compute omschrijving1=char.substr(eig_deel1,1,nummer1-1).
* vul op met het hele basisveld indien er geen breuk in de tekst staat.
if missing(slash1) omschrijving1=eig_deel1.
* vul de eerste teller en eerste noemer in.
compute teller1=number(char.substr(eig_deel1,nummer1,slash1-nummer1),f8.0).
compute noemer1=number(char.substr(eig_deel1,slash1+1,spatie_na_slash1-1),f8.0).

* soms is er nog een tweede tekst en tweede breuk beschikbaar.
* we gaan op zoek naar tekst na de eerste breuk.
compute tekst2=CHAR.INDEX(char.substr(eig_deel1,spatie_na_slash1+slash1),"ABCDEFGHIJKLMNOZPQRSTUVWXYZ",1).
* we gaan op zoek naar een cijfer na de eerste breuk.
compute nummer2=CHAR.INDEX(char.substr(eig_deel1,spatie_na_slash1+slash1),"1234567890",1).
* als we tekst gevonden zouden hebben, dan geven we de absolute positie van die tekst aan.
if tekst2>0 positietekst2=tekst2+spatie_na_slash1+slash1-1.
* als we een cijfer gevonden zouden hebben, dan geven we de absolute positie van dat nummer aan.
if nummer2>0 positienummer2=nummer2+spatie_na_slash1+slash1-1.
string omschrijving2 (a50).
* als er geen tweede cijfer is, dan nemen we gewoon de rest mee als tekst.
if missing(positienummer2) omschrijving2=char.substr(eig_deel1,positietekst2).
* is er wel nog een cijfer, dan nemen we enkel het deel voor dat cijfer mee.
if positienummer2>0 omschrijving2=char.substr(eig_deel1,positietekst2,nummer2-tekst2).
* als er nog een slash is na de eerste slash in een breuk, dan berekenen we er de absolute positie van.
if CHAR.INDEX(char.substr(eig_deel1,slash1+1),"/")>0 slash2=CHAR.INDEX(char.substr(eig_deel1,slash1+1),"/")+slash1.
* daarmeer kunen we de tweede teller en niemer opsporen.
compute teller2=number(char.substr(eig_deel1,positienummer2,char.index(char.substr(eig_deel1,positienummer2),"/")-1),f8.0).
compute noemer2=number(char.substr(eig_deel1,slash2+1,char.index(char.substr(eig_deel1,slash2)," ")-1),f8.0).

EXECUTE.
delete variables eig_deel1
nummer1
slash1
spatie_na_slash1
tekst2
nummer2
positietekst2
positienummer2
slash2.

* beslis welke breuken we meenemen uit deel1.
* bereken de waarde.
* doe hetzelfde met deel2 en tel op.

* wat nemen we expliciet mee.
if any(ltrim(rtrim(omschrijving1)),"GEBOUW VE","ONB","VERP GROND","VERP","BE","VE","NP","PP","VE-BEZ-OPSTAL","EIG.GROND","EIG.GROND","EIG.GROND DEEL","VG BE","GEBOUW","VE-BEZ-ERFP")=1 eigendom_teller=teller1.
if any(ltrim(rtrim(omschrijving1)),"GEBOUW VE","ONB","VERP GROND","VERP","BE","VE","NP","PP","VE-BEZ-OPSTAL","EIG.GROND","EIG.GROND","EIG.GROND DEEL","VG BE","GEBOUW","VE-BEZ-ERFP")=1 eigendom_noemer=noemer1.

*wat nemen we expliciet niet mee.
if any(ltrim(rtrim(omschrijving1)),"VG","ERFP","OPSTAL")=1 eigendom_teller=0.
if any(ltrim(rtrim(omschrijving1)),"VG","ERFP","OPSTAL")=1 eigendom_noemer=1.


* wat nemen we expliciet mee.
if any(ltrim(rtrim(omschrijving2)),"GEBOUW VE","ONB","VERP GROND","VERP","BE","VE","NP","PP","VE-BEZ-OPSTAL","EIG.GROND","EIG.GROND","EIG.GROND DEEL","VG BE","GEBOUW","VE-BEZ-ERFP")=1 eigendom_teller2=teller2.
if any(ltrim(rtrim(omschrijving2)),"GEBOUW VE","ONB","VERP GROND","VERP","BE","VE","NP","PP","VE-BEZ-OPSTAL","EIG.GROND","EIG.GROND","EIG.GROND DEEL","VG BE","GEBOUW","VE-BEZ-ERFP")=1 eigendom_noemer2=noemer2.

*wat nemen we expliciet niet mee.
if any(ltrim(rtrim(omschrijving2)),"VG","ERFP","OPSTAL")=1 eigendom_teller2=0.
if any(ltrim(rtrim(omschrijving2)),"VG","ERFP","OPSTAL")=1 eigendom_noemer2=1.


* indien er geen breuk kon gevormd worden, dan gaan we ervan uit dat de omschrijving op de hele eigendom slaat.
if (missing(eigendom_teller) | eigendom_teller=0) & 
any(ltrim(rtrim(omschrijving1)),"GEBOUW VE","ONB","VERP GROND","VERP","BE","VE","NP","PP","VE-BEZ-OPSTAL","EIG.GROND","EIG.GROND","EIG.GROND DEEL","VG BE","GEBOUW","VE-BEZ-ERFP")=1 eigendom_teller=1.
if missing(eigendom_noemer)
& any(ltrim(rtrim(omschrijving1)),"GEBOUW VE","ONB","VERP GROND","VERP","BE","VE","NP","PP","VE-BEZ-OPSTAL","EIG.GROND","EIG.GROND","EIG.GROND DEEL","VG BE","GEBOUW","VE-BEZ-ERFP")=1 eigendom_noemer=1.

if (missing(eigendom_teller2)  | eigendom_teller2=0) 
& any(ltrim(rtrim(omschrijving2)),"GEBOUW VE","ONB","VERP GROND","VERP","BE","VE","NP","PP","VE-BEZ-OPSTAL","EIG.GROND","EIG.GROND","EIG.GROND DEEL","VG BE","GEBOUW","VE-BEZ-ERFP")=1 eigendom_teller2=1.
if missing(eigendom_noemer2) 
& any(ltrim(rtrim(omschrijving2)),"GEBOUW VE","ONB","VERP GROND","VERP","BE","VE","NP","PP","VE-BEZ-OPSTAL","EIG.GROND","EIG.GROND","EIG.GROND DEEL","VG BE","GEBOUW","VE-BEZ-ERFP")=1 eigendom_noemer2=1.


* bereken de breuk.
compute aandeel_eigendom=eigendom_teller/eigendom_noemer.
if eigendom_teller2/eigendom_noemer2>0 aandeel_eigendom=aandeel_eigendom+eigendom_teller2/eigendom_noemer2.
if missing(aandeel_eigendom) aandeel_eigendom=eigendom_teller2/eigendom_noemer2.

* managers zijn geen eigenaars.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=propertySituationIdf
  /managedowner=max(managedBy).
if managedBy=1 aandeel_eigendom=0.
if missing(managedBy) & managedowner=1 & missing(aandeel_eigendom) aandeel_eigendom=1.


* we testen het resultaat.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=propertySituationIdf
  /som_aandelen=SUM(aandeel_eigendom)
  /aantal_eigenaars=N.

* indien het resultaat niet ok is, maar is maar één eigenaar gekend, dan geven we die eigenaar de volledige eigendom.
if aantal_eigenaars=1 & (som_aandelen=0 | missing(som_aandelen)) aandeel_eigendom=1.
* wanneer er geen breuken beschikbaar zijn, maar er is wel info dat iemand verpacht, dan geven we die volledige eigendom.
if som_aandelen=0 & (omschrijving1="VERP" | omschrijving1="VERP DEEL") aandeel_eigendom=1.

* we controleren opnieuw.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=propertySituationIdf
  /som_aandelen=SUM(aandeel_eigendom).

* in enkele gevallen kunnen we nu nog wat meer expliciet toekennen.
* dit zijn veel mogelijke waarden, maar het gaat om weinig gevallen.
* eerst de variaties op pachters.
if (missing(som_aandelen) | som_aandelen=0) & any(ltrim(rtrim(omschrijving1)),
'ERFP',
'VG DEEL',
'VG',
'GEBOUW VG',
'OPSTAL',
'VG VERP',
'BEWONING',
'GEBOUW ERFP',
'BEWONING DEEL',
'GEBR/BEWON',
'ERFP DEEL',
'ERFP GEBOUW',
'ERFP.GROND',
'GEBOUW BEWONING',
'DEEL ERFP EIG.GROND',
'ERFP EIG.GROND',
'ERFP VR 00A 73CA',
'ERFP VR 09A 22CA',
'ERFP VR 22CA',
'ERFP VR 49CA',
'ERFP VR 4HA 98A 32CA',
'GEBRUIK DEEL',
'GEBRUIK-OPSTAL - GEBOUW',
'VERP BE',
'VERP DEEL',
'VERP EIG.GROND',
'VERP VG',
'VERP VR 00A 34CA',
'VERP VR 09A 22CA',
'VERP VR 22CA',
'VERP VR 49CA',
'VERP VR 4HA 98A 32CA',
'VERP VR 75A 74CA',
'VERP.GROND',
'VG BE DEEL',
'VG EIG.GROND',
'VG OPSTAL',
'VG-BEZ-ERFP',
'VR 00A 32CA',
'VR 01 HA 11 A 00 CA',
'VR 01A 03CA',
'VR 01A 14CA',
'VR 01A 27CA',
'VR 01A 44CA',
'VR 01A 47CA',
'VR 01CA',
'VR 03A 33CA',
'VR 05A 23CA',
'VR 17A 92CA',
'VR 1HA 11A 61CA',
'VR 1HA 43A 71CA',
'VR 26A 04CA',
'VR 68A 57CA',
'VR 85CA',
'VR 94 A 51 CA') aandeel_eigendom=0.

* dan de variaties op eigenaars.
if (missing(som_aandelen) | som_aandelen=0) & any(ltrim(rtrim(omschrijving1)),'DEEL',
'GROND',
'GEBOUW DEEL',
'BE DEEL',
'GEBOUW VERP',
'GEBOUW BE',
'BE VERP',
'GROND DEEL',
'VE BE DEEL',
'VE DEEL BE DEEL',
'GROND VERP',
'VE-BEZ-BEWONING',
'DEEL GEBOUW',
'VERP GEBOUW',
'BE-BEZ-GEBR/BEWON',
'BE - GEBOUW',
'BE EIG.GROND',
'BE OPSTAL EIG.GROND',
'BE-BEZ-BEWONING',
'BE-BEZ-ERFP',
'DEEL VE DEEL BE',
'EIG.GROND -EIG.GROND',
'EIGENAAR GROND/GEBOUW',
'VE DEEL',
'VE DEEL - BE DEEL',
'VE DEEL BE',
'VE DEEL GEBRUIK DEEL BE DEEL',
'VE-BEZ-GEBR/BEWON') aandeel_eigendom=1.

* potentiele eigenaars meenemen.
if missing(aandeel_eigendom) potentiele_eigenaar=1.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=propertySituationIdf
  /som_aandelen=SUM(aandeel_eigendom)
  /som_potentiele_eigenaar=sum(potentiele_eigenaar).

*if som_aandelen=0 & missing(aandeel_eigendom) aandeel_eigendom=1.
compute aandeel_eigendom=aandeel_eigendom/som_aandelen.
if (missing(som_aandelen) | som_aandelen=0) & missing(aandeel_eigendom) & potentiele_eigenaar=1 aandeel_eigendom=1/som_potentiele_eigenaar.
EXECUTE.

delete variables 
eigendom_teller
eigendom_noemer
eigendom_teller2
eigendom_noemer2
managedowner
aantal_eigenaars
potentiele_eigenaar
som_aandelen
som_potentiele_eigenaar.

rename variables (
omschrijving1
teller1
noemer1
omschrijving2
teller2
noemer2
aandeel_eigendom=
right_omschrijving_deel_1
right_teller_deel_1
right_noemer_1
right_omschrijving_deel_2
right_teller_deel_2
right_noemer_2
breuk_verdeling).



* mogelijk is het zinvol om hier KI toe te voegen.

* verdeling KI.
*compute KI_belastbaar_deel=KI_belastbaar*breuk_verdeling.
*compute KI_onbelastbaar_deel=KI_onbelastbaar*breuk_verdeling.
* opmerking: totaal KI staat nu nog merdere keren in het bestand, let op dat je dit niet meerdere keren gaat tellen per perceeldeel.



* we maken een basisindeling van eigenaars:
0 'gewone eigenaar'
1 'eigenaar met partner'
2 'partner van de eigenaar'
3 'eigenaar met gekende manager'
4 'manager, geen eigenaar'.

* we maken volwaardige eigenaars van de partners.
* je kan ze eenvoudig weer wegfilteren door owner_type=partner van de eigenaar te deleten.
* opgelet: doordat je rijen toevoegt, maak je de verdeelsleutel van eigenaarschap kapot. Dus op het moment dat je daar iets mee doet, moet je ofwel de partners negeren, ofwel hun waarden nog eens door twee delen.

DATASET ACTIVATE eigenaars.
compute owner_classificatie=0.
if officialId_partner > 0 owner_classificatie=1.
if managedby > 0 owner_classificatie=4.

DATASET ACTIVATE eigenaars.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=propertySituationIdf order
  /managedBy_max=MAX(managedBy).

if missing(managedBy) & managedBy_max=1 owner_classificatie = 3.

value labels owner_classificatie
0 'gewone eigenaar'
1 'eigenaar met partner'
2 'partner van de eigenaar'
3 'eigenaar met gekende manager'
4 'manager, geen eigenaar'.

DATASET COPY  partners.
DATASET ACTIVATE  partners.
FILTER OFF.
USE ALL.
SELECT IF (officialId_partner > 0).
EXECUTE.
compute owner_classificatie=2.
compute officialId=officialId_partner.
compute name=name_partner.
compute firstname=firstName_partner.
compute birthdate=birthdate_partner.
compute country=country_partner.
compute zipCode=zipCode_partner.
compute municipality_fr=municipality_partner_fr.
compute municipality_nl=municipality_partner_nl.
compute street_fr=street_partner_fr.
compute street_nl=street_partner_nl.
compute number=number_partner.
compute boxNumber=boxNumber_partner.
DATASET ACTIVATE eigenaars.
ADD FILES /FILE=*
  /FILE='partners'.
EXECUTE.
dataset close partners.

frequencies owner_classificatie.

delete variables managedBy_max.
compute breuk_verdeling_partners=breuk_verdeling.
if owner_classificatie=2 | owner_classificatie=1 breuk_verdeling_partners=breuk_verdeling/2.
if owner_classificatie=2 breuk_verdeling=$sysmis.
EXECUTE.

VARIABLE LABELS breuk_verdeling "breuk verdeling eigendom, gecleaned, missing indien partner".
VARIABLE LABELS breuk_verdeling_partners "breuk verdeling eigendom, gecleaned, eigendom 50/50 verdeeld over partners".
VARIABLE LABELS owner_classificatie "hoofdverdeling eigenaars".


* variabelen overzetten.
dataset activate prc.
dataset copy gebouwdelen0.
dataset activate gebouwdelen0.
FILTER OFF.
USE ALL.
SELECT IF (order = 1).
EXECUTE.

match files
/file=*
/keep=
propertySituationIdf
capakey
woningen 
KI_belastbaar
KI_onbelastbaar.
sort cases propertySituationIdf (a).

DATASET ACTIVATE eigenaars.
sort cases propertySituationIdf (a).
MATCH FILES /FILE=*
  /TABLE='gebouwdelen0'
  /BY propertySituationIdf.
EXECUTE.
dataset close gebouwdelen0.

SAVE OUTFILE='' + werkbestanden + 'eigenaars_gebouwdeel_verwerkt.sav'
  /COMPRESSED.

