* Encoding: windows-1252.

DEFINE basismap () 'C:\Users\sa59772\Desktop\kadasterlokaal\kadaster2016\legger\' !ENDDEFINE.





GET DATA  /TYPE=TXT
  /FILE=''
    + basismap + 'owner.csv'
  /DELCASE=LINE
  /DELIMITERS=";"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=propertySituationIdf F9
order F3
partyType F2
right A50
right_trad A50
managedBy F1
officialId F12
name A100
firstname A100
birthdate A10
country A2
zipCode A10
municipality_fr A100
municipality_nl A100
street_fr A100
street_nl A100
number A10
boxNumber A10
officialId_partner F12
name_partner A100
firstName_partner A100
birthdate_partner A10
country_partner A2
zipCode_partner A10
municipality_partner_fr A100
municipality_partner_nl A100
street_partner_fr A100
street_partner_nl A100
number_partner A10
boxNumber_partner A10
coOwner A100
anonymousOwner A100
dateSituation A8.
CACHE.
EXECUTE.
DATASET NAME owners WINDOW=FRONT.

value labels partytype
1 '1 In gemeenschap'
2 '2 Tijdelijke vereniging'
3 '3 Feitelijke vereniging'
4 '4 Natuurlijk persoon'
5 '5 Rechtspersoon'
6 '6 Andere'
7 '7 Erfloos'
8 '8 Onbeheerde nalatenschap'
9 '9 Belgische staat'
13 '13 gedeeltelijk van de gemeenschap en gedeeltelijk van de vrouw'
15 '15 gedeeltelijk van de gemeenschap en gedeeltelijk van de man'
16 '16 gedeeltelijk van de vrouw en gedeeltelijk van de man'
17 '17 gedeeltelijk van de gemeenschap, gedeeltelijk van de vrouw en gedeeltelijk van de man'
18 '18 ontbrekende informatie'
19 '19 Algemene vereniging'.


SAVE OUTFILE='' + basismap + '\basisbestand_owner.sav'
  /COMPRESSED.



GET DATA  /TYPE=TXT
  /FILE=''
    + basismap + 'parcel.csv'
  /ENCODING='Locale'
  /DELCASE=LINE
  /DELIMITERS=";"
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=propertySituationIdf F9
divCad F5
section A1
primaryNumber F4
bisNumber F2
exponentLetter A1
exponentNumber F2
partNumber A5
capakey A17
order F2
nature F3
descriptPrivate A50
block A1
floor F2
floorSituation A50
crossDetail A36
matUtil A9
notTaxedMatUtil A2
nisCom F5
street_situation A100
street_translation F1
street_code F5
number A20
polWa A7
surfaceNotTaxable F6
surfaceTaxable F7
surfaceVerif A1
constructionYear F4
soilIndex F1
soilRent A1
cadastralIncomePerSurface F2
cadastralIncomePerSurfaceOtherDi F1
numberCadastralIncome F1
charCadastralIncome A1
cadastralIncome F8
dateEndExoneration A10
decrete F3
constructionIndication F3
constructionType A1
floorNumberAboveground F2
garret F1
physModYear F4
constructionQuality A1
garageNumber F3
centralHeating F1
bathroomNumber F3
housingUnitNumber F3
placeNumber F4
builtSurface F5
usedSurface F5
dateSituation A8.
CACHE.
EXECUTE.
DATASET NAME parcel WINDOW=FRONT.

SAVE OUTFILE='' + basismap + '\basisbestand_parcel.sav'
  /COMPRESSED.
