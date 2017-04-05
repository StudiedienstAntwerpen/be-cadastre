* Encoding: windows-1252.

* inhoudelijke wijzigingen:
- verdiepen werden bouwlagen
- minder perceeldelen dan verwacht, mogelijk met effect op KI
- sleutelveld propertySituationIdf + order is niet steeds uniek in gebouwdelenbestand.


SET Unicode=No Locale=nl_BE.

* locatie hoofdmap.
DEFINE basismap () 'C:\Users\sa59772\Desktop\kadasterlokaal\kadaster2016\' !ENDDEFINE.
DEFINE werkmap () 'C:\Users\sa59772\Desktop\kadasterlokaal\kadaster2016\werkbestanden\' !ENDDEFINE.


* perceeldelen ophalen.

* indien nog open staat.
dataset activate parcel.
* indien al afgesloten.
GET
  FILE=
    '' + basismap + '\legger\basisbestand_parcel.sav'.
DATASET NAME prc WINDOW=FRONT.


value labels numberCadastralIncome	
1 'Gewoon ongebouwd onroerend goed'	
2 'Gewoon gebouwd onroerend goed'	
3 'Ongebouwde nijverheidsgrond (of eventueel handel met outillage)'	
4 'Nijverheidsgebouw (of eventueel ambacht of handel met outillage)'	
5 'Op een ongebouwd perceel geplaatst materieel en outillage'	
6 'Op een gebouwd perceel geplaatst materieel en outillage'.

RECODE charCadastralIncome	
('F'=1)
('G'=2)
('H'=3)
('J'=4)
('K'=5)
('L'=6)
('P'=7)
('Q'=8)
('X'=9) into charCadastralIncome_num.
value labels charCadastralIncome_num
1 'Belastbaar kadastraal inkomen'
2 'Kadastraal inkomen vrijgesteld van de onroerende voorheffing op grond van art 253,2° of 3°, van het W.I.B. 92 of van bijzondere wetten'
3 'Kadastraal inkomen vrijgesteld van de onroerende voorheffing op grond van art 253,1° van het W.I.B. 92 of voorlopig vrijgesteld gedeelte van een in aanbouw genomen onbebouwde grond'
4 'Niet-vastgesteld kadastraal inkomen of vastgesteld kadastraal inkomen, maar niet belastbaar wegens niet-ingebruikneming of niet-verhuring'
5 'Voorlopig kadastraal inkomen: ingebruikneming of verhuring voor de volledige voltooiing'
6 'Gedeeltelijk voorlopig kadastraal inkomen van een appartementsgebouw waarvan niet al de appartementen zijn in gebruik genomen of verhuurd'
7 'Kadastraal inkomen van een in aanbouw genomen onbebouwde grond of van een nieuwbeboste grond, belast zonder rekening te houden met de nieuwe aard krachtens art 494,§3 van het W.I.B. 92'
8 'Kadastraal inkomen van een gebouw of van materieel en outillage dat vrijstelling geniet van de onroerende voorheffing voor economische doeleinden. Zal belastbaar worden vanaf de aangeduide datum.'
9 'Kadastraal inkomen vrijgesteld van de onroerende voorheffing overeenkomstig een bijzondere bepaling van één van de drie Gewesten (zie ook tabel decrete)'.






* sleutelveld is niet uniek!
* in Antwerpen: negen gevallen waar de combinatie propertySituationIdf order nog altijd niet uniek is.
* wegens lage aantal, deleten we deze. We sorteren eerst op constructionIndication zodat we de record met het meeste info overhouden.
* ongeveer 1400 propertySituationIdf bestaan dan nog steeds uit meerdere order nummers. Dit is mogelijk volgens het datamodel.

* Identify Duplicate Cases.
SORT CASES BY propertySituationIdf(A) order(A) constructionIndication(A).
MATCH FILES
  /FILE=*
  /BY propertySituationIdf order
  /LAST=PrimaryLast.
VARIABLE LABELS  PrimaryLast 'Indicator of each last matching case as Primary'.
VALUE LABELS  PrimaryLast 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryLast (ORDINAL).
EXECUTE.

frequencies PrimaryLast.

FILTER OFF.
USE ALL.
SELECT IF (PrimaryLast = 1).
EXECUTE.

delete variables primarylast.



* zie de syntax checken_capakey_da.sps om te helpen deze conversietabel te maken.
* dit is een ruwe benadering van een postcode; deze conversie is enkel van toepassing voor Antwerpen en niet noodzakelijk voor verdere verwerking.
Recode divCad
(11002=2000) (11003=2600) (11006=2140) (11012=2100)
(11014=2180) (11019=2660) (11028=2170) (11051=2610)
(11302=2600) (11303=2600) (11312=2140) (11313=2140)
(11342=2100) (11343=2100) (11344=2100) (11345=2100)
(11346=2100) (11363=2180) (11364=2180) (11382=2660)
(11383=2660) (11422=2170) (11423=2170) (11462=2610)
(11463=2610) (11802=2020) (11803=2000) (11804=2000)
(11805=2060) (11806=2060) (11807=2060) (11808=2018)
(11809=2020) (11810=2018) (11811=2000) (11812=2018)
(11813=2050) (11814=2030) (11815=2030) (11816=2030)
(11817=2030) (11818=2040) (11819=2040) (11820=2040)
(else=0)
INTO postcode_da.
alter type postcode_da (f4.0).


* gebiedsindeling ophalen (zie 00_toekennen_perceel_sector.sps).
* statsec= statistische sector.
* wijkcode= eigen clustering van sectoren, met enkele uitzonderingen waar grenzen niet samenvallen.

GET
  FILE=
    '' + basismap + 'werkbestanden\sectoren_toekennen.sav'.
DATASET NAME statsec WINDOW=FRONT.
alter type capakey (a17).
alter type statsec (a4).
alter type WijkCode (a5).
sort cases capakey (a).

* gebiedsindeling koppelen aan perceeldelen.
dataset activate prc.
sort cases capakey (a).
MATCH FILES /FILE=*
  /TABLE='statsec'
  /BY capakey.
EXECUTE.

* checken op ontbrekende gevallen.
* in principe zou je voor elk perceel een geometrie moeten hebben.
DATASET DECLARE test.
AGGREGATE
  /OUTFILE='test'
  /BREAK=capakey statsec WijkCode
  /N_BREAK=N.
dataset activate test.
frequencies statsec.

dataset activate prc.
dataset close test.
dataset close statsec.

* statistische sectoren kunnen redelijk goed naar postcodes omgezet worden in Antwerpen.
* dit is iets zuiverder dan postcode_da, maar postcodes zijn te grillig om exact te bereiken op deze manier.
* voor het proces hier is dit niet essentieel.
recode statsec
("C21-"=2060) ("R19-"=2100) ("P12-"=2180) ("U10-"=2610) ("Q11-"=2170) ("J881"=2030)
("C22-"=2060) ("R39-"=2100) ("P392"=2180) ("U11-"=2610) ("Q12-"=2170) ("J901"=2030)
("C23-"=2060) ("R101"=2100) ("T20-"=2600) ("E551"=2018) ("Q13-"=2170) ("J912"=2030)
("C41-"=2060) ("R12-"=2100) ("T21-"=2600) ("G51-"=2018) ("T10-"=2600) ("J923"=2030)
("H40-"=2060) ("R13-"=2100) ("T22-"=2600) ("G53-"=2018) ("T111"=2600) ("J932"=2030)
("H43-"=2060) ("R172"=2100) ("T23-"=2600) ("G54-"=2018) ("T12-"=2600) ("J94-"=2030)
("J072"=2000) ("R05-"=2100) ("T24-"=2600) ("G552"=2018) ("T13-"=2600) ("A04-"=2000)
("J83-"=2000) ("R180"=2100) ("T25-"=2600) ("G59-"=2018) ("T14-"=2600) ("A05-"=2000)
("S10-"=2140) ("R20-"=2100) ("D31-"=2018) ("F11-"=2020) ("T180"=2600) ("A10-"=2000)
("S11-"=2140) ("R21-"=2100) ("D34-"=2018) ("F12-"=2020) ("T19-"=2600) ("A12-"=2000)
("S12-"=2140) ("R22-"=2100) ("D35-"=2018) ("F60-"=2020) ("T412"=2600) ("A14-"=2000)
("S13-"=2140) ("R23-"=2100) ("D38-"=2018) ("F61-"=2020) ("T42-"=2600) ("A21-"=2000)
("S19-"=2140) ("R24-"=2100) ("D41-"=2018) ("F62-"=2020) ("Q03-"=2170) ("A22-"=2000)
("S28-"=2140) ("R28-"=2100) ("D42-"=2018) ("F64-"=2020) ("Q04-"=2170) ("E15-"=2000)
("S2MJ"=2140) ("R29-"=2100) ("K171"=2030) ("F65-"=2020) ("U30-"=2610) ("A00-"=2000)
("S41-"=2140) ("R30-"=2100) ("K172"=2030) ("U03-"=2610) ("U31-"=2610) ("A01-"=2000)
("S42-"=2140) ("R31-"=2100) ("K173"=2030) ("U40-"=2610) ("U32-"=2610) ("A02-"=2000)
("S43-"=2140) ("R32-"=2100) ("K174"=2030) ("U41-"=2610) ("U33-"=2610) ("A03-"=2000)
("S00-"=2140) ("R33-"=2100) ("K175"=2030) ("U43-"=2610) ("T00-"=2600) ("A081"=2000)
("S01-"=2140) ("R34-"=2100) ("K1MN"=2030) ("U47-"=2610) ("T01-"=2600) ("A11-"=2000)
("S02-"=2140) ("R35-"=2100) ("K271"=2040) ("U57-"=2610) ("T02-"=2600) ("A13-"=2000)
("S03-"=2140) ("R401"=2100) ("K272"=2040) ("U5MA"=2610) ("T03-"=2600) ("A15-"=2000)
("S04-"=2140) ("R41-"=2100) ("K2MN"=2040) ("U5PA"=2610) ("T04-"=2600) ("C42-"=2060)
("S05-"=2140) ("R42-"=2100) ("L070"=2040) ("U60-"=2610) ("T05-"=2600) ("C43-"=2060)
("S20-"=2140) ("R43-"=2100) ("L070"=2040) ("U68-"=2610) ("T09-"=2600) ("C44-"=2060)
("S30-"=2140) ("R44-"=2100) ("L17-"=2040) ("U69-"=2610) ("T30-"=2600) ("C45-"=2060)
("S31-"=2140) ("R47-"=2100) ("V00-"=2660) ("Q201"=2170) ("T39-"=2600) ("C491"=2060)
("E50-"=2018) ("R482"=2100) ("V01-"=2660) ("Q212"=2170) ("Q001"=2170) ("H41-"=2060)
("E521"=2018) ("C20-"=2018) ("V02-"=2660) ("Q222"=2170) ("Q012"=2170) ("H44-"=2060)
("E53-"=2018) ("C24-"=2018) ("V03-"=2660) ("Q2AA"=2170) ("Q021"=2170) ("F21-"=2020)
("G522"=2018) ("C25-"=2018) ("V04-"=2660) ("P33-"=2180) ("Q052"=2170) ("F223"=2020)
("U00-"=2610) ("C28-"=2018) ("V13-"=2660) ("P500"=2180) ("Q072"=2170) ("G72-"=2020)
("U01-"=2610) ("C29-"=2018) ("V20-"=2660) ("P589"=2180) ("Q091"=2170) ("G73-"=2020)
("U02-"=2610) ("C31-"=2018) ("V05-"=2660) ("P590"=2180) ("Q17-"=2170) ("G74-"=2020)
("U09-"=2610) ("D30-"=2018) ("V10-"=2660) ("P590"=2180) ("Q241"=2170) ("G75-"=2020)
("H4MJ"=2060) ("D32-"=2018) ("V11-"=2660) ("K214"=2040) ("Q242"=2170) ("G780"=2020)
("H83-"=2060) ("D33-"=2018) ("V12-"=2660) ("B701"=2050) ("Q49-"=2170) ("Q14-"=2170)
("H84-"=2060) ("P05-"=2180) ("V14-"=2660) ("B71-"=2050) ("E5MJ"=2000) ("Q233"=2170)
("H8MJ"=2060) ("P20-"=2180) ("V07-"=2660) ("B721"=2050) ("F6NJ"=2020) ("Q2PA"=2170)
("J820"=2000) ("P21-"=2180) ("V099"=2660) ("B73-"=2050) ("F6MJ"=2020) ("Q30-"=2170)
("J84-"=2000) ("P22-"=2180) ("V301"=2660) ("B742"=2050) ("L000"=2040) ("Q39-"=2170)
("J85-"=2000) ("P23-"=2180) ("V312"=2660) ("B752"=2050) ("L011"=2040) ("U20-"=2610)
("J873"=2000) ("P242"=2180) ("V322"=2660) ("B782"=2050) ("L022"=2040) ("U21-"=2610)
("R00-"=2100) ("P291"=2180) ("V373"=2660) ("B791"=2050) ("L090"=2040) ("U22-"=2610)
("R01-"=2100) ("P00-"=2180) ("V391"=2660) ("B813"=2050) ("L100"=2040) ("E122"=2000)
("R02-"=2100) ("P01-"=2180) ("V19-"=2660) ("B824"=2050) ("L111"=2040) ("E131"=2000)
("R03-"=2100) ("P02-"=2180) ("V21-"=2660) ("P100"=2180) ("L122"=2040) ("E14-"=2000)
("R04-"=2100) ("P03-"=2180) ("V22-"=2660) ("P111"=2180) ("L18-"=2040) ("E19-"=2000)
("R099"=2100) ("P04-"=2180) ("V23-"=2660) ("P192"=2180) ("J80-"=2030) 
("R110"=2100) ("P09-"=2180) ("V29-"=2660) ("Q10-"=2170) ("J81-"=2030) 
INTO postzone_statsec.
execute.

value labels postzone_statsec
2000 'Antwerpen centrum'
2018 'Antwerpen Zuid'
2020 'Antwerpen Kiel'
2030 'Haven'
2040 'Bezali'
2050 'Antwerpen Linkeroever'
2060 'Antwerpen Noord'
2100 'Deurne'
2140 'Borgerhout'
2170 'Merksem'
2180 'Ekeren'
2600 'Berchem'
2610 'Wilrijk'
2660 'Hoboken'.

SAVE OUTFILE='' + werkmap + '\basisbestand_gebouwdelen.sav'
  /COMPRESSED.




* OPPERVLAKTE IN GIS OPHALEN.

* opmerking: de naam van dit bestand kan varieren van jaar tot jaar.
GET TRANSLATE
  FILE=
    '' + basismap +
    '\geometrie\Adp11002.dbf'
  /TYPE=DBF /MAP .
DATASET NAME gis WINDOW=FRONT.
match files
/file=*
/keep=capakey oppervl.
sort cases capakey (a).
rename variables oppervl=oppervlakte_perceel_gis.
alter type capakey (a17).
dataset activate prc.
sort cases capakey (a).
MATCH FILES /FILE=*
  /TABLE='gis'
  /BY capakey.
EXECUTE.

dataset close gis.



* EINDE KOPPELINGEN.



********************************


* BASISVERWERKING PERCEELDELEN.


* juridische oppervlakte.

recode surfaceNotTaxable
surfaceTaxable (missing=0).
compute juridische_oppervlakte=surfaceNotTaxable+surfaceTaxable.
compute juridische_oppervlakte_belastbaar=surfaceTaxable.
compute juridische_oppervlakte_onbelastbaar=surfaceNotTaxable.


AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES OVERWRITEVARS=YES
  /BREAK=capakey
  /juridische_oppervlakte_perceel=MAX(juridische_oppervlakte)
  /jur_opp_belastbaar_perceel=MAX(juridische_oppervlakte_belastbaar)
  /jur_opp_onbelastbaar_perceel=MAX(juridische_oppervlakte_onbelastbaar).
DELETE VARIABLES juridische_oppervlakte juridische_oppervlakte_belastbaar juridische_oppervlakte_onbelastbaar.



*variable labels CC_01 'Classificatiecode'.
*variable labels CC_02 'Type van constructie'.
*variable labels CC_03 'Aantal verdiepingen'.
*variable labels CC_04 'Bewoonbare dakverdieping'.
*variable labels CC_05 'Jaar beeindiging opbouw'.
*variable labels CC_06 'jaar laatste fysische wijziging'.
*variable labels CC_07 'kwaliteit van de constructie'.
*variable labels CC_08 'aantal garages, parkings en/of overdekte standplaatsen'.
*variable labels CC_09 'centrale verwarming'.
*variable labels CC_10 'aantal badkamers'.
*variable labels CC_11 'aantal zelfstannisdige woongelegenheden'.
*variable labels CC_12 'aantal woonplaatsen'.
*variable labels CC_13 'bebouwde grond oppervlakte'.
*variable labels CC_14 'Nuttige oppervlakte'.


* CLASSIFICATIE SOORT PERCEEL.
* dit is een eigen eenvoudige classificatie.
* de basis-info is per perceeldeel. We gaan hier ook het perceeldeel in de context van zijn perceel bekijken, om complex gebruik in kaart te krijgen. 
* heel de module produceert enkel classificatie_eenvoudig, perceel_gebruik en app_lift. Al de andere variabelen zijn tussenvariabelen die achteraf gewist worden.
* de resulterende variabele is nagenoeg altijd inherent uniek op niveau van het perceel, enkel komt het vaak voor dat een deel van het gebruik onbekend is.

recode constructionIndication (else=copy) into 
 classificatiecode .
value labels classificatiecode
10 'Huis in een tuinwijk'
20 'Gekarakteriseerde hoeve'
30 'Villa'
31 'Bungalow'
32 'Fermette'
33 'Vakantieverblijf'
40 'Huis zonder bewoonbare kelder'
41 'Huis bel-etage'
50 'Huis met bewoonbare kelder'
60 'Huis met koetspoort als enige ingang'
70 'Huis met koetspoort en particuliere ingang'
80 'Huis zonder woonplaatsen op het gelijkvloers'
100 'appartementsgebouwen zonder lift Toebehorend aan een enkele eigenaar'
101 'appartementsgebouwen zonder lift Wooneenheid'
102 'appartementsgebouwen zonder lift Exploitatie-eenheid (voor beroeps-doeleinden, afzonderlijk gekadastreerd)'
103 'appartementsgebouwen zonder lift Garage, standplaats, parking, afzonderlijk gekadastreerd'
104 'appartementsgebouwen zonder lift Diverse lokalen (dienstbodenkamer, mansarde, kelder), afzonderlijk gekadastreerd'
105 'appartementsgebouwen zonder lift Huis#'
110 'appartementsgebouwen met lift Toebehorend aan een enkele eigenaar'
111 'appartementsgebouwen met lift Wooneenheid'
112 'appartementsgebouwen met lift Exploitatie-eenheid (voor beroeps-doeleinden, afzonderlijk gekadastreerd)'
113 'appartementsgebouwen met lift Garage, standplaats, parking, afzonderlijk gekadastreerd'
114 'appartementsgebouwen met lift Diverse lokalen (dienstbodenkamer, mansarde, kelder), afzonderlijk gekadastreerd'
200 'huizen met handelsbestemming  Zonder particuliere ingang'
210 'huizen met handelsbestemming  Met particuliere ingang'
220 'huizen met handelsbestemming  Met koetspoort alleen'
230 'huizen met handelsbestemming  Met koetspoort en particuliere ingang'
300 'Ambachten - Kleine ondernemingen - Nijverheid (Produktie van voedingswaren - Kleding en gebruiksartikelen - Bouwmaterialen - Andere produktiesektoren dan V tot VII - Diverse gebouwen en constructies'
305 'Ambachten - Kleine ondernemingen - Nijverheid (Produktie van voedingswaren - Kleding en gebruiksartikelen - Bouwmaterialen - Andere produktiesektoren dan V tot VII - Diverse gebouwen en constructies'
400 'Kantoorgebouwen'
410 'Gebouw bestemd voor handelsdoeinden (zonder woonfucntie)'
420 'Bedrijf uit de HORECA sector'
430 'Gebouw bestemd voor culturele, recreatieve of sportieve activiteiten'
440 'Gebouw bestemd voor sociale hulp of hospitalisatie'
450 'Gebouw bestemd voor het onderwijs'
460 'Gebouw bestemd voor de uitoefening van erediensten, enz'
470 'Kasteel'
480 'Openbaar gebouw of gebouw voor openbaar nut'
500 'Aanhorigheid van een woning (met uitzondering van bij een building behorende garages opgenomen onder de indicien 103 en 113)'
510 'Ambachtelijke- of industriele aanhorigheid'
520 'Aanhorigheid met handelsdoeleinden'
530 'Landbouwaanhorigheid'
531 'Serre behorende bij een landbouw, tuinbouw of wijngaarduitbating'
532 'Serre niet behorende bij een landbouw, tuinbouw of wijngaarduitbating (alleenstaande serre, door liefhebber uitgebate serre)'
540 'Gebouwen met bijzonder karakter'
999 '???'.
variable level classificatiecode (NOMINAL).

* maak een eenvoudige classificatie.
recode classificatiecode (10=1) (20=1) (30=1)
(31=1) (32=1) (33=1) (40=1) (41=1)
(50=1) (60=1) (70=1) (80=1)
(105=1) (100=2) (101=2) (110=2)
(111=2) (103=3) (104=3) (113=3)
(114=3) (102=4) (112=4) (200=5)
(210=5) (220=5) (230=5) (300=6)
(305=6) (410=5) (400=7) (420=8)
(430=9) (440=10) (450=11) (460=12)
(470=9) (540=9) (480=13) (500=14)
(510=14) (520=14) (530=14) (531=14)
(532=14) (999=15) (missing=16) into classificatie_eenvoudig.
VALUE LABELS classificatie_eenvoudig
1 'huizen'
2 'appartementen'
3 'aanhorigheden appartementen'
4 'handelseenheden'
5 'handelshuizen'
6 'industrieel pand'
7 'kantoor'
8 'horeca'
9 'cultuur en sport'
10 'gezondheid en sociaal'
11 'onderwijs'
12 'religie'
13 'overheid'
14 'andere aanhorigheid'
15 'anders/onbekend'
16 'geen classificatiecode'.


* dummy van gebruik.
if classificatiecode=10 huis=1.
if classificatiecode=20 huis=1.
if classificatiecode=30 huis=1.
if classificatiecode=31 huis=1.
if classificatiecode=33 huis=1.
if classificatiecode=40 huis=1.
if classificatiecode=41 huis=1.
if classificatiecode=50 huis=1.
if classificatiecode=60 huis=1.
if classificatiecode=70 huis=1.
if classificatiecode=80 huis=1.
if classificatiecode=105 huis=1.
if classificatiecode=100 appartement0=1.
if classificatiecode=101 appartement0=1.
if classificatiecode=110 appartement0=1.
if classificatiecode=111 appartement0=1.
if classificatiecode=103 aanhorigheid_appartement0=1.
if classificatiecode=104 aanhorigheid_appartement0=1.
if classificatiecode=113 aanhorigheid_appartement0=1.
if classificatiecode=114 aanhorigheid_appartement0=1.
if classificatiecode=102 handelseenheid0=1.
if classificatiecode=112 handelseenheid0=1.
if classificatiecode=200 handelshuis=1.
if classificatiecode=210 handelshuis=1.
if classificatiecode=220 handelshuis=1.
if classificatiecode=230 handelshuis=1.
if classificatiecode=300 industrieel_pand=1.
if classificatiecode=305 industrieel_pand=1.
if classificatiecode=410 handelshuis=1.
if classificatiecode=400 kantoor=1.
if classificatiecode=420 horeca=1.
if classificatiecode=430 cultuur_sport=1.
if classificatiecode=440 gezondheid_sociaal=1.
if classificatiecode=450 onderwijs=1.
if classificatiecode=460 religie=1.
if classificatiecode=470 cultuur_sport=1.
if classificatiecode=540 cultuur_sport=1.
if classificatiecode=480 overheid=1.
if classificatiecode=500 aanhorigheid_andere=1.
if classificatiecode=510 aanhorigheid_andere=1.
if classificatiecode=520 aanhorigheid_andere=1.
if classificatiecode=530 aanhorigheid_andere=1.
if classificatiecode=531 aanhorigheid_andere=1.
if classificatiecode=532 aanhorigheid_andere=1.
if classificatiecode=999 | missing(classificatiecode) onbekend0=1.
if classificatiecode=32 huis=1.

* drie soorten appartementen aanmaken.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /appartement0_max=max(appartement0) 
  /handelseenheid0_max=max(handelseenheid0).

recode appartement0_max
handelseenheid0_max (missing=0).

if appartement0_max=1 & handelseenheid0_max =0 woonappartement=1.
if appartement0_max=0 & handelseenheid0_max =1 handelsappartement=1.
if appartement0_max=1 & handelseenheid0_max =1 woonhandelsappartement=1.



AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /huis_max=MAX(huis) 
  /handelshuis_max=MAX(handelshuis) 
  /industrieel_pand_max=MAX(industrieel_pand) 
  /kantoor_max=MAX(kantoor) 
  /horeca_max=MAX(horeca) 
  /cultuur_sport_max=MAX(cultuur_sport) 
  /gezondheid_sociaal_max=MAX(gezondheid_sociaal) 
  /onderwijs_max=MAX(onderwijs) 
  /religie_max=MAX(religie) 
  /overheid_max=MAX(overheid) 
  /aanhorigheid_andere_max=MAX(aanhorigheid_andere) 
  /onbekend0_max=MAX(onbekend0).


if woonappartement=1 perceel_gebruik=2.
if handelsappartement=1 perceel_gebruik=3.
if woonhandelsappartement=1 perceel_gebruik=4.
if huis_max=1 perceel_gebruik=1.
if handelshuis_max=1 perceel_gebruik=5.
if industrieel_pand_max=1 perceel_gebruik=6.
if kantoor_max=1 perceel_gebruik=7.
if horeca_max=1 perceel_gebruik=8.
if cultuur_sport_max=1 perceel_gebruik=9.
if gezondheid_sociaal_max=1 perceel_gebruik=10.
if onderwijs_max=1 perceel_gebruik=11.
if religie_max=1 perceel_gebruik=12.
if overheid_max=1 perceel_gebruik=13.
if missing(perceel_gebruik) perceel_gebruik=14.

* er zijn maar twee geldige percelen met meer dan een gebruik, op deze manier gemeten.
* er zijn er wel veel met een bekend en een onbekend gebruik.

value labels perceel_gebruik
1 'huis'
2 'woonappartement'
3 'handelsappartement'
4 'woonhandelappartement'
5 'handelshuis'
6 'industrieel pand'
7 'kantoor'
8 'horeca'
9 'cultuur sport'
10 'gezondheid sociaal'
11 'onderwijs'
12 'religie'
13 'overheid'
14 'onbekend'.

EXECUTE.
delete variables huis
appartement0
aanhorigheid_appartement0
handelseenheid0
handelshuis
industrieel_pand
kantoor
horeca
cultuur_sport
gezondheid_sociaal
onderwijs
religie
overheid
aanhorigheid_andere
onbekend0
appartement0_max
handelseenheid0_max
woonappartement
handelsappartement
woonhandelsappartement
huis_max
handelshuis_max
industrieel_pand_max
kantoor_max
horeca_max
cultuur_sport_max
gezondheid_sociaal_max
onderwijs_max
religie_max
overheid_max
aanhorigheid_andere_max
onbekend0_max.


* wat heeft een lift en wat niet.
recode classificatiecode
(100=0)
(101=0)
(102=0)
(103=0)
(104=0)
(105=0)
(110=1)
(111=1)
(112=1)
(113=1)
(114=1)
into app_lift.
variable labels app_lift "appartement met en zonder lift".
VALUE LABELS app_lift
0 'appartement zonder lift'
1 'appartement met lift'.
* opgelet: heel wat percelen omvatten zowel dingen met als zonder lift.

* einde verwerking cc_01.



* cc_02, type constructie.
* type bebouwing is niet enkel ingevuld voor panden waar wij dat als relevant zouden beschouwen.
recode constructiontype ('A'=1) ('B'=2) ('C'=3) into type_constructie.
VARIABLE LABELS type_constructie 'type constructie (open/halfopen/gesloten)'.
value labels type_constructie
1 'Gesloten bebouwing'
2 'Halfopen bebouwing'
3 'Open bebouwing'.



* VERDIEP EN AARD.

* cc_03, cc_04 EN sl2.
* cc_03 (floorNumberAboveground) is een variable voor dingen met verdiepingen. Bijvoorbeeld een huis of een appartementsblok. 
*-> bij cc_03 ging het om verdiepen, floorNumberAboveground is het aantal bouwlagen.
* sl2 (descriptPrivate) gaat over waar op het perceel een perceeldeel lig. Dit bevat indien nodig de verdieping van het ding in kwestie. Bijvoorbeeld een appartement. 
*-> in descriptPrivate zijn de voorlooptekens "  #' verwijderd.
* cc_04 (garret) gaat over bewoonde zolders.

* er zijn heel wat panden met nul verdiepen (1 bouwlaag), maar slechts zelden is dit bij een type gebouw waar je dat niet zou verwachten.
* we maken een variabele die op gebouwniveau van toepassing is (n_verdiep) en een die op wooneenheden van toepassing is (verdiep).
* omdat gebouwen geen eenheid zijn in het kadaster, moeten we helaas aggregeren op perceel. We nemen dan het hoogste van de twee variabelen en tellen er eventueel nog de bewoonde zolders bij.

* hetzelfde perceel kan huizen en appartementen hebben, met elk een eigen aantal verdiepen.
* doorgaans heeft een perceel met appartementen een enkele record met het aantal verdiepen, de rest staat op missing.
* in Antwerpen bestaat een huis met 18 verdiepen :)

* enkel van "buildings" (een enkele eigenaar) worden verdiepen geregistreerd in de constructiecode, niet van woningen in een building .
* daarom is het nodig om ook het veld "sl2/descriptPrivate" (gedetailleerde ligging of iets dergelijks) te gebruiken.

compute n_verdiep =floorNumberAboveground-1.
variable labels n_verdiep "aantal verdiepen (floorNumberAboveground-1)".


* sl2 bevat mogelijk zowel de "aard" als het verdiep.
* in theorie kan de aard enkel onderstaande dingen zijn.
string descript_clean (a35).
compute descript_clean=ltrim(ltrim(ltrim(ltrim(descriptPrivate,'.'),'"'),'/'),'#').
string aard (a4).
if CHAR.INDEX(descript_clean,'A')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'B')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'BU')=1 aard=char.substr(descript_clean,1,2).
if CHAR.INDEX(descript_clean,'G')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'HA')=1 aard=char.substr(descript_clean,1,2).
if CHAR.INDEX(descript_clean,'K')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'KA')=1 aard=char.substr(descript_clean,1,2).
if CHAR.INDEX(descript_clean,'M')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'P')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'S')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'T')=1 aard=char.substr(descript_clean,1,1).
if CHAR.INDEX(descript_clean,'VITR')=1 aard=char.substr(descript_clean,1,4).

* in theorie volgt onmiddelijk op aard de verdieping.
string verdiep0 (a254).
if aard~="" verdiep0=char.substr(descript_clean,length(ltrim(rtrim(aard)))+1).
* normaal gezien volgt op het verdiep een slash of niets meer.
string verdiep1 (a254).
compute verdiep1=char.substr(verdiep0,1,CHAR.INDEX(verdiep0,"/")-1).
do if CHAR.INDEX(verdiep0,"/")=0.
compute verdiep1=char.substr(verdiep0,1).
end if.

* maar soms hangen er nog spaties of punten voor het verdiep begint.
compute verdiep1=ltrim(ltrim(verdiep1,".")).

* soms staat er een punt in het verdiep, of een liggend streepje een @ of een &.
* in beide gevallen gaan we ervan uit dat het verdiep dan omschreven staat vOOr dat punt of streepje.
* OPMERKING: soms staat er iets als 1.2.3; dit wijzen we toe als 1. Wellicht zou 3 beter zijn. Misschien ook niet. 
* Alleszins is het wat complexer om die drie op te pikken zonder andere problemen te introduceren.
if CHAR.INDEX(verdiep1,".")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,".")-1).
if CHAR.INDEX(verdiep1,"-")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"-")-1).
if CHAR.INDEX(verdiep1," ")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1," ")-1).
if CHAR.INDEX(verdiep1,"@")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"@")-1).
if CHAR.INDEX(verdiep1,"&")>0 verdiep1=char.substr(verdiep1,1,CHAR.INDEX(verdiep1,"&")-1).

* we gaan ervan uit dat als het verdiepnummer nu nog altijd begint met OG, GV, TV of BE, alles wat erachter komt weg mag.
if CHAR.INDEX(verdiep1,"GV")=1 verdiep1=char.substr(verdiep1,1,2).
if CHAR.INDEX(verdiep1,"OG")=1  verdiep1=char.substr(verdiep1,1,2).
if CHAR.INDEX(verdiep1,"TV")=1 verdiep1=char.substr(verdiep1,1,2).

* we zetten het om naar een numerieke waarde.
compute verdiep=number(verdiep1,f3.0).
recode verdiep1 ('GV'=0) ('OG'=-1) ('TV'=0.5) ('BE'=0.75) into verdiep.
* opmerking: gv=gelijkvloers, og=ondergronds, er kunnen eventueel meerdere verdiepen of lokalen zijn, 
TV=tussenverdiep, 'BE'=bel-etage.


* indien S, G, K, P, B  dan is het een nummer, geen verdiep.
* indien VITR dan is het nog iets anders.
if aard="S" | aard="G" | aard="K" | aard="P" | aard="B" | aard="VITR" verdiep=$sysmis.

* enkele records hebben een belachelijk hoog aantal verdiepingen.
* vanaf hoeveel verdiepen het absurd wordt is natuurlijk gebiedsafhankelijk.
if verdiep>40 verdiep=$sysmis.

* einde toewijzing verdiep per rij. 
* we aggregeren per perceel om het aantal verdiepen van gebouwen te benaderen.

* opkuisen aard.
rename variables aard=aard0.
recode aard0 
('A'=1)
('B'=2)
('BU'=3)
('G'=4)
('HA'=5)
('K'=6)
('KA'=7)
('M'=8)
('P'=9)
('S'=10)
('T'=11)
('VITR'=12)
into aard.
value labels aard
1 'wooneenheid'
2 'bergplaats'
3 'bureaus'
4 'garage'
5 'handel'
6 'kelder'
7 'kamer'
8 'zolderkamer'
9 'parking'
10 'standplaats'
11 'tuin'
12 'vitrine'.
execute.
delete variables verdiep0 verdiep1  aard0 descript_clean.
* opmerking: enkele rijen krijgen een foute 'aard', omdat bijvoorbeeld BOUWGROND in dit veld gebruikt wordt, wat volgens de documentatie niet kan.


* cc_04, is er een zolder.
* die nemen we mee in sommige verdiepentellers.
compute bewoonbare_dakverdieping=garret.

VARIABLE LABELS bewoonbare_dakverdieping "bewoonbare dakverdieping (cc_04)".


* variabele om de 'beste' verdiepschatting te maken per perceel.
* OPMERKING: niet echt logisch dat dit hier staat.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /n_verdiep_max=MAX(n_verdiep) 
  /verdiep_max=MAX(verdiep)
  /dakverdiep_max=max(bewoonbare_dakverdieping).

compute verdiepen_perceel=max(n_verdiep_max,verdiep_max).
if missing(verdiepen_perceel) verdiepen_perceel=n_verdiep_max.
if missing(verdiepen_perceel) verdiepen_perceel=verdiep_max.
compute verdiepen_perceel=trunc(verdiepen_perceel).
compute verdiepen_inc_dakverdiep=verdiepen_perceel.
if dakverdiep_max=1 verdiepen_inc_dakverdiep=verdiepen_perceel+1.
EXECUTE.
delete variables n_verdiep_max verdiep_max dakverdiep_max.

variable labels verdiep "hoeveelste verdiep (sl2)".
variable labels verdiepen_perceel "aantal verdiepen perceel (sl2 en cc_03)".
variable labels verdiepen_inc_dakverdiep "aantal verdiepen perceel (inclusief dakverdiep)".





* cc_05, bouwjaar.
* tot 1930 is dit een categorie, daarna is het een exact cijfer.
* opnieuw: verschillende perceeldelen kunnen verschillende bouwjaren hebben. 
* In Antwerpen is dit in ongeveer  1200-1500 van de 140000 percelen het geval.
* 10% percelen zonder bouwjaar.


compute bouwjaar_ruw=constructionYear.
recode bouwjaar_ruw (1 thru 5 = copy) (6 thru highest=6) (missing=99) into bouwjaar_cat.
if bouwjaar_ruw>1930 & bouwjaar_ruw <1946 bouwjaar_cat=6.
if bouwjaar_ruw>1945 & bouwjaar_ruw <1983 bouwjaar_cat=7.
if bouwjaar_ruw>1983 & bouwjaar_ruw <1999 bouwjaar_cat=8.
if bouwjaar_ruw>1999 bouwjaar_cat=9.
value labels bouwjaar_cat
1  "voor 1850"
2 "1850-1874"
3 "1875-1899"
4 "1900-1918"
5 "1919-1930"
6 "1930-1945"
7 "1946-1983"
8 "1984-1999"
9 "2000-nu"
99 "leeg".
missing values bouwjaar_cat (99).

recode bouwjaar_ruw
(0 =99) (1=1800) (2=1862) (3=1887) (4=1908) (5=1924) (6 thru highest=copy) (missing=99)
into bouwjaar_schatting.
missing values bouwjaar_schatting (99).

if bouwjaar_ruw > 1930 bouwjaar_exact=bouwjaar_ruw.

variable labels bouwjaar_ruw "bouwjaar (categorie en jaar door elkaar)".
variable labels bouwjaar_cat "bouwjaar (categorie, alle percelen)".
variable labels bouwjaar_schatting "bouwjaar (schatting waar categorie, exact waar beschikbaar)".
variable labels bouwjaar_exact "bouwjaar (enkel indien exact)".




*cc_06, "renovatiejaar".
* dit is de laatste maal dat een wijziging op dit perceel aan het kadaster werd gemeld.
* het kan dan gaan om en verbouwingsplichtige renovatie, een wijziging van het aantal wooneenheden, etc.
* millenium bug: slechts twee digits beschikbaar. Maar sowieso pas ingevuld vanaf 1982, dus het probleem stelt zich pas in 2082.
compute jaar_wijziging=physModYear.
alter type jaar_wijziging (f4.0).

recode jaar_wijziging (1982 thru 1990 = 1) (1991 thru 1999=2) (2000 thru 2006=3) (2007 thru highest=4) into jaar_wijziging_cat.
value labels jaar_wijziging_cat
1 '1982-1990'
2 '1991-1999'
3 '2000-2006'
4 '2007-heden'.




* cc_07, "kwaliteit van de constructie".
* opmerking: 98,8% van de valid cases zijn "normaal".
* dit is in verhouding tot de buurt en het type pand. Een villa in een villawijk is dus normaal.
recode constructionquality ("M"=1) ("N"=2) ("L"=3) ("-"=98) (""=99) into kwaliteit.
missing values kwaliteit (98,99).
value labels kwaliteit
1 'minderwaardig'
2 'normaal'
3 'luxueus'.



* cc_08, "garages, parkings en/of overdekte standplaatsen".
* deze informatie zit verspreid over drie velden: sl2, classficatiecode, cc_08.
compute aantal_garages_ed_cc_08=garageNumber.
alter type aantal_garages_ed_cc_08 (f3.0).

* op basis van sl2 weten we het soort parkeerplaats.
if aard=4 | aard= 9 | aard=10 aard_parkeren=1.
if aard=4 aard_garage=1.
if aard=10 aard_standplaats=1.
if aard=9 aard_parking=1.
* in de classificatiecode kunnen we ook parkeerplaatsen vinden.
if classificatiecode=103 | classificatiecode=113 classificatie_parkeren=1.

* er zijn dus drie bronnen om een rij als een ding met een parkeerplaats te beschouwen.
if aantal_garages_ed_cc_08>0 | classificatie_parkeren=1 | aard_parkeren=1 ding_met_parking=1.

* sommige records hebben een aantal plaatsen, andere ZIJN een plaats. dus een complexe teller bouwen die het beste verzamelt.
* er zijn geen percelen waar zowel het aantal is ingevuld als dat er records zijn met individuele plaatsen.
compute aantal_parkeerplaatsen=0.
if aantal_garages_ed_cc_08>0 aantal_parkeerplaatsen=aantal_garages_ed_cc_08.
if aard_parkeren=1 & aantal_parkeerplaatsen=0 aantal_parkeerplaatsen=1.
if classificatie_parkeren=1 & missing(aard) & aantal_parkeerplaatsen=0 aantal_parkeerplaatsen=1.

* wat voor parkeerplaats is het?.
* indien geen details, zeg 1 of het aantal gekende plaatsen.
if (missing(aard_garage) & missing(aard_parking) & missing(aard_standplaats)) parking_onbekend_type=aantal_garages_ed_cc_08.
if classificatie_parkeren=1 & missing(aard_garage) & missing(aard_parking) & missing(aard_standplaats) & (missing(aantal_garages_ed_cc_08) | aantal_garages_ed_cc_08=0) parking_onbekend_type=1.
* indien wel details, zeg 1 of het aantal plaatsen.
if aantal_garages_ed_cc_08>0 & aard_garage=1 aard_garage=aantal_garages_ed_cc_08.
if aantal_garages_ed_cc_08>0 & aard_standplaats=1 aard_standplaats=aantal_garages_ed_cc_08.
if aantal_garages_ed_cc_08>0 & aard_parking=1 aard_parking=aantal_garages_ed_cc_08.

variable labels aantal_parkeerplaatsen "parkeergelegenheden (cc_08+cc01+sl2)".
variable labels aard_parkeren "parkeergelegenheden (sl2+cc08)".
variable labels aard_garage "garages (sl2+cc08)".
variable labels aard_standplaats "standplaats (sl2+cc08)".
variable labels aard_parking "parking (sl2+cc08)".
variable labels parking_onbekend_type "andere parkeerplaatsen (cc01+cc08)".

EXECUTE.
delete variables ding_met_parking aard_parkeren aantal_garages_ed_cc_08 classificatie_parkeren.



* cc09, centrale verwarming.
compute centrale_verwarming=centralheating.
missing values centrale_verwarming (99,98).


* cc_10, aantal badkamers.
compute aantal_badkamers=bathroomnumber.



* woningen tellen.

*VOORBEREIDING.

* een van de moeilijkste onderdelen van dit werk.
* onderstaande methode is het resultaat van uitgebreide vergelijkingen met de census, bevolkingsstatistieken en case studies.
* maar ze zit niet geweldig logisch in elkaar.

*CC_11 'aantal zelfstandige woongelegenheden'.
compute aantal_woningen_cc11=housingUnitNumber.

* appartementen, appartementsgebouwen en huizen hebben sowieso minstens 1 woning.
recode classificatiecode (10=1) (20=1) (30=1) (31=1) (32=1) (33=1) (40=1) 
(41=1) (50=1) (60=1) (70=1) (80=1) (100=1) (101=1) (105=1) (110=1) (111=1)
into cc01_woontype.

* aard, afgeleide van sl2.
if aard=1 woning_aard=1.
recode woning_aard (missing=0).

* perceel gebruik: : 
classificatie van het gebruik van het perceel, op basis van aggregatie van cc01. Puur een vereenvoudiging van cc01, behalve voor woonhandelsappartementen
1-4: huizen, appartementen (inclsuief handel)
5: handelshuizen
14: onbekend
perceel_gebruik.

recode cc01_woontype woning_aard aantal_woningen_cc11 (missing=0).


* UITVOERING.

* voor percelen met huizen of appartementen
    EN het ding zelf is een woontype cc01  OF het heeft een woning aard (volgens sl2)
    EN er is een woningenteller (in cc11)
    TEL die woningenteller.

if perceel_gebruik<5 & (cc01_woontype=1 | woning_aard=1) woningen=aantal_woningen_cc11.
* opmerking: er zijn (in 2014) 2000 records zonder woningenteller die hier niet meegenomen worden. Verder onderzoek zou kunnen uitwijzen dat je die best toch meeneemt.

* handelshuizen tellen we mee als er een woningenteller is ingevuld.
if perceel_gebruik=5 woningen=aantal_woningen_cc11.

* percelen met een ander gekend type gebruik tellen we nooit als woning.
if perceel_gebruik>5 & perceel_gebruik<14 woningen=0.

* indien het gebruik van het perceel onbekend is, dan tellen we ze als één woning als het een woning aard heeft, of volgens de teller van het aantal woningen als deze ingevuld is (ook als het geen woning aard heeft).
if perceel_gebruik=14 & woning_aard=1 woningen=max(1,aantal_woningen_cc11).
if perceel_gebruik=14 & woning_aard=0 woningen=aantal_woningen_cc11.


* bij aggregeren gewoon de som nemen.
recode woningen (missing=0).

* einde woningen tellen.




* woonplaatsen of kamers.
* ook ingevuld voor andere dingen dan wooneenheden.
* indien enkel volgens sl2 een woning: 81% missings.

*variable labels CC_12 'aantal woonplaatsen (kamers)'.

if woningen>0 aantal_kamers=placeNumber.
recode aantal_kamers  (missing=0).
compute kamers_per_woning=aantal_kamers/woningen.
* extreme waarden verwijderen.
recode kamers_per_woning (0=sysmis) (31 thru highest=sysmis).
* indien extreme waarde, ook de teller zelf verwijderen.
if missing(kamers_per_woning) aantal_kamers=$sysmis.
* teller voor kamers in andere dingen dan woningen.
if woningen=0 & placeNumber>0 kamers_niet_woning = placeNumber.

variable labels kamers_per_woning 'kamers per woning'.
variable labels aantal_kamers 'kamers in woningen'.
variable labels kamers_niet_woning 'kamers in andere dingen dan woningen'.




* bebouwde oppervlakte.

*variable labels CC_13 'bebouwde grondoppervlakte'.
compute bebouwde_oppervlakte_origineel=builtSurface.
* slechts 40 percelen met meer dan een oppervlaktewaarde.
* bijna 20% missing of nul op perceelniveau.
* ontbreekt in meer dan de helft van de gevallen bij appartementen.
* bebouwde oppervlakte ontbreekt bij percelen die ingedeeld zijn in appartementen met meerdere eigenaars.


* nuttige oppervlakte.
*variable labels CC_14 'Nuttige oppervlakte'.
compute nuttige_oppervlakte_origineel=usedSurface.
* nagenoeg voor alle woningen ingevuld.
* van de woning-rijen heeft 52%  zowel nuttige als bebouwde oppervlakte.


* cleanen oppervlaktes.

* indien je wil zien welke percelen een rare geometrie of een rare wettelijke oppervlakte hebben.
*compute test_gis_jur=juridische_oppervlakte_perceel/oppervlakte_perceel_gis.

* arbitraire grens: indien de bebouwde oppervlakte meer dan dubbel zo groot is als het maximum van geografische 
of juridsiche oppervlakte, dan beschouwen we deze als fout (onbestaand).
compute #test_bebouwde_opp=bebouwde_oppervlakte_origineel/max(oppervlakte_perceel_gis,juridische_oppervlakte_perceel).
if #test_bebouwde_opp<2 bebouwde_oppervlakte=bebouwde_oppervlakte_origineel.

* arbitraire grens: indien de nuttige oppervlakte meer dan dubbel zo groot is als het maximum van geografische of juridsiche oppervlakte, vermenigvuldigd met het aantal bouwlagen, dan beschouwen we deze als fout (onbestaand).
* we passen dit enkel toe indien er minstens een verdiepen is.
recode verdiepen_inc_dakverdiep
(lowest thru 0=0) (0 thru 0.99=0) (missing=0) into #verdiepenteller.
compute #test_nuttige_opp=nuttige_oppervlakte_origineel/(max(oppervlakte_perceel_gis,juridische_oppervlakte_perceel)*(#verdiepenteller+1)).
if #test_nuttige_opp< 2 | #verdiepenteller=0 nuttige_oppervlakte=nuttige_oppervlakte_origineel.

* als je alle rare gevallen bovenaan wilt hebben (best in hele module # verwijderen).
*compute maxtest=max(test_bebouwde_opp,test_nuttige_opp,test_gis_jur).
*sort cases maxtest (d).

* einde oppervlakte cleaning








* waar zijn de kelders.
if classificatiecode=104 | classificatiecode=114 | aard=6 kelder=1.


* EINDE UNIVERSELE VERWERKING.

* indeling die NIScodes voor grondgebruik probeert te reconstrueren.
* toewijzing aangeleverd door Virge.
* er zijn slechts enkele gevallen waar een perceel meerdere "echte" functies heeft.

value labels nature
510 'UITKIJK'
521 'ONDERGR. R.'
407 'HAND/HUIS'
408 'GR.WARENH.'
409 'GAR.STELPL'
410 'PARKEERGEB'
411 'SERV.STAT.'
412 'OVER.MARKT'
413 'TOONZAAL'
414 'KIOSK'
415 'DIERENGEB.'
403 'DRANKHUIS'
404 'HOTEL'
405 'RESTAURANT'
280 'ZUIVELFAB.'
281 'BAKKERIJ'
282 'VLEESW/FAB'
283 'SLACHTERIJ'
284 'VEEVOE/FAB'
285 'KOFFIEFAB.'
286 'BROUWERIJ'
287 'DRANKFABR.'
288 'TABAKFABR.'
289 'MAALDERIJ'
290 'VOEDINGS/F'
300 'KLEDINGFAB'
301 'TEXTIELFAB'
302 'LEDERWAR/F'
303 'MEUBELFAB.'
304 'SPEELG/FAB'
305 'PAPIERFAB.'
306 'GEBRUIKS/F'
320 'STEENBAKK.'
321 'CEMENTFAB.'
322 'ZAGERIJ'
323 'VERFFABR.'
324 'BOUWMAT/F.'
340 'METAALNIJV'
341 'HOOGOVEN'
342 'KALKHOVEN'
343 'CONSTR/WPL'
344 'ELEK.MAT.F.'
345 'PETROL/RAF'
346 'CHEMIC/FAB'
347 'RUBBERFAB.'
348 'IJSFABRIEK'
349 'GLASFABR.'
350 'PLAST/FAB.'
351 'AARDEW/FAB'
352 'KOLENMIJN'
353 'ELEK.CENTR'
354 'GASFABRIEK'
355 'GAZOMETER'
356 'COKESFABR.'
357 'NIJV/GEB.'
370 'HANGAR'
371 'MAGAZIJN'
376 'RESERVOIR'
377 'SILO'
379 'DROOGINST.'
380 'KOELINR.'
381 'MAT. & OUT.'
382 'BEDRIJFSC#'
520 'PUIN'
400 'BANK'
401 'BEURS'
402 'KANTOORGEB'
260 'DRUKKERIJ'
261 'GAR.WERKPL'
262 'SMIDSE'
263 'SCHRIJNW.'
264 'WASSERIJ'
265 'WERKPLAATS'
480 'KERK'
481 'KAPEL'
482 'KLOOSTER'
483 'PASTORIE'
484 'SEMINARIE'
485 'BISDOM'
486 'SYNAGOGE'
487 'MOSKEE'
488 'TEMPEL'
489 'GEB.ERED.'
462 'MUSEUM'
523 'KASTEEL'
524 'HISTOR.GEB'
525 'MONUMENT'
526 'WINDMOLEN'
527 'WATERMOLEN'
372 'ELEK.CABIN'
373 'PYLOON'
374 'GASCABINE'
375 'CABINE'
428 'STATION'
429 'WACHTHUIS'
430 'TEL/CEL'
431 'TELECOM/G.'
432 'LUCHTHAVEN'
528 'WATERTOREN'
529 'WATERWINN.'
530 'ZUIVER/INS'
531 'AFVALVERW.'
378 'ONDERZOEKC'
460 'SCHOOLGEB.'
461 'UNIVERSIT.'
420 'GEM/HUIS'
421 'GOUVER/GEB'
422 'K.PALEIS'
423 'GERECHTSH.'
424 'STRAFINR.'
425 'GEZANTSCH.'
426 'GENDARMER.'
427 'MILIT.GEB.'
433 'LIJKENHUIS'
434 'ADMIN.GEB.'
440 'WEESHUIS'
441 'KINDERBEW.'
442 'BESCHER/W.'
443 'RUSTHUIS'
444 'VERPL/INR.'
445 'KUURINR.'
446 'WELZIJNSG.'
240 'HOEVE'
241 'PAARDESTAL'
242 'DUIVENTIL'
243 'K.VEETEELT'
244 'G.VEETEELT'
245 'SERRE'
246 'PADDEST/KW'
247 'LANDGEBOUW'
463 'BIBLIOTH.'
505 'THEATER'
506 'SPEKT/ZAAL'
507 'KULT.CENTR'
508 'BIOSCOOP'
509 'CASINO'
406 'FEESTZAAL'
504 'JEUGDHEEM'
500 'BADINRICHT'
501 'SPORTGEB.'
502 'VAKAN/TEH.'
503 'VAKAN/VERB'
522 'PAVILJOEN'
164 'OPP.& G.D.'
165 'G.D.AP.GEB'
166 'BEB.OPP.A'
220 'D.AP.GEB.#'
221 'M.D.AP.GEB'
222 'BUILDING'
223 'HUIS#'
200 'HUIS'
201 'NOODWONING'
202 'KROTWONING'
203 'BERGPLAATS'
204 'GARAGE'
205 'AFDAK          '
206 'LAVATORY'
67 'BEB.OPP.G'
68 'BEB.OPP.U'
77 'KOER'
80 'MAT.& OUT.'
50 'NIJV/GROND'
51 'WERF'
52 'KAAI'
55 'SPOORWEG'
59 'KANAAL'
69 'BEB.OPP.N'
72 'VLIEGVELD'
73 'MILIT.TERR'
9 'BOS'
17 'PARK'
74 'KERKHOF'
35 'WOESTE GR.'
36 'HEIDE'
38 'MOERAS'
41 'AANSPOEL.'
43 'WAL'
44 'DIJK'
46 'STORT.WGR.'
71 'PARKING'
79 'D.PARKING#'
25 'POEL'
26 'VIJVER'
27 'MEER'
28 'GRACHT'
29 'SLOOT'
76 'BASSIN GEW'
33 'WEG'
34 'PLEIN'
1 'BOUWLAND'
2 'WEILAND'
3 'HOOILAND'
4 'TUIN'
5 'WARMOESGR.'
10 'BOOMG.HOOG'
11 'BOOMG.LAAG'
13 'BOOMKWEK.'
20 'SPEELTERR.'
18 'SPORTTERR.'
21 'KAMPEERT.'
78 'BOUWGROND'
70 'GROND'.


* OPMERKINGEN:
* er zijn wel wat percelen met meerdere "functies".
* maar in bijna alle gevallen is er een "functie" die je kan negeren, bijvoorbeeld "grond".
* we sorteren zo dat de eerste functie wellicht de meest zinvolle is, die nemen we dan mee in de aggregatie.
* > deze oplossing wordt hier niet toegepast, omdat we de classificatiecode gebruiken om het perceel te kwalificeren. de info hier gebruiken we enkel op niveau van de gebouwdelen.
recode nature (166=1)
(222=1)
(220=1)
(165=1)
(221=1)
(164=1)
(205=2)
(203=2)
(242=2)
(244=2)
(204=2)
(240=2)
(200=2)
(223=2)
(243=2)
(202=2)
(247=2)
(206=2)
(201=2)
(241=2)
(246=2)
(245=2)
(351=3)
(281=3)
(324=3)
(286=3)
(321=3)
(346=3)
(356=3)
(343=3)
(287=3)
(379=3)
(260=3)
(353=3)
(344=3)
(261=3)
(354=3)
(355=3)
(306=3)
(349=3)
(341=3)
(348=3)
(342=3)
(300=3)
(380=3)
(285=3)
(352=3)
(302=3)
(289=3)
(381=3)
(340=3)
(303=3)
(357=3)
(305=3)
(345=3)
(350=3)
(376=3)
(347=3)
(263=3)
(377=3)
(283=3)
(262=3)
(304=3)
(320=3)
(288=3)
(301=3)
(284=3)
(323=3)
(282=3)
(290=3)
(264=3)
(265=3)
(322=3)
(280=3)
(370=4)
(371=4)
(400=5)
(401=5)
(402=5)
(415=6)
(403=6)
(409=6)
(408=6)
(407=6)
(404=6)
(414=6)
(412=6)
(410=6)
(405=6)
(411=6)
(413=6)
(434=7)
(531=7)
(500=7)
(442=7)
(463=7)
(508=7)
(485=7)
(375=7)
(509=7)
(372=7)
(406=7)
(374=7)
(489=7)
(420=7)
(426=7)
(423=7)
(425=7)
(421=7)
(524=7)
(504=7)
(422=7)
(481=7)
(523=7)
(480=7)
(441=7)
(482=7)
(507=7)
(445=7)
(433=7)
(432=7)
(427=7)
(525=7)
(487=7)
(462=7)
(521=7)
(378=7)
(483=7)
(522=7)
(520=7)
(373=7)
(443=7)
(460=7)
(484=7)
(506=7)
(501=7)
(428=7)
(424=7)
(486=7)
(430=7)
(431=7)
(488=7)
(505=7)
(461=7)
(502=7)
(503=7)
(444=7)
(429=7)
(527=7)
(528=7)
(529=7)
(440=7)
(446=7)
(526=7)
(530=7)
(41=8)
(76=8)
(67=8)
(69=8)
(68=8)
(10=8)
(11=8)
(13=8)
(9=8)
(78=8)
(1=8)
(79=8)
(44=8)
(28=8)
(36=8)
(3=8)
(52=8)
(21=8)
(59=8)
(74=8)
(77=8)
(27=8)
(73=8)
(38=8)
(50=8)
(17=8)
(71=8)
(34=8)
(25=8)
(29=8)
(20=8)
(55=8)
(18=8)
(46=8)
(4=8)
(26=8)
(72=8)
(43=8)
(5=8)
(33=8)
(2=8)
(51=8)
(35=8)
(382=9)
(70=9)
(80=9)
(510=9)
 into NIS_hoofdgroep.
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

recode art_aard
(220=1)
(221=1)
(415=2)
(409=2)
(408=2)
(407=2)
(414=2)
(412=2)
(410=2)
(411=2)
(413=2)
(351=3)
(281=3)
(324=3)
(286=3)
(321=3)
(346=3)
(356=3)
(343=3)
(287=3)
(379=3)
(260=3)
(353=3)
(344=3)
(261=3)
(354=3)
(355=3)
(306=3)
(349=3)
(341=3)
(348=3)
(342=3)
(300=3)
(380=3)
(285=3)
(352=3)
(302=3)
(289=3)
(381=3)
(340=3)
(303=3)
(357=3)
(305=3)
(345=3)
(350=3)
(376=3)
(347=3)
(263=3)
(377=3)
(283=3)
(262=3)
(304=3)
(320=3)
(288=3)
(301=3)
(284=3)
(323=3)
(282=3)
(290=3)
(264=3)
(265=3)
(322=3)
(280=3)
(79=4)
(74=4)
(77=4)
(73=4)
(521=4)
(71=4)
(72=4)
(400=5)
(401=5)
(402=5)
(205=6)
(203=6)
(204=6)
(206=6)
(10=7)
(11=7)
(9=8)
(1=9)
(78=10)
(222=11)
(485=12)
(489=12)
(481=12)
(480=12)
(482=12)
(487=12)
(483=12)
(484=12)
(486=12)
(488=12)
(166=13)
(165=13)
(164=13)
(76=14)
(28=14)
(59=14)
(27=14)
(25=14)
(29=14)
(26=14)
(34=15)
(33=15)
(3=16)
(403=17)
(404=17)
(405=17)
(240=18)
(200=18)
(223=18)
(202=18)
(201=18)
(242=19)
(244=19)
(243=19)
(247=19)
(241=19)
(246=19)
(524=20)
(523=20)
(525=20)
(527=20)
(526=20)
(52=21)
(50=21)
(55=21)
(51=21)
(531=22)
(375=22)
(372=22)
(374=22)
(432=22)
(373=22)
(428=22)
(430=22)
(431=22)
(429=22)
(528=22)
(529=22)
(530=22)
(463=23)
(462=23)
(378=23)
(460=23)
(461=23)
(434=24)
(420=24)
(426=24)
(423=24)
(425=24)
(421=24)
(422=24)
(427=24)
(424=24)
(370=25)
(371=25)
(17=26)
(520=27)
(500=28)
(508=28)
(509=28)
(406=28)
(504=28)
(21=28)
(507=28)
(522=28)
(20=28)
(506=28)
(501=28)
(18=28)
(505=28)
(502=28)
(503=28)
(245=29)
(442=30)
(441=30)
(445=30)
(433=30)
(443=30)
(444=30)
(440=30)
(446=30)
(67=31)
(69=31)
(68=31)
(4=32)
(13=33)
(5=33)
(2=34)
(41=35)
(44=35)
(36=35)
(38=35)
(46=35)
(43=35)
(35=35)
(382=36)
(70=36)
(80=36)
(510=36)
 into NIS_rubriek.

value labels nis_rubriek
1 'Afzonderlijke appartementen (met KI, zonder oppervlakte)'
2 'Allerlei handelsinrichtingen'
3 'Ambachts- en industriegebouwen'
4 'Andere'
5 'Banken, kantoren'
6 'Bijgebouwen'
7 'Boomgaard'
8 'Bos'
9 'Bouwland'
10 'Bouwpercelen'
11 'Building'
12 'Eredienst'
13 'Fictieve percelen appartementsgebouw (zonder KI, met oppervlakte)'
14 'Gekadastreerde wateren'
15 'Gekadastreerde wegen'
16 'Hooiland'
17 'Horeca'
18 'Huis, hoeve'
19 'Landelijke bijgebouwen'
20 'Monumenten'
21 'Nijverheidsgronden'
22 'Nutsvoorzieningen'
23 'Onderwijs, onderzoek en cultuur'
24 'Openbare gebouwen'
25 'Opslagruimte'
26 'Park'
27 'Puin'
28 'Recreatie, sport'
29 'Serre'
30 'Sociale Zorg en ziekenzorg'
31 'Splitsing voor grond en gebouw'
32 'Tuin'
33 'Tuinbouwgronden'
34 'Weiland'
35 'Woeste gronden'
36 'niet toegewezen'.

*aanmaken dummy's.

* OPMERKINGEN:
* er zijn wel wat percelen met meerdere "functies".
* maar in bijna alle gevallen is er een "functie" die je kan negeren, bijvoorbeeld "grond".
* als je op  PERCEELNIVEAU iets zinvol wil zeggen: sorteer de perceeldelen zo dat de eerste functie wellicht de meest zinvolle is, die nemen we dan mee in de aggregatie, door iets als functie_nis=first(fuctie_nis).

if NIS_hoofdgroep =1 nis_app_building=1.
if NIS_hoofdgroep =2 nis_huis_hoeve=1.
if NIS_hoofdgroep =3 nis_industrie=1.
if NIS_hoofdgroep =4 nis_opslag=1.
if NIS_hoofdgroep =5 nis_kantoor=1.
if NIS_hoofdgroep =6 nis_commercieel=1.
if NIS_hoofdgroep =7 nis_ander=1.
if NIS_hoofdgroep =8 nis_onbebouwd=1.
if NIS_hoofdgroep =8 nis_niettoegekend=1.




* kadastraal inkomen.
* dit bestaat uit onbelastbaar en belastbaar kadastraal inkomen.
* deze informatie zit verspreid over vier velden: ri1, ri2 en cod1, cod2.


* cod = F, K, P of L betekent belastbaar kadastraal inkomen.
 if charCadastralIncome="F" | charCadastralIncome="P" | charCadastralIncome="K" | charCadastralIncome="L" KI_belastbaar=cadastralIncome.
* bij andere letters betreffen de variabelen onbelastbaar inkomen.
if ~(charCadastralIncome="F" | charCadastralIncome="P" | charCadastralIncome="K" | charCadastralIncome="L") KI_onbelastbaar=cadastralIncome.
execute.

SAVE OUTFILE='' + basismap + 'werkbestanden\werkbestand_gebouwdelen.sav'
  /COMPRESSED.


