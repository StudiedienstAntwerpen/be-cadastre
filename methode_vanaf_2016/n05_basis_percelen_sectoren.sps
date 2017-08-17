* Encoding: windows-1252.
DEFINE werkbestanden () '\\Antwerpen.local\Doc\OD_IF_AUD\2_04_Statistiek\2_04_01_Data_en_kaarten\kadaster_percelen\kadaster_gebouwdelen_2016\werkbestanden\' !ENDDEFINE.
DEFINE locatie_swing () '\\Antwerpen.local\Doc\OD_IF_AUD\2_04_Statistiek\2_04_09_Ontwikkeling_website_DSPA\Swing_cijfers_interactief\bestanden_swing\Kadaster' !ENDDEFINE.


* vergeet de backslash op het einde niet!

* de tijdsvariabelen moeten opgevuld met het verwerkte jaar, sommige weggeschreven bestanden krijgen dit jaartal ook mee in de bestandsnaam.
DEFINE datum_van_de_dump () 20160101 !ENDDEFINE.
DEFINE datum_toestand_string () "2016" !ENDDEFINE.
DEFINE datum_toestand () 2016 !ENDDEFINE.


GET FILE='' + werkbestanden + 'werkbestand_gebouwdelen.sav'.
DATASET NAME gebouwdelen WINDOW=FRONT.
dataset close prc.
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


* indeling Vreidi.
recode nature
(220=1)
(200=1)
(201=1)
(202=1)
(203=1)
(205=1)
(206=1)
(240=1)
(532=1)
(164=1)
(165=1)
(166=1)
(204=8)
(221=1)
(222=1)
(223=1)
(241=7)
(242=7)
(243=7)
(244=7)
(245=7)
(246=7)
(247=7)
(260=2)
(261=2)
(262=2)
(263=2)
(264=2)
(265=2)
(280=2)
(281=2)
(282=2)
(283=2)
(284=2)
(285=2)
(286=2)
(287=2)
(288=2)
(289=2)
(290=2)
(300=2)
(301=2)
(302=2)
(303=2)
(304=2)
(305=2)
(306=2)
(320=2)
(321=2)
(322=2)
(323=2)
(324=2)
(340=2)
(341=2)
(342=2)
(343=2)
(344=2)
(345=2)
(346=2)
(347=2)
(348=2)
(349=2)
(350=2)
(351=2)
(352=2)
(353=2)
(354=2)
(355=2)
(356=2)
(357=2)
(370=2)
(371=2)
(372=4)
(373=4)
(374=4)
(375=4)
(376=2)
(377=2)
(378=4)
(379=2)
(380=2)
(381=2)
(382=2)
(400=2)
(401=2)
(402=2)
(403=2)
(404=2)
(405=2)
(406=5)
(407=3)
(408=2)
(409=8)
(410=8)
(411=2)
(412=2)
(413=2)
(414=2)
(415=2)
(420=4)
(421=4)
(422=4)
(423=4)
(424=4)
(425=4)
(426=4)
(427=4)
(428=4)
(429=4)
(430=4)
(431=4)
(432=4)
(433=4)
(434=4)
(440=4)
(441=4)
(442=4)
(443=4)
(444=4)
(445=4)
(446=4)
(460=4)
(461=4)
(462=5)
(463=5)
(480=4)
(481=4)
(482=4)
(483=4)
(484=4)
(485=4)
(486=4)
(487=4)
(488=4)
(489=4)
(500=5)
(501=5)
(502=5)
(503=5)
(504=5)
(505=5)
(506=5)
(507=5)
(508=5)
(509=5)
(510=9)
(520=9)
(521=9)
(522=9)
(523=4)
(524=4)
(525=4)
(526=4)
(527=4)
(528=4)
(529=4)
(530=4)
(531=4)
(1=7)
(2=7)
(3=7)
(4=7)
(5=7)
(9=6)
(10=7)
(11=7)
(13=7)
(17=6)
(18=5)
(20=5)
(21=5)
(25=8)
(26=8)
(27=8)
(28=8)
(29=8)
(33=8)
(34=8)
(35=6)
(36=6)
(38=6)
(41=6)
(43=6)
(44=6)
(46=6)
(50=2)
(51=2)
(52=2)
(55=2)
(59=8)
(67=9)
(68=9)
(69=2)
(70=9)
(71=8)
(72=4)
(73=4)
(74=6)
(76=8)
(77=9)
(78=1)
(79=8)
(80=9)
(533=1)
(534=1)
(535=2)
(536=2)
(537=1)
(538=9)
(539=9)
(540=9)
(541=9)
(542=9)
(543=8)
(544=8)
(545=8)
(546=9)
(547=2)
(548=8)
(549=9)
(550=9)
(551=9)
(552=9)
into hoofdgebruik.

recode nature
(220=1002)
(200=1001)
(201=1001)
(202=1001)
(203=1001)
(205=1001)
(206=1001)
(240=1001)
(532=1001)
(164=1002)
(165=1002)
(166=1002)
(204=8003)
(221=1002)
(222=1002)
(223=1002)
(241=7001)
(242=7001)
(243=7001)
(244=7001)
(245=7001)
(246=7001)
(247=7001)
(260=2003)
(261=2003)
(262=2003)
(263=2003)
(264=2003)
(265=2003)
(280=2003)
(281=2003)
(282=2003)
(283=2003)
(284=2003)
(285=2003)
(286=2003)
(287=2003)
(288=2003)
(289=2003)
(290=2003)
(300=2003)
(301=2003)
(302=2003)
(303=2003)
(304=2003)
(305=2003)
(306=2003)
(320=2003)
(321=2003)
(322=2003)
(323=2003)
(324=2003)
(340=2003)
(341=2003)
(342=2003)
(343=2003)
(344=2003)
(345=2003)
(346=2003)
(347=2003)
(348=2003)
(349=2003)
(350=2003)
(351=2003)
(352=2003)
(353=2003)
(354=2003)
(355=2003)
(356=2003)
(357=2003)
(370=2004)
(371=2004)
(372=4006)
(373=4006)
(374=4006)
(375=4006)
(376=2003)
(377=2003)
(378=4001)
(379=2003)
(380=2003)
(381=2003)
(382=2003)
(400=2002)
(401=2002)
(402=2002)
(403=2001)
(404=2001)
(405=2001)
(406=5002)
(407=3001)
(408=2001)
(409=8003)
(410=8003)
(411=2001)
(412=2001)
(413=2001)
(414=2001)
(415=2001)
(420=4003)
(421=4003)
(422=4003)
(423=4003)
(424=4003)
(425=4003)
(426=4003)
(427=4003)
(428=4006)
(429=4006)
(430=4006)
(431=4006)
(432=4006)
(433=4003)
(434=4003)
(440=4002)
(441=4002)
(442=4002)
(443=4002)
(444=4002)
(445=4002)
(446=4002)
(460=4001)
(461=4001)
(462=5002)
(463=5002)
(480=4004)
(481=4004)
(482=4004)
(483=4004)
(484=4004)
(485=4004)
(486=4004)
(487=4004)
(488=4004)
(489=4004)
(500=5001)
(501=5001)
(502=5004)
(503=5004)
(504=5002)
(505=5002)
(506=5002)
(507=5002)
(508=5002)
(509=5002)
(510=9001)
(520=9001)
(521=9001)
(522=9001)
(523=4005)
(524=4005)
(525=4005)
(526=4005)
(527=4005)
(528=4006)
(529=4006)
(530=4006)
(531=4006)
(1=7001)
(2=7001)
(3=7001)
(4=7001)
(5=7001)
(9=6001)
(10=7001)
(11=7001)
(13=7001)
(17=6002)
(18=5001)
(20=5003)
(21=5004)
(25=8002)
(26=8002)
(27=8002)
(28=8002)
(29=8002)
(33=8001)
(34=8001)
(35=6003)
(36=6003)
(38=6003)
(41=6003)
(43=6003)
(44=6003)
(46=6003)
(50=2005)
(51=2005)
(52=2005)
(55=2005)
(59=8002)
(67=9001)
(68=9001)
(69=2005)
(70=9001)
(71=8003)
(72=4006)
(73=4006)
(74=6002)
(76=8002)
(77=9001)
(78=1003)
(79=8003)
(80=9001)
(533=1002)
(534=1002)
(535=2001)
(536=2002)
(537=1002)
(538=9001)
(539=9001)
(540=9001)
(541=9001)
(542=9001)
(543=8003)
(544=8003)
(545=8003)
(546=9001)
(547=2001)
(548=8001)
(549=9001)
(550=9001)
(551=9001)
(552=9001)
into detailgebruik.


value labels hoofdgebruik
1 'Wonen'
2 'Bedrijf'
3 'Gemengd'
4 'Gemeenschap'
5 'Recreatie'
6 'Groen'
7 'Land- en Tuinbouw'
8 'Infrastructuur'
9 'Andere'.

value labels detailgebruik
1001 'Eengezinswoning'
1002 'Meergezinsgebouw'
1003 'Bouwgrond'
2001 'Commercieel gebouw'
2002 'Kantoorgebouw'
2003 'Industriegebouw'
2004 'Opslaggebouw'
2005 'Industriegrond'
3001 'Woon- en commercieel gebouw'
4001 'Onderwijs'
4002 'Zorg'
4003 'Openbaar gebouw'
4004 'Eredienst'
4005 'Monument'
4006 'Nutsvoorziening'
5001 'Sport'
5002 'Cultuur'
5003 'Jeugd'
5004 'Vakantie'
6001 'Bos'
6002 'Park'
6003 'Woeste grond'
7001 'Land- en Tuinbouw'
8001 'Gekadastreerde weg'
8002 'Gekadastreerd water'
8003 'Parking'
9001 'Andere'.



* morfologische eengezinswoningen zijn meergezinsgebouwen als er meerdere woningen in zitten.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /woningen_op_perceel=SUM(woningen).
if detailgebruik=1001 & woningen_op_perceel > 1 detailgebruik=1002.
* opmerking: er zijn enkele percelen waar enkele dingen wel een woonfunctie hebben, maar die toch geen woningen hebben. Deze kunnen in enkele gevallen zowel eengzinswoning als meergezinsgebouw meekrijgen.

* definieer hoofdgebruik.
* er zijn er verschillende mogelijk.
DATASET DECLARE hoofdgebruik0.
AGGREGATE
  /OUTFILE='hoofdgebruik0'
  /BREAK=capakey statsec wijkcode hoofdgebruik
  /woningen=SUM(woningen).
dataset activate hoofdgebruik0.

* verwijder de categorie "andere" indien er ook een ander hoofdgebruik is.
* (ofwel: als er een "gewoon" hoofdgebruik is in combinatie met "ander" hoofdgebruik, dan houden we dit "gewoon" hoofdgebruik over).
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /aantal_hoofdgebruiken=N.
compute verwijderen=0.
if aantal_hoofdgebruiken>1 & hoofdgebruik=9 verwijderen=1.
FILTER OFF.
USE ALL.
SELECT IF (verwijderen = 0).
EXECUTE.

* hou één gebruik over (dit mag willekeurig zijn).
DATASET DECLARE hoofdgebruik.
AGGREGATE
  /OUTFILE='hoofdgebruik'
  /BREAK=capakey
  /hoofdgebruik=FIRST(hoofdgebruik)
  /aantal_hoofdgebruiken=N.
dataset activate hoofdgebruik.
dataset close hoofdgebruik0.


* als er toch nog meerdere hoofdgebruiken waren, dan voegen we deze samen tot één.
if aantal_hoofdgebruiken>1 hoofdgebruik=3.
EXECUTE.
delete variables aantal_hoofdgebruiken.
* EINDE HOOFDGEBRUIK (we halen dit op na grote aggregate naar percelen).

* DETAIL GEBRUIK: alle gebruiken, gescheiden door puntkomma.
DATASET ACTIVATE gebouwdelen.

* verzamel de verschillende gebruiken.
DATASET DECLARE detailgebruik.
AGGREGATE
  /OUTFILE='detailgebruik'
  /BREAK=capakey detailgebruik
  /N_BREAK=N.
dataset activate detailgebruik.

* geef ze een volgnummer binnen het perceel.
if $casenum=1 volgnummer=1.
if capakey~=lag(capakey) volgnummer=1.
if capakey=lag(capakey) volgnummer=lag(volgnummer)+1.

* tel het aantal gebruiken binnen het perceel.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /aantaldetailgebruiken=N.

* voeg de gebruiken samen tot één variabele.
string detailgebruik0 (a100).
compute detailgebruik0 =VALUELABEL(detailgebruik).
string detailgebruikgroep (a500).
if volgnummer=1 detailgebruikgroep=detailgebruik0.
if capakey=lag(capakey) & detailgebruik0~=lag(detailgebruik0) detailgebruikgroep=concat(ltrim(rtrim(lag(detailgebruikgroep))),";",detailgebruik0). 
EXECUTE.

* de laatste rij van het perceel is degene met de volledige info over alle gebruik.
* de laatste rij is waar volgnummer gelijk is aan aantaldetailgebruiken.

FILTER OFF.
USE ALL.
SELECT IF (aantaldetailgebruiken = volgnummer).
EXECUTE.


* controleer of je lengte genoeg hebt!.
*compute lengte=length(ltrim(rtrim(detailgebruikgroep))).
alter type detailgebruikgroep (a100).

match files
/file=*
/keep=capakey detailgebruikgroep.
rename variables detailgebruikgroep=detailgebruik.

* EINDE aanmaak detailgebruik (we halen dit op na grote aggregate naar percelen).


* BEGIN verzamel aarden per perceel.

* DETAIL aarden: alle gebruiken, gescheiden door puntkomma.
DATASET ACTIVATE gebouwdelen.

* verzamel de verschillende gebruiken.
DATASET DECLARE nature.
AGGREGATE
  /OUTFILE='nature'
  /BREAK=capakey nature
  /N_BREAK=N.
dataset activate nature.

* geef ze een volgnummer binnen het perceel.
if $casenum=1 volgnummer=1.
if capakey~=lag(capakey) volgnummer=1.
if capakey=lag(capakey) volgnummer=lag(volgnummer)+1.

* tel het aantal gebruiken binnen het perceel.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=capakey
  /aantalgebruiken=N.

* voeg de gebruiken samen tot één variabele.
string naturegroup (a100).
alter type nature (a3).
if volgnummer=1 naturegroup=nature.
if capakey=lag(capakey) & nature~=lag(nature) naturegroup=concat(ltrim(rtrim(lag(naturegroup))),";",nature). 
EXECUTE.

* de laatste rij van het perceel is degene met de volledige info over alle gebruik.
* de laatste rij is waar volgnummer gelijk is aan aantalgebruiken.

FILTER OFF.
USE ALL.
SELECT IF (aantalgebruiken = volgnummer).
EXECUTE.


* controleer of je lengte genoeg hebt!.
compute naturegroup=ltrim(rtrim(naturegroup)).
*compute lengte=length(ltrim(rtrim(naturegroup))).
alter type naturegroup (a100).

match files
/file=*
/keep=capakey naturegroup.
rename variables naturegroup=nature.

* EINDE aanmaak nature (we halen dit op na grote aggregate naar percelen).





DATASET ACTIVATE gebouwdelen.
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
/parkeerplaatsen=sum(aantal_parkeerplaatsen)
/NIS_hoofdgroep=min(nis_hoofdgroep)
/nis_app_building=max(nis_app_building)
/nis_huis_hoeve=max(nis_huis_hoeve)
/nis_industrie=max(nis_industrie)
/nis_opslag=max(nis_opslag)
/nis_kantoor=max(nis_kantoor)
/nis_commercieel=max(nis_commercieel)
/nis_ander=max(nis_ander)
/nis_onbebouwd=max(nis_onbebouwd)
/nis_niettoegekend=max(nis_niettoegekend).
DATASET ACTIVATE basic.

* voeg hoofdgebruik toe.
sort cases capakey (a).
MATCH FILES /FILE=*
  /TABLE='hoofdgebruik'
  /BY capakey.
EXECUTE.
dataset close hoofdgebruik.

variable labels hoofdgebruik "hoofdgebruik (op perceelniveau)".

* voeg detailgebruik toe.

sort cases capakey (a).
MATCH FILES /FILE=*
  /TABLE='detailgebruik'
  /BY capakey.
EXECUTE.
dataset close detailgebruik.

variable labels detailgebruik "detailgebruik (op perceelniveau)".

* voeg nature toe.

sort cases capakey (a).
MATCH FILES /FILE=*
  /TABLE='nature'
  /BY capakey.
EXECUTE.
dataset close nature.

variable labels nature "nature (op perceelniveau)".

DATASET ACTIVATE gebouwdelen.

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
EXECUTE.

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
* we tellen het enkel indien het een perceel betreft met Ã©Ã©n woning waar een huis of handelshuis staat.
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

RENAME VARIABLES eigenaarswoning=eigenaarswoningen.
rename variables prc_onbebouwd_opp=onbebouwd_opp.
rename variables prc_vloeroppervlakte=vloeroppervlakte.
rename variables prc_eengezinswoning=eengezinswoning.
rename variables prc_meergezinswoningen=meergezinswoningen.

dataset copy percelenset.
DATASET ACTIVATE percelenset.

rename variables (prc_sombouwjaren_woningen
prc_woningen_met_bouwjaar = sombouwjaren_woningen
woningen_met_bouwjaar).

rename variables woonkamers = woonvertrekken.
compute p_eigenaarswoningen=eigenaarswoningen/woningen*100.
compute vloer_terrein_index=vloeroppervlakte/oppervlakte_perceel_gis.
compute datum_toestand=datum_van_de_dump.
compute gemiddeld_bouwjaar_woningen=sombouwjaren_woningen/woningen_met_bouwjaar.
recode gemiddeld_bouwjaar_woningen (0=sysmis).




rename variables bebouwingstype=onbebouwd_deel.
rename variables meergezinswoningen=woningen_in_meergezinsgebouwen.

if gesloten_bebouwing=1 bebouwingstype=1.
if halfopen_bebouwing=1 bebouwingstype=2.
if open_bebouwing=1 bebouwingstype=3.
value labels bebouwingstype
1 'gesloten bebouwing'
2 'halfopen bebouwing'
3 'open bebouwing'.


rename variables type_eigenaars_perceel=type_eigenaars_perceel0.
string type_eigenaars_perceel (a40).
compute type_eigenaars_perceel=VALUELABEL(type_eigenaars_perceel0).

rename variables bebouwingstype=bebouwingstype0.
string bebouwingstype (a20).
compute bebouwingstype=VALUELABEL(bebouwingstype0).

rename variables hoofdgebruik=hoofdgebruik0.
string hoofdgebruik (a20).
compute hoofdgebruik=VALUELABEL(hoofdgebruik0).

rename variables onbebouwd_deel=onbebouwd_deel0.
string onbebouwd_deel (a20).
compute onbebouwd_deel=VALUELABEL(onbebouwd_deel0).



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
vloer_terrein_index
verdiepen
woningen
eigenaarswoningen
p_eigenaarswoningen
eengezinswoning
woningen_in_meergezinsgebouwen
woonvertrekken
bouwjaar_origineel_recentst
oudste_bouwjaar
recentste_bouwjaar
recentste_jaar_wijziging
sombouwjaren_woningen
woningen_met_bouwjaar
gemiddeld_bouwjaar_woningen
parkeerplaatsen
type_eigenaars_perceel
bebouwingstype
onbebouwd_deel
hoofdgebruik
detailgebruik
nature
datum_toestand.

rename variables adressen=kadaster_adressen.

alter type 
juridische_oppervlakte_perceel
bebouwde_oppervlakte_origineel
nuttige_oppervlakte_origineel
bebouwde_oppervlakte
onbebouwd_opp
nuttige_oppervlakte
woonoppervlakte
vloeroppervlakte
vloer_terrein_index
verdiepen
woningen
eigenaarswoningen
p_eigenaarswoningen
eengezinswoning
woningen_in_meergezinsgebouwen
woonvertrekken
bouwjaar_origineel_recentst
oudste_bouwjaar
recentste_bouwjaar
recentste_jaar_wijziging
sombouwjaren_woningen
woningen_met_bouwjaar
gemiddeld_bouwjaar_woningen
parkeerplaatsen
datum_toestand (f8.0).

SAVE OUTFILE='' + werkbestanden + 'dataset_percelen.sav'
  /COMPRESSED.

SAVE TRANSLATE OUTFILE='' + werkbestanden + 'analysekaart_percelen_unicode.csv'
  /TYPE=CSV
  /ENCODING='UTF8'
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.



* TOT HIER GERAAKT: hervatten proces.

dataset activate basic.
*dataset close percelenset.

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
/prc_n_woonkamers=sum(woonkamers)
  /prc_woning_rijhuis=SUM(prc_woning_rijhuis) 
  /prc_woning_halfopenhuis=SUM(prc_woning_halfopenhuis) 
  /prc_woning_openhuis=SUM(prc_woning_openhuis) 
  /prc_eengezinswoning=SUM(eengezinswoning) 
  /prc_meergezinswoningen=SUM(meergezinswoningen) 
  /prc_woon_parkeren=SUM(prc_woon_parkeren) 
  /prc_woningen_geenparking=SUM(prc_woningen_geenparking) 
  /prc_woningen_teweinigparking=SUM(prc_woningen_teweinigparking) 
  /prc_woningen_netgenoegparking=SUM(prc_woningen_netgenoegparking) 
  /prc_woningen_parkeeroverschot=SUM(prc_woningen_parkeeroverschot)
  /prc_vloeroppervlakte=SUM(vloeroppervlakte)
   /prc_woonoppervlakte=SUM(woonoppervlakte)
   /prc_door_eigenaar_bewoonde_woning=sum(eigenaarswoningen)
/prc_eengezins_eigenaarswoning=sum(prc_eengezins_eigenaarswoning)
/prc_oudewoning=sum(prc_oudewoning)
/prc_sombouwjaren_woningen=sum(prc_sombouwjaren_woningen)
/prc_woningen_met_bouwjaar=sum(prc_woningen_met_bouwjaar).
dataset activate statsecprc.
* de volgende aanpassingen zijn er om het bestand helemaal af te stemmen op het formaat van Swing.
rename variables statsec=geoitem.
alter type geoitem (a5).
recode geoitem (""="9999").
compute period=datum_toestand.
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
  /BREAK=wijkcode /prc_woningen=SUM(woningen) 
  /prc_aantal=N
  /prc_opp_gis=SUM(oppervlakte_perceel_gis) 
  /prc_juridische_oppervlakte=sum(juridische_oppervlakte_perceel)
  /prc_verdiep_relevant=SUM(verdiep_relevant)
  /prc_verdiep_som=sum(verdiepen)
  /prc_verdiep_0_2=SUM(verdiep_0_2) 
  /prc_verdiep_3_4=SUM(verdiep_3_4) 
  /prc_verdiep_5_9=SUM(verdiep_5_9) 
  /prc_verdiep_10plus=SUM(verdiep_10plus)
/prc_n_woonkamers=sum(woonkamers)
  /prc_woning_rijhuis=SUM(prc_woning_rijhuis) 
  /prc_woning_halfopenhuis=SUM(prc_woning_halfopenhuis) 
  /prc_woning_openhuis=SUM(prc_woning_openhuis) 
  /prc_eengezinswoning=SUM(eengezinswoning) 
  /prc_meergezinswoningen=SUM(meergezinswoningen) 
  /prc_woon_parkeren=SUM(prc_woon_parkeren) 
  /prc_woningen_geenparking=SUM(prc_woningen_geenparking) 
  /prc_woningen_teweinigparking=SUM(prc_woningen_teweinigparking) 
  /prc_woningen_netgenoegparking=SUM(prc_woningen_netgenoegparking) 
  /prc_woningen_parkeeroverschot=SUM(prc_woningen_parkeeroverschot)
  /prc_vloeroppervlakte=SUM(vloeroppervlakte)
   /prc_woonoppervlakte=SUM(woonoppervlakte)
   /prc_door_eigenaar_bewoonde_woning=sum(eigenaarswoningen)
/prc_eengezins_eigenaarswoning=sum(prc_eengezins_eigenaarswoning)
/prc_oudewoning=sum(prc_oudewoning)
/prc_sombouwjaren_woningen=sum(prc_sombouwjaren_woningen)
/prc_woningen_met_bouwjaar=sum(prc_woningen_met_bouwjaar).
dataset activate wijkprc.
rename variables wijkcode=geoitem.
alter type geoitem (a5).
recode geoitem (""="onb").
compute period=datum_toestand.
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

SAVE TRANSLATE OUTFILE='' + locatie_swing + 'kadaster_' + datum_toestand_string + '2016.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.



dataset activate basic.
dataset close wijkprc.
dataset close gebouwdelen.

