use atal;
go

-- importovat soubor PRIKAZ.FS

-- temp tabulka pro prikazy
IF OBJECT_ID('dbo.temp_prikaz','U') IS NOT NULL DROP TABLE dbo.temp_prikaz
CREATE TABLE dbo.temp_prikaz
(
	LineFeed varchar(100)
);
GO

BULK INSERT dbo.temp_prikaz
   FROM '\\dpserver05\users$\data\atal\fs\PRIKAZ.fs'  
   WITH   
      (  
         CODEPAGE = '1250',
         ROWTERMINATOR ='\n'  
      );

/*SELECT * FROM dbo.temp_prikaz*/

-- struktura pro prikazy
IF OBJECT_ID('dbo.Prikaz','U') IS NOT NULL DROP TABLE dbo.Prikaz
CREATE TABLE dbo.Prikaz
(
	Nazev_sluzby varchar(10)
	,Typ_dne varchar(10)
	,Datum_platnosti varchar(50)
	,Linka varchar(10)
	,Nazev_sluzby2 varchar(10)
	,Poradi_zastavky int
	,Druh_provozu varchar(10)
	,Cislo_zastavky int
	,Cislo_oznacniku int
	,Cas_prijezdu int
	,Cas_odjezdu int
	,Kod_cile1 varchar(10)
	,Kod_cile2 varchar(10)
	,c1 varchar(10)
	,c2 varchar(10)
	,l1 varchar(10)
	,c3 varchar(10)
	,c4 varchar(10)
	,l2 varchar(10)
	,Temp varchar(50)
);
GO

-- prochazet temp a vkladat 
DECLARE @radek varchar(100)
DECLARE @sluzba varchar(100)
DECLARE @den varchar(10)
DECLARE @platnost varchar(50)
DECLARE @linka varchar(10)
DECLARE @sluzba2 varchar(10)
DECLARE @poradi varchar(10)
DECLARE @provoz varchar(10)
DECLARE @zastavka varchar(10)
DECLARE @oznacnik varchar(10)
DECLARE @prijezd varchar(10)
DECLARE @odjezd varchar(10)
DECLARE @cil1 varchar(10)
DECLARE @cil2 varchar(10)
DECLARE @c1 varchar(10)
DECLARE @c2 varchar(10)
DECLARE @c3 varchar(10)
DECLARE @c4 varchar(10)
DECLARE @l1 varchar(10)
DECLARE @l2 varchar(10)
DECLARE @zbytek varchar(50)

DECLARE C CURSOR FOR SELECT LineFeed FROM dbo.temp_prikaz

OPEN C

FETCH NEXT FROM C INTO @radek
WHILE @@FETCH_STATUS = 0
BEGIN
	IF LEFT(@radek, 1) = '@'
		BEGIN
			--PRINT @radek + ' contains @'
			SET @sluzba = REPLACE(dbo.SPLIT_COLUMNS(@radek, 1, '|'),'@','')
			SET @den = dbo.SPLIT_COLUMNS(@radek, 2, '|') 
			SET @platnost = REPLACE(@radek, '@' + @sluzba + '|' + @den + '|', '') 
		END
	ELSE
		BEGIN
			--PRINT @radek + ' values'
			SET @linka = dbo.SPLIT_COLUMNS(@radek, 1, '|')
			SET @sluzba2 = dbo.SPLIT_COLUMNS(@radek, 2, '|')
			SET @poradi = dbo.SPLIT_COLUMNS(@radek, 3, '|')
			SET @provoz = dbo.SPLIT_COLUMNS(@radek, 4, '|')
			SET @zastavka = dbo.SPLIT_COLUMNS(@radek, 5, '|')
			SET @oznacnik = dbo.SPLIT_COLUMNS(@radek, 6, '|')
			SET @prijezd = dbo.SPLIT_COLUMNS(@radek, 7, '|')
			SET @odjezd = dbo.SPLIT_COLUMNS(@radek, 8, '|')
			SET @cil1 = dbo.SPLIT_COLUMNS(@radek, 9, '|')
			SET @cil2 = dbo.SPLIT_COLUMNS(@radek, 10, '|')
			SET @c1 = dbo.SPLIT_COLUMNS(@radek, 11, '|')
			SET @c2 = dbo.SPLIT_COLUMNS(@radek, 12, '|')
			SET @l1 = dbo.SPLIT_COLUMNS(@radek, 13, '|')
			SET @c3 = dbo.SPLIT_COLUMNS(@radek, 14, '|')
			SET @c4 = dbo.SPLIT_COLUMNS(@radek, 15, '|')
			SET @l2 = dbo.SPLIT_COLUMNS(@radek, 16, '|')
			SET @zbytek = REPLACE(@radek, @linka + '|' + @sluzba2 + '|' + @poradi + '|' + @provoz + '|' + @zastavka + '|' + @oznacnik + '|' + @prijezd + '|' + @odjezd + '|' + @cil1 + '|' + @cil2 + '|' + @c1 + '|' + @c2 + '|' + @l1 + '|' + @c3 + '|' + @c4 + '|' + @l2 + '|', '') 
			INSERT INTO dbo.Prikaz (Nazev_sluzby, Typ_dne, Datum_platnosti, Linka, Nazev_sluzby2, Poradi_zastavky, Druh_provozu, Cislo_zastavky, Cislo_oznacniku, Cas_prijezdu, Cas_odjezdu, Kod_cile1, Kod_cile2, c1, c2, l1, c3, c4, l2, Temp) 
			VALUES (@sluzba, @den, @platnost, @linka, @sluzba2, @poradi, @provoz, @zastavka, @oznacnik, @prijezd, @odjezd, @cil1, @cil2, @c1, @c2, @l1, @c3, @c4, @l2, @zbytek)
			--PRINT @linka + @licence + @provoz + @platnost + @poradi + @zastavka + @oznacnik
		END
	FETCH NEXT FROM C INTO @radek
END

CLOSE C
DEALLOCATE C
GO

-- vlozit views
IF OBJECT_ID('dbo.PrikazStanice','V') IS NOT NULL DROP VIEW dbo.PrikazStanice
GO
CREATE VIEW dbo.PrikazStanice AS
SELECT  TOP (100) PERCENT '999999' AS Vuz_cislo, '999999' AS Kurz, dbo.Prikaz.Linka, 0 AS Smer, dbo.Prikaz.Poradi_zastavky, dbo.C_Stanice.Nazev_zastavky, dbo.C_Stanice.Zkraceny_nazev_zastavky, dbo.Prikaz.Cislo_zastavky, 
            dbo.Prikaz.Cislo_oznacniku, dbo.Prikaz.Druh_provozu, dbo.Prikaz.Cas_prijezdu AS Prijezd, dbo.Prikaz.Cas_odjezdu AS Odjezd, dbo.Prikaz.Kod_cile1, CONVERT(varchar(10), dbo.Prikaz.Nazev_sluzby) AS Nazev_sluzby, dbo.Prikaz.Typ_dne, GETDATE() 
            AS Datum, '00000000' AS Poradi
FROM    dbo.Prikaz LEFT OUTER JOIN
            dbo.C_Stanice ON dbo.Prikaz.Cislo_zastavky = dbo.C_Stanice.Cislo_zastavky AND dbo.Prikaz.Cislo_oznacniku = dbo.C_Stanice.Cislo_oznacniku AND dbo.Prikaz.Druh_provozu = dbo.C_Stanice.Druh_provozu
ORDER BY dbo.Prikaz.Linka, Prijezd
GO

IF OBJECT_ID('dbo.Prikaz15aStanice','V') IS NOT NULL DROP VIEW dbo.Prikaz15aStanice
IF OBJECT_ID('dbo.Prikaz15bStanice','V') IS NOT NULL DROP VIEW dbo.Prikaz15bStanice
GO
/*CREATE VIEW dbo.Prikaz15aStanice AS
SELECT     TOP (100) PERCENT dbo.C_Vozy.Vuz_cislo, dbo.Prikaz.Linka, dbo.C_Vozy.Nazev_sluzby, dbo.C_Stanice.Nazev_zastavky, dbo.Prikaz.Cislo_zastavky, 
                      dbo.Prikaz.Cislo_oznacniku, dbo.Prikaz.Poradi_zastavky, dbo.Prikaz.Typ_dne, dbo.Prikaz.Druh_provozu, dbo.Prikaz.Cas_prijezdu AS Prijezd, 
                      dbo.Prikaz.Cas_odjezdu AS Odjezd, dbo.Prikaz.Kod_cile1
FROM         dbo.Prikaz INNER JOIN
                      dbo.C_Stanice ON dbo.Prikaz.Cislo_zastavky = dbo.C_Stanice.Cislo_zastavky AND dbo.Prikaz.Cislo_oznacniku = dbo.C_Stanice.Cislo_oznacniku AND 
                      dbo.Prikaz.Druh_provozu = dbo.C_Stanice.Druh_provozu INNER JOIN
                      dbo.C_Vozy ON dbo.Prikaz.Nazev_sluzby = dbo.C_Vozy.Nazev_sluzby
GROUP BY dbo.C_Vozy.Vuz_cislo, dbo.Prikaz.Linka, dbo.C_Vozy.Nazev_sluzby, dbo.C_Stanice.Nazev_zastavky, dbo.Prikaz.Cislo_zastavky, dbo.Prikaz.Cislo_oznacniku, 
                      dbo.Prikaz.Poradi_zastavky, dbo.Prikaz.Typ_dne, dbo.Prikaz.Druh_provozu, dbo.Prikaz.Cas_prijezdu, dbo.Prikaz.Cas_odjezdu, dbo.Prikaz.Kod_cile1
HAVING      (dbo.Prikaz.Kod_cile1 = '110')
ORDER BY Prijezd
GO
CREATE VIEW dbo.Prikaz15bStanice AS
SELECT     TOP (100) PERCENT dbo.C_Vozy.Vuz_cislo, dbo.Prikaz.Linka, dbo.C_Vozy.Nazev_sluzby, dbo.C_Stanice.Nazev_zastavky, dbo.Prikaz.Cislo_zastavky, 
                      MAX(dbo.Prikaz.Cislo_oznacniku) AS Cislo_oznacniku, dbo.Prikaz.Poradi_zastavky, dbo.Prikaz.Typ_dne, dbo.Prikaz.Druh_provozu, MAX(dbo.Prikaz.Cas_prijezdu) 
                      AS Prijezd, MAX(dbo.Prikaz.Cas_odjezdu) AS Odjezd, dbo.Prikaz.Kod_cile1
FROM         dbo.Prikaz INNER JOIN
                      dbo.C_Stanice ON dbo.Prikaz.Cislo_zastavky = dbo.C_Stanice.Cislo_zastavky AND dbo.Prikaz.Cislo_oznacniku = dbo.C_Stanice.Cislo_oznacniku AND 
                      dbo.Prikaz.Druh_provozu = dbo.C_Stanice.Druh_provozu INNER JOIN
                      dbo.C_Vozy ON dbo.Prikaz.Nazev_sluzby = dbo.C_Vozy.Nazev_sluzby
GROUP BY dbo.C_Vozy.Vuz_cislo, dbo.Prikaz.Linka, dbo.C_Vozy.Nazev_sluzby, dbo.C_Stanice.Nazev_zastavky, dbo.Prikaz.Cislo_zastavky, dbo.Prikaz.Poradi_zastavky, 
                      dbo.Prikaz.Typ_dne, dbo.Prikaz.Druh_provozu, dbo.Prikaz.Kod_cile1
HAVING      (dbo.Prikaz.Kod_cile1 = '105')
ORDER BY Prijezd
GO*/

IF OBJECT_ID('dbo.Linka15aSmer0Vozovna','V') IS NOT NULL DROP VIEW dbo.Linka15aSmer0Vozovna
IF OBJECT_ID('dbo.Linka15aSmer2','V') IS NOT NULL DROP VIEW dbo.Linka15aSmer2
IF OBJECT_ID('dbo.Linka15aSmer1','V') IS NOT NULL DROP VIEW dbo.Linka15aSmer1
IF OBJECT_ID('dbo.Linka15bSmer2','V') IS NOT NULL DROP VIEW dbo.Linka15bSmer2
IF OBJECT_ID('dbo.Linka15bSmer1','V') IS NOT NULL DROP VIEW dbo.Linka15bSmer1
GO
/*CREATE VIEW dbo.Linka15aSmerVozovna AS
SELECT     TOP (100) PERCENT dbo.C_Vozy.Vuz_cislo, dbo.C_Vozy.Nazev_sluzby AS Kurz, dbo.LinkyStanice.Cislo_linky AS Linka, dbo.LinkyStanice.Smer, 
                      dbo.C_PoradiLokace.Poradi_lokace, dbo.LinkyStanice.Nazev_zastavky, dbo.LinkyStanice.Zkraceny_nazev_zastavky, dbo.LinkyStanice.Cislo_zastavky, 
                      dbo.LinkyStanice.Cislo_oznacniku, dbo.LinkyStanice.Druh_provozu, dbo.LinkyStanice.t0, dbo.LinkyStanice.t8, dbo.LinkyStanice.t3, dbo.LinkyStanice.t4, 
                      dbo.LinkyStanice.t6, dbo.LinkyStanice.Cislo_licence, dbo.LinkyStanice.Platnost, 0 AS Spoj, dbo.Prikaz15aStanice.Prijezd
FROM         dbo.LinkyStanice INNER JOIN
                      dbo.C_Vozy ON dbo.LinkyStanice.Cislo_linky = dbo.C_Vozy.Linka INNER JOIN
                      dbo.C_PoradiLokace ON dbo.LinkyStanice.Poradi = dbo.C_PoradiLokace.Poradi LEFT OUTER JOIN
                      dbo.Prikaz15aStanice ON dbo.LinkyStanice.Cislo_zastavky = dbo.Prikaz15aStanice.Cislo_zastavky AND 
                      dbo.LinkyStanice.Cislo_oznacniku = dbo.Prikaz15aStanice.Cislo_oznacniku
WHERE     (dbo.C_PoradiLokace.Poradi_lokace < 1) AND (dbo.LinkyStanice.Smer = '0')
ORDER BY dbo.LinkyStanice.Cislo_oznacniku DESC
GO
CREATE VIEW dbo.Linka15aSmer2 AS
SELECT     TOP (100) PERCENT dbo.C_Vozy.Vuz_cislo, dbo.C_Vozy.Nazev_sluzby AS Kurz, dbo.LinkyStanice.Cislo_linky AS Linka, dbo.LinkyStanice.Smer + 2 AS Smer, 
                      dbo.C_PoradiLokace.Poradi_lokace, dbo.LinkyStanice.Nazev_zastavky, dbo.LinkyStanice.Zkraceny_nazev_zastavky, dbo.LinkyStanice.Cislo_zastavky, 
                      dbo.LinkyStanice.Cislo_oznacniku, dbo.LinkyStanice.Druh_provozu, dbo.LinkyStanice.t0, dbo.LinkyStanice.t8, dbo.LinkyStanice.t3, dbo.LinkyStanice.t4, 
                      dbo.LinkyStanice.t6, dbo.LinkyStanice.Cislo_licence, dbo.LinkyStanice.Platnost, 525 AS Spoj, dbo.Prikaz15aStanice.Prijezd
FROM         dbo.LinkyStanice INNER JOIN
                      dbo.C_Vozy ON dbo.LinkyStanice.Cislo_linky = dbo.C_Vozy.Linka INNER JOIN
                      dbo.C_PoradiLokace ON dbo.LinkyStanice.Poradi = dbo.C_PoradiLokace.Poradi LEFT OUTER JOIN
                      dbo.Prikaz15aStanice ON dbo.LinkyStanice.Cislo_zastavky = dbo.Prikaz15aStanice.Cislo_zastavky
WHERE     (dbo.LinkyStanice.Smer + 2 = '2') AND (dbo.C_PoradiLokace.Poradi_lokace > 0) AND (dbo.C_PoradiLokace.Linka15a = 1)
ORDER BY dbo.C_PoradiLokace.Poradi_lokace
GO
CREATE VIEW dbo.Linka15aSmer1 AS
SELECT     TOP (100) PERCENT dbo.C_Vozy.Vuz_cislo, dbo.C_Vozy.Nazev_sluzby AS Kurz, dbo.LinkyStanice.Cislo_linky AS Linka, dbo.LinkyStanice.Smer, 
                      dbo.C_PoradiLokace.Poradi_lokace, dbo.LinkyStanice.Nazev_zastavky, dbo.LinkyStanice.Zkraceny_nazev_zastavky, dbo.LinkyStanice.Cislo_zastavky, 
                      dbo.LinkyStanice.Cislo_oznacniku, dbo.LinkyStanice.Druh_provozu, dbo.LinkyStanice.t0, dbo.LinkyStanice.t8, dbo.LinkyStanice.t3, dbo.LinkyStanice.t4, 
                      dbo.LinkyStanice.t6, dbo.LinkyStanice.Cislo_licence, dbo.LinkyStanice.Platnost, 558 AS Spoj, dbo.Prikaz15aStanice.Prijezd
FROM         dbo.LinkyStanice INNER JOIN
                      dbo.C_Vozy ON dbo.LinkyStanice.Cislo_linky = dbo.C_Vozy.Linka INNER JOIN
                      dbo.C_PoradiLokace ON dbo.LinkyStanice.Poradi = dbo.C_PoradiLokace.Poradi LEFT OUTER JOIN
                      dbo.Prikaz15aStanice ON dbo.LinkyStanice.Cislo_zastavky = dbo.Prikaz15aStanice.Cislo_zastavky
WHERE     (dbo.LinkyStanice.Smer = 1) AND (dbo.C_PoradiLokace.Poradi_lokace <> 0) AND (dbo.C_PoradiLokace.Linka15a = 1)
ORDER BY dbo.C_PoradiLokace.Poradi_lokace DESC
GO
CREATE VIEW dbo.Linka15bSmer2 AS
SELECT     TOP (100) PERCENT dbo.C_Vozy.Vuz_cislo, dbo.C_Vozy.Nazev_sluzby AS Kurz, dbo.LinkyStanice.Cislo_linky AS Linka, dbo.LinkyStanice.Smer + 2 AS Smer, 
                      dbo.C_PoradiLokace.Poradi_lokace, dbo.LinkyStanice.Nazev_zastavky, dbo.LinkyStanice.Zkraceny_nazev_zastavky, dbo.LinkyStanice.Cislo_zastavky, 
                      dbo.LinkyStanice.Cislo_oznacniku, dbo.LinkyStanice.Druh_provozu, dbo.LinkyStanice.t0, dbo.LinkyStanice.t8, dbo.LinkyStanice.t3, dbo.LinkyStanice.t4, 
                      dbo.LinkyStanice.t6, dbo.LinkyStanice.Cislo_licence, dbo.LinkyStanice.Platnost, 525 AS Spoj, dbo.Prikaz15bStanice.Prijezd
FROM         dbo.LinkyStanice INNER JOIN
                      dbo.C_Vozy ON dbo.LinkyStanice.Cislo_linky = dbo.C_Vozy.Linka INNER JOIN
                      dbo.C_PoradiLokace ON dbo.LinkyStanice.Poradi = dbo.C_PoradiLokace.Poradi LEFT OUTER JOIN
                      dbo.Prikaz15bStanice ON dbo.LinkyStanice.Cislo_zastavky = dbo.Prikaz15bStanice.Cislo_zastavky
WHERE     (dbo.LinkyStanice.Smer + 2 = '2') AND (dbo.C_PoradiLokace.Poradi_lokace > 0) AND (dbo.C_PoradiLokace.Linka15b = 1)
ORDER BY dbo.C_PoradiLokace.Poradi_lokace
GO
CREATE VIEW dbo.Linka15bSmer1 AS
SELECT     TOP (100) PERCENT dbo.C_Vozy.Vuz_cislo, dbo.C_Vozy.Nazev_sluzby AS Kurz, dbo.LinkyStanice.Cislo_linky AS Linka, dbo.LinkyStanice.Smer, 
                      dbo.C_PoradiLokace.Poradi_lokace, dbo.LinkyStanice.Nazev_zastavky, dbo.LinkyStanice.Zkraceny_nazev_zastavky, dbo.LinkyStanice.Cislo_zastavky, 
                      dbo.LinkyStanice.Cislo_oznacniku, dbo.LinkyStanice.Druh_provozu, dbo.LinkyStanice.t0, dbo.LinkyStanice.t8, dbo.LinkyStanice.t3, dbo.LinkyStanice.t4, 
                      dbo.LinkyStanice.t6, dbo.LinkyStanice.Cislo_licence, dbo.LinkyStanice.Platnost, 558 AS Spoj, dbo.Prikaz15bStanice.Prijezd
FROM         dbo.LinkyStanice INNER JOIN
                      dbo.C_Vozy ON dbo.LinkyStanice.Cislo_linky = dbo.C_Vozy.Linka INNER JOIN
                      dbo.C_PoradiLokace ON dbo.LinkyStanice.Poradi = dbo.C_PoradiLokace.Poradi INNER JOIN
                      dbo.Prikaz15bStanice ON dbo.LinkyStanice.Cislo_zastavky = dbo.Prikaz15bStanice.Cislo_zastavky
WHERE     (dbo.LinkyStanice.Smer = 1) AND (dbo.C_PoradiLokace.Poradi_lokace <> 0) AND (dbo.C_PoradiLokace.Linka15b = 1)
ORDER BY dbo.C_PoradiLokace.Poradi_lokace DESC
GO*/

-- vycistit temp prikaz
IF OBJECT_ID('dbo.temp_prikaz','U') IS NOT NULL DROP TABLE dbo.temp_prikaz
SELECT * FROM dbo.Prikaz