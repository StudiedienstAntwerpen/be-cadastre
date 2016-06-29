* Encoding: windows-1252.

* om dit script te laten werken, moet je dit nog doen:
- geschreven op Antwerpen: er wordt onderscheid gemaakt ts Antwerpenaren en niet-Antwerpenaren
Je kan dus de naamgeving wijzigen en de postcodes aanpassen naar die van jouw gemeente
- Er wordt gerefereerd naar een lijst overheidseigenaars. Die wordt hier intern in elkaar geknutseld voor overheidseigenaars die iets in Antwerpen hebben
Als je dit soort eigenaars zelf wil kunnen identificeren, moet je dus iets gelijkaardigs maken.

* we werken hier volledig in de map werkbestanden.
* locatie werkbestanden.
DEFINE werkbestanden () 'G:\OD_IF_AUD\2_04_Statistiek\2_04_01_Data_en_kaarten\kadaster_percelen\kadaster_gebouwdelen_2015\werkbestanden\' !ENDDEFINE.


*eigenaars gebouwdeel (bestand dat we eerder maakten waar elk perceeldeel aan elk van zijn vier potentiële eigenaars is gekoppeld als rijen onder elkaar).

* GET FILE enkel nodig indien je de dataset "eigenaars" uit script 02 hebt afgesloten.
GET
  FILE=
    '' + werkbestanden + 'eigenaars_gebouwdeel.sav'.
DATASET NAME eigenaars WINDOW=FRONT.
DATASET ACTIVATE eigenaars.
* apen/napen.
string eig_pc (a4).
compute eig_pc=CHAR.SUBSTR(eigenaar_post_stad,1,4).


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
sort cases Eig_code (a).
DATASET ACTIVATE eigenaars.
sort cases Eig_code (a).
MATCH FILES /FILE=*
  /TABLE='overheid'
  /BY Eig_code.
EXECUTE.
dataset close overheid.

* hoofdclassificatie eigenaars.
compute type_eigenaar=5.
if char.subst(eig_code,1,2)="XX" | char.subst(eig_code,1,2)="XY" type_eigenaar=2.
if antwerpenaar=1 & (char.subst(eig_code,1,2)="XX" | char.subst(eig_code,1,2)="XY") type_eigenaar=1.
if overheidseigenaar=1 type_eigenaar=4.
IF (Eig_code='FM403795657EABN' | Eig_code='FM404710724EABN' | Eig_code='AM404688354XXXN' | 
    Eig_code='AM421111543XXXN' | Eig_code=' DB207500123EABN') type_eigenaar=3.
* OCMW en Stad Antwerpen niet opgenomen als sociale eigenaar.
* opgelet DB207500123EABN is de stad Antwerpen: woningen van de stad zijn allicht sociale woningen, maar ze hebben ook enkele duizenden percelen die niet sociale woningen zijn.
* OCMW is niet opgenomen, omdat zij veel "woningen" hebben die wellicht eerder serviceflats of ziekenhuiskamers zijn.

value labels type_eigenaar
1 'Antwerps persoon'
2 'niet-Antwerps persoon'
3 'sociale eigenaar'
4 'andere overheid'
5 'private rechtspersoon'.



* mens/bedrijf.
recode type_eigenaar (1=1) (2=1) (else=0) into natuurlijk_rechtspersoon.
value labels natuurlijk_rechtspersoon
0 'rechtspersoon'
1 'natuurlijk persoon'.
if natuurlijk_rechtspersoon=0 rechtspersoon=1.

string persoonscode (a45).
if natuurlijk_rechtspersoon=1 persoonscode=eig_code.

recode type_eigenaar (3=1) into sociale_woning_eigenaar.

if char.substr(persoonscode,1,2)="XX" geslacht=0.
if char.substr(persoonscode,1,2)="XY" geslacht=1.
value labels geslacht
0 'vrouw'
1 'man'.
*compute persoonscode_num=number(char.substr(persoonscode,3),F11.0).

* jaarlijks aan te passen, 2014 lijkt het beste jaartal om voor de legger van 2015 te gebruiken. 
compute geboortejaar = number(char.substr(persoonscode,3,2),F4.0).
if geboortejaar > 14 geboortejaar = 1900+geboortejaar.
if geboortejaar <= 14 geboortejaar = 2000+geboortejaar.
compute leeftijd=2014-geboortejaar.




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
match files
/file=*
/keep=
aav
art_aard
classificatiecode
aard
verdiep
woningen.
sort cases aav (a).
rename variables aav=art_deelnr.
DATASET ACTIVATE inwonendeeigenaars.
sort cases art_deelnr (a).
MATCH FILES /FILE=*
  /TABLE='gebouwdelen0'
  /BY art_deelnr.
EXECUTE.
dataset close gebouwdelen0.

FILTER OFF.
USE ALL.
SELECT IF (woningen > 0).
EXECUTE.






* straatnamen, huisnummers en postcodes van eigenaar en perceeldeel klaarzetten.

* links: de eigenaarsgegevens, rechts de eigendomsgegevens.
* opmerking: bij gebruik postzone op basis van statsec ipv postcode_da ging type 2 van 10000 naar 800 gevallen.
compute postcode_links=eig_pc.
compute postcode_rechts=postzone_statsec.

*gaat ervan uit dat beide enkel Antwerpen kunnen zijn.
* je zou ook strenger kunnen zijn: je kan enkel inwonend zijn als pand en adres eigenaar in zelfde postzone liggen. Maar het is courant dat postcodes fout zijn.
if postcode_links=postcode_rechts zelfde_postcode=1.
recode zelfde_postcode (missing=0).


* eig_adres bevat zowel huisnummer als straatnaam.
* dit blok splitst straatnaam van huisnummer voor de eigenaarsgegevens.
* deze methode met dank aan Dorien Dossche van de stad Aalst.

string inveld (a46).
compute inveld=eig_adres.

***  invar=INVELD & outvar=UITSTRAAT   *** DE OUTPUTVAR MAG NOG NIET BESTAAN
***    de variabele INVELD  bevat de string die de straatnaam, huisnr, en index bevat als 1 variabele    
***    de variabele UITSTRAAT zal enkel de straatnaam bevatten 
***    indien de invoer string leeg is (lengte=0) dan zal de uitvoerstring ook leeg zijn       
***    maximum stringlengte van 50, pas aan indien nodig, zie definitie #stempa .
*NUMERIC  #ilusa  (F4.0).
*NUMERIC  #ilengtea (F4.0).
STRING  #schara  (A1).
STRING  #stempa  (A50).
STRING UITSTRAAT (A40).
STRING #stempc (A5).
COMPUTE  #ilengtein = LENGHT(RTRIM(inveld)).
COMPUTE  #stempa = ''.
COMPUTE #eerst = 1.
COMPUTE #huisnr = 0.
COMPUTE #einde=0.
COMPUTE #stempc = ''.

LOOP  #ilusa  =1  TO  #ilengtein  BY  1 IF (#huisnr = 0).
   COMPUTE  #schara = CHAR.SUBSTR(LOWER(INVELD),#ilusa,1).
* VERIFIEER EERST OP VOORLOOPCIJFERS (vb 1 meistraat, 3 sleutelsstraat, etc.).
DO IF #eerst =1.
     DO IF CHAR.INDEX('0123456789',#schara) > 0.
     COMPUTE  #stempa  =  CONCAT(RTRIM(#stempa),#schara).
     ELSE.
     COMPUTE #eerst = 0.
     END IF.
END IF.
* HIER BEGINT DE ALFABETISCHE STRAATNAAM.
DO IF #eerst =0.
      DO IF CHAR.INDEX('0123456789',#schara) EQ 0.
           DO IF #schara NE ',' .
           COMPUTE  #stempa  =  CONCAT(RTRIM(#stempa),#schara).
           END IF.
        ELSE.
        COMPUTE #huisnr=1.
      END IF.
END IF.
END LOOP.
COMPUTE  UITSTRAAT  =  (#stempa).

LOOP  #ilusabis =   (#ilusa -1)  TO  #ilengtein  BY  1 IF (#einde = 0).
   COMPUTE  #schara = CHAR.SUBSTR((INVELD),#ilusabis,1).
    DO IF CHAR.INDEX('0123456789',#schara) > 0.
     COMPUTE  #stempc  =  CONCAT(RTRIM(#stempc),#schara).
     ELSE.
     COMPUTE #einde = 1.
     END IF.
END LOOP.
COMPUTE  UITHUISNR = NUM(#stempc,f5.0).
string UITHUISNR_string (a50).
COMPUTE  UITHUISNR_string = #stempc.
EXECUTE.
rename variables uitstraat=straatnaam_links.
rename variables uithuisnr=huisnummer_links.
rename variables uithuisnr_string=huisnummer_string_links.


* ook het perceeldeel heeft een adres met straatnaam en huisnummer in een enkel veld.
* dit blok splitst straatnaam van huisnummer voor de eigendomsgegevens.
compute inveld=sl1.

***  invar=INVELD & outvar=UITSTRAAT   *** DE OUTPUTVAR MAG NOG NIET BESTAAN
***    de variabele INVELD  bevat de string die de straatnaam, huisnr, en index bevat als 1 variabele    
***    de variabele UITSTRAAT zal enkel de straatnaam bevatten 
***    indien de invoer string leeg is (lengte=0) dan zal de uitvoerstring ook leeg zijn       
***    maximum stringlengte van 50, pas aan indien nodig, zie definitie #stempa .
*NUMERIC  #ilusa  (F4.0).
*NUMERIC  #ilengtea (F4.0).
STRING  #schara  (A1).
STRING  #stempa  (A50).
STRING UITSTRAAT (A40).
STRING #stempc (A5).
COMPUTE  #ilengtein = LENGHT(RTRIM(INVELD)).
COMPUTE  #stempa = ''.
COMPUTE #eerst = 1.
COMPUTE #huisnr = 0.
COMPUTE #einde=0.
COMPUTE #stempc = ''.

LOOP  #ilusa  =1  TO  #ilengtein  BY  1 IF (#huisnr = 0).
   COMPUTE  #schara = CHAR.SUBSTR(LOWER(INVELD),#ilusa,1).
* VERIFIEER EERST OP VOORLOOPCIJFERS (vb 1 meistraat, 3 sleutelsstraat, etc.).
DO IF #eerst =1.
     DO IF CHAR.INDEX('0123456789',#schara) > 0.
     COMPUTE  #stempa  =  CONCAT(RTRIM(#stempa),#schara).
     ELSE.
     COMPUTE #eerst = 0.
     END IF.
END IF.
* HIER BEGINT DE ALFABETISCHE STRAATNAAM.
DO IF #eerst =0.
      DO IF CHAR.INDEX('0123456789',#schara) EQ 0.
           DO IF #schara NE ',' .
           COMPUTE  #stempa  =  CONCAT(RTRIM(#stempa),#schara).
           END IF.
        ELSE.
        COMPUTE #huisnr=1.
      END IF.
END IF.
END LOOP.
COMPUTE  UITSTRAAT  =  (#stempa).

LOOP  #ilusabis =   (#ilusa -1)  TO  #ilengtein  BY  1 IF (#einde = 0).
   COMPUTE  #schara = CHAR.SUBSTR((INVELD),#ilusabis,1).
    DO IF CHAR.INDEX('0123456789',#schara) > 0.
     COMPUTE  #stempc  =  CONCAT(RTRIM(#stempc),#schara).
     ELSE.
     COMPUTE #einde = 1.
     END IF.
END LOOP.
COMPUTE  UITHUISNR = NUM(#stempc,f5.0).
string UITHUISNR_string (a50).
COMPUTE  UITHUISNR_string = #stempc.
EXECUTE.
rename variables uitstraat=straatnaam_rechts.
rename variables uithuisnr=huisnummer_rechts.
rename variables uithuisnr_string=huisnummer_string_rechts.
delete variables inveld.



* op zoek naar ongeveer dezelfde straatnaam.

* je kan dit proces best goed bestuderen, met andere data komen hier mogelijk vreemde resultaten uit.
* hierbij werd gekeken welke straatnaamcombinaties vaak voorkomen, om zo veel voorkomende soorten fouten op te sporen.
* sommige types correcties kunnen in een andere context meer problemen veroorzaken dan ze oplossen.
* of sommige soorten fouten kunnen in Antwerpen heel zeldzaam zijn, maar ergens anders veel voorkomen.

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

* verwijderen +.
string straatnaam_links_verkort (a100).
string straatnaam_rechts_verkort (a100).
compute straatnaam_links_verkort=REPLACE(straatnaam_links,"+","").
compute straatnaam_rechts_verkort=REPLACE(straatnaam_rechts,"+","").

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
if CHAR.INDEX(eig_adres,"/")>0 huisnummer_links_naslash=char.substr(eig_adres,CHAR.INDEX(eig_adres,"/")+1).
string huisnummer_rechts_naslash (a50).
if CHAR.INDEX(sl1,"/")>0 huisnummer_rechts_naslash=char.substr(sl1,CHAR.INDEX(sl1,"/")+1).
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
daa
Art_deelnr
capakey
sl1
persoonscode
Eig_adres
Eig_code
eigenaar_volgnummer
eig_deel
antwerpenaar
natuurlijk_rechtspersoon
zelfde_postcode
zelfde_straatnaam
zelfde_huisnummer
woningen.

sort cases Art_deelnr (a).
rename variables Art_deelnr=aav.
alter type aav (a15).





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

sort cases persoonscode (a) kwalimatch(a).
if $casenum=1 volgnummer=1.
if lag(persoonscode)~=persoonscode volgnummer=1.
if lag(persoonscode)=persoonscode volgnummer=lag(volgnummer)+1.

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
/keep=aav eig_code
bewoond_door_eigenaar.
RENAME VARIABLES bewoond_door_eigenaar=inwonende_eigenaar.
sort cases aav (a) eig_code (a).
rename variables aav=art_deelnr.

* voeg de nieuwe variable toe aan het eigenaarsbestand.
DATASET ACTIVATE eigenaars.
sort cases art_deelnr (a) eig_code (a).
MATCH FILES /FILE=*
  /TABLE='inwonendeeigenaars'
  /BY art_deelnr Eig_code.
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



* VERDELING EIGENDOM.
DATASET ACTIVATE eigenaars.


* de variabele eig_deel bevat een verdeelsleutel van het eigendom. Daarnaast bevat het ook informatie over verpachting, blote eigendom of volle eigendom.
* aan de hand van die variabele, kunnen we een verdeling maken van hoeveel bezit er bij wat voor eigenaars zit.
* Om dit te kunnen aggregren naar percelen of hogere niveaus, zullen we die verdeelsleutel toepassen op het Kadastra Inkomen.

* basis opkuis.
STRING  eig_deel1 (A36).
COMPUTE eig_deel1=REPLACE(Eig_deel,"--","-").

* als er direct een getal in zit, kunnen we direct een breuk maken.
* in dat geval is het eerste zinvolle teken van eig_deel een geldig getal.
COMPUTE simpel=number(CHAR.SUBSTR(eig_deel1,2,1),f1.0).
* en dan is de teller van de breuk het deel voor de slash.
if simpel>0 teller=number(char.substr(eig_deel1,2,CHAR.INDEX(eig_deel1,"/")-2),f10.0).
* en de noemer het deel na de slash.
string noemer0 (a10).
if simpel>0 noemer0=char.substr(eig_deel1,CHAR.INDEX(eig_deel1,"/")+1).
if simpel>0 noemer=number(noemer0,f12.0).
if simpel>0 & missing(noemer) noemer=number(char.substr(noemer0,1,CHAR.INDEX(noemer0,"- /",1)-1),f12.0).

* oppikken waar we de breuk voor de verschillende soorten eigenaars zouden kunnen terugvinden.
compute verpachter = CHAR.INDEX(eig_deel1,"VERP",4).
compute blote_eigenaar = CHAR.INDEX(eig_deel1,"BE ",3).
compute volle_eigendom = CHAR.INDEX(eig_deel1,"VE ",3).
compute eigenaar_grond = CHAR.INDEX(eig_deel1,"-EIG.GROND ").

* verpachter.
* we gaan op zoek vanaf 5 tekens na VERP, daar staat mogelijk een breuk.
string teller_verp0 (a50).
if verpachter>0 teller_verp0=char.substr(eig_deel1,verpachter+5).
compute teller_verp=number(CHAR.SUBSTR(teller_verp0,1,CHAR.INDEX(teller_verp0,"/")-1),f12.0).
string noemer_verp0 (a50).
if verpachter>0 noemer_verp0=char.substr(teller_verp0,CHAR.INDEX(teller_verp0,"/")+1).
if verpachter>0 noemer_verp=number(noemer_verp0,f12.0).
if verpachter>0 & missing(noemer_verp) noemer_verp=number(char.substr(noemer_verp0,1,CHAR.INDEX(noemer_verp0,"- /",1)-1),f12.0).

* blote eigenaar.
string teller_bloot0 (a50).
if blote_eigenaar>0 teller_bloot0=char.substr(eig_deel1,blote_eigenaar+3).
compute teller_bloot=number(CHAR.SUBSTR(teller_bloot0,1,CHAR.INDEX(teller_bloot0,"/")-1),f12.0).
string noemer_bloot0 (a50).
if blote_eigenaar>0 noemer_bloot0=char.substr(teller_bloot0,CHAR.INDEX(teller_bloot0,"/")+1).
if blote_eigenaar>0 noemer_bloot=number(noemer_bloot0,f12.0).
if blote_eigenaar>0 & missing(noemer_bloot) noemer_bloot=number(char.substr(noemer_bloot0,1,CHAR.INDEX(noemer_bloot0,"- /",1)-1),f12.0).

* volle eigendom.
string teller_vol0 (a50).
if volle_eigendom>0 teller_vol0=char.substr(eig_deel1,volle_eigendom+3).
compute teller_vol=number(CHAR.SUBSTR(teller_vol0,1,CHAR.INDEX(teller_vol0,"/")-1),f12.0).
string noemer_vol0 (a50).
if volle_eigendom>0 noemer_vol0=char.substr(teller_vol0,CHAR.INDEX(teller_vol0,"/")+1).
if volle_eigendom>0 noemer_vol=number(noemer_vol0,f12.0).
if volle_eigendom>0 & missing(noemer_vol) noemer_vol=number(char.substr(noemer_vol0,1,CHAR.INDEX(noemer_vol0,"- /",1)-1),f12.0).

* eigenaar grond.
* dit gaan we enkel meenemen als de rest van het eigendom niet verdeeld kan worden.
string teller_grond0 (a50).
if eigenaar_grond>0 teller_grond0=char.substr(eig_deel1,eigenaar_grond+11).
compute teller_grond=number(CHAR.SUBSTR(teller_grond0,1,CHAR.INDEX(teller_grond0,"/")-1),f12.0).
if eig_deel1="-EIG.GROND DEEL-" teller_grond=1.
string noemer_grond0 (a50).
if eigenaar_grond>0 noemer_grond0=char.substr(teller_grond0,CHAR.INDEX(teller_grond0,"/")+1).
if eigenaar_grond>0 noemer_grond=number(noemer_grond0,f12.0).
if eigenaar_grond>0 & missing(noemer_grond) noemer_grond=number(char.substr(noemer_grond0,1,CHAR.INDEX(noemer_grond0,"- /",1)-1),f12.0).
if eig_deel1="-EIG.GROND DEEL-" noemer_grond=1.


recode teller
teller_verp
teller_bloot
teller_vol 
teller_grond (sysmis=0).
recode 
noemer
noemer_verp
noemer_bloot
noemer_vol 
noemer_grond (sysmis=1).
compute breuk=teller/noemer.
compute breuk_verp=teller_verp/noemer_verp.
compute breuk_bloot=teller_bloot/noemer_bloot.
compute breuk_vol=teller_vol/noemer_vol.
compute breuk_grond=teller_grond/noemer_grond.
* we nemen enkel verpachters mee, niet pachters (of erfpacht, ERFP). Daarom kunnen we dit allemaal optellen. We beschouwen pachten hier dus niet als "echt" eigenaarsschap.
compute breuk_verdeling=breuk+breuk_verp+breuk_bloot+breuk_vol.
execute.
delete variables teller_verp0 noemer_verp0.
delete variables teller_bloot0 noemer_bloot0.
delete variables teller_vol0 noemer_vol0.
delete variables noemer0 simpel verpachter blote_eigenaar volle_eigendom.

* in het geval er niets of bijna niets is ingevuld, gaan we ervan uit dat dit het volledig eigenaarsschap bedoelt.
if Eig_deel="-BE-" breuk_verdeling=1.
if Eig_deel="" breuk_verdeling=1.


AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=Art_deelnr
  /breuk_verdeling_sum=SUM(breuk_verdeling) 
  /breuk_verdeling_numiss=NUMISS(breuk_verdeling)
  /totaal_rijen=N.

* beslissen wat te doen met speciale verdeelsleutels.
* dit doen we enkel als de rest niets oplevert.
do if breuk_verdeling_sum<0.01.
if Eig_deel='-GEBOUW-' breuk_verdeling=1.
if Eig_deel='-OPSTAL-' breuk_verdeling=0.
if Eig_deel='-EIG.GROND-' breuk_verdeling=1.
if Eig_deel='-ERFP-' breuk_verdeling=0.
if Eig_deel='-VERP-' breuk_verdeling=1.
if Eig_deel='-GROND-' breuk_verdeling=1.
if Eig_deel='-VG-' breuk_verdeling=0.
if Eig_deel='-BE-' breuk_verdeling=1.
if char.index(Eig_deel,'-GEBOUW ')>0 breuk_verdeling=1.
if char.index(Eig_deel,'-VG ')>0  breuk_verdeling=0.
if char.index(Eig_deel,'BE-')>0  breuk_verdeling=1.
if char.index(Eig_deel,'-BE')>0  breuk_verdeling=1.
if Eig_deel='-DEEL-' breuk_verdeling=1.
if Eig_deel='-GROND DEEL-' breuk_verdeling=1.
if missing(breuk_verdeling) breuk_verdeling=0.
end if.


freq breuk_verdeling_sum.
* dit kan je gebruiken om exotische gevallen te identificeren.
* met name sommen groter dan één, sommen gelijk aan nul, perceeldelen zonder geldige waarden.

* als we nog steeds niets hebben, dan gebruiken we eigenaarschap van de grond.
DELETE VARIABLES breuk_verdeling_sum
breuk_verdeling_numiss
totaal_rijen.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=Art_deelnr
  /breuk_verdeling_sum=SUM(breuk_verdeling) 
  /breuk_verdeling_numiss=NUMISS(breuk_verdeling)
  /totaal_rijen=N.
if breuk_verdeling_sum < 0.01 breuk_verdeling=breuk_grond.
EXECUTE.

* wat nu nog overblijft analyseren we niet verder.
* we verdelen dit eigendom gewoon over iedereen die in het eigenaarsbestand zit.
DELETE VARIABLES breuk_verdeling_sum
breuk_verdeling_numiss
totaal_rijen.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=Art_deelnr
  /breuk_verdeling_sum=SUM(breuk_verdeling) 
  /breuk_verdeling_numiss=NUMISS(breuk_verdeling)
  /totaal_rijen=N.
if breuk_verdeling_sum < 0.01 breuk_verdeling=1/totaal_rijen.

* te grote waarden corrigeren we hier
* normaal gezien is breuk_verdeling_sum altijd = 1 dus dan doet dit niets.
* waar het groter is, herleidt het de breuk verdeling waarden zo dat de som toch 1 wordt.
if breuk_verdeling_sum >= 0.01 breuk_verdeling=breuk_verdeling/breuk_verdeling_sum.

EXECUTE.
DELETE VARIABLES breuk_verdeling_sum
breuk_verdeling_numiss
totaal_rijen.

delete variables teller
noemer
eigenaar_grond
teller_verp
noemer_verp
teller_bloot
noemer_bloot
teller_vol
noemer_vol
teller_grond0
teller_grond
noemer_grond0
noemer_grond
breuk
breuk_verp
breuk_bloot
breuk_vol
breuk_grond.

* we voegen het kadastraal inkomen (KI) toe op basis van de prc tabel.
dataset activate prc.
dataset copy ki.
dataset activate ki.
match files
/file=*
/keep=art_deelnr ki_belastbaar ki_onbelastbaar.
sort cases art_deelnr (a).

DATASET ACTIVATE eigenaars.
sort cases art_deelnr (a).
MATCH FILES /FILE=*
  /TABLE='ki'
  /BY art_deelnr.
EXECUTE.

dataset close ki.


* verdeling KI.
compute KI_belastbaar_deel=KI_belastbaar*breuk_verdeling.
compute KI_onbelastbaar_deel=KI_onbelastbaar*breuk_verdeling.
* opmerking: totaal KI staat nu nog merdere keren in het bestand, let op dat je dit niet meerdere keren gaat tellen per perceeldeel.


SAVE OUTFILE='' + werkbestanden + 'eigenaars_gebouwdeel_verwerkt.sav'
  /COMPRESSED.
