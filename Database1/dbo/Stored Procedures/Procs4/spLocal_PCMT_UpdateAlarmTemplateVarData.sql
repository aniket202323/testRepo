﻿
CREATE PROCEDURE [dbo].[spLocal_PCMT_UpdateAlarmTemplateVarData]
/*
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_UpdateAlarmTemplateVarData
Author:					Marc Charest(STI)
Date Created:			2009-06-02
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
===============================================================================================================
This SP gets and saves sheet_variables data.
When @ProcessFlag = 0, then SP only shows differences between the primary sheet and the secondary sheet(s)
When @ProcessFlag = 1, then SP updates all primary and secondary sheet(s).


Called by:  			PCMT (VBA modules)
	
Revision	Date			Who									What
========	===========	==========================		===============================================================



spLocal_PCMT_GetPlantModelUDP 1, 1
*/


--PARAMETERS
@Titles					VARCHAR(8000),				--sequence of order and title
@PrimarySheetID		INT,							--primary sheet id 
@PrimaryLineID			INT,							--primary line id
@SecondaryIDs			VARCHAR(8000),				--all other sheet ids
@ProcessFlag			INT,							--0 means we only show the messages
															--1 means we process with updating the sheets
@DspTplFlag				INT,							--0 means we are searching for Autolog variables
															--1 means we are searching for Alarm View variables
@VarIDs01				VARCHAR(8000),				--sequence of order and variable id
@VarIDs02				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs03				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs04				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs05				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs06				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs07				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs08				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs09				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs10				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs11				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs12				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs13				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs14				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs15				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs16				VARCHAR(8000) = NULL,	--sequence of order and variable id
@VarIDs17				VARCHAR(8000) = NULL		--sequence of order and variable id


AS

SET NOCOUNT ON


DECLARE
--Looping variables
@SheetCount				INT,
@LoopCounter			INT,
@Sheet_Id				INT,
@Sheet_Desc				VARCHAR(255),
@PL_Id					INT,
@PL_Desc					VARCHAR(255),
@PU_Desc					VARCHAR(255),
@Sheet_Type_Id			INT,
--Other variables
@PrimarySheetDesc		VARCHAR(255),
@PrimaryLineDesc		VARCHAR(255),
@NbrOfChanges			INT				--Number of message(s) where 'added' or 'removed'

/*
SET @ProcessFlag		= 0
SET @Titles				= '1[FLD]Titre'
SET @VarIDs01				= '2[FLD]10615[REC]3[FLD]10611[REC]4[FLD]10616[REC]5[FLD]10617'
SET @PrimarySheetID	= 365
SET @PrimaryLineID	= 52
SET @SecondaryIDs 	= '366[FLD]53'

DROP TABLE #Titles
DROP TABLE #Variables
DROP TABLE #SecondaryIDs
RETURN

*/

--Sub information to build @SheetVariables
CREATE TABLE #Titles(
	Item_Id				INT,
	Title_Order			INT,
	Title_Desc			VARCHAR(255)
)

--Sub information to build @SheetVariables
CREATE TABLE #Variables(
	Item					INT IDENTITY,
	Item_Id				INT,
	Var_Order			INT,
	Var_Id				INT
)

--All sheet id where we want to replicate primary display
CREATE TABLE #SecondaryIDs(
	Item_Id				INT,
	Sheet_Id				INT,
	PL_Id					INT
)

--This table contains what we want to be the primary display
DECLARE @SheetVariables TABLE(
	Var_Id				INT,
	Var_Order			INT,
	Title					VARCHAR(255)
)

--This table contains what we want to be the primary display (with more information)
DECLARE @PrimaryDisplay TABLE(
	Item_Id				INT IDENTITY,
	Item_Desc			VARCHAR(255),
	PU_Desc				VARCHAR(255),
	PU_Desc_Short		VARCHAR(255),
	PL_Desc				VARCHAR(255),
	Sheet_Id				INT,
	Var_Id				INT
)

--Actual secondary display
DECLARE @SecondaryDisplay TABLE(
	Item_Id				INT IDENTITY,
	Item_Desc			VARCHAR(255),
	PU_Desc				VARCHAR(255),
	PU_Desc_Short		VARCHAR(255),
	PL_Desc				VARCHAR(255),
	Sheet_Id				INT,
	Var_Id				INT
)

--Messages on what we are about to do
DECLARE @Messages TABLE(
	Item_Id				INT IDENTITY,
	Item_Desc			VARCHAR(255),
	PU_Desc				VARCHAR(255),
	PL_Desc				VARCHAR(255),
	Message				Varchar(255),
	Var_Id				INT,
	Sheet_Id				INT
)

--Temporary table to store secondary items in order to get the right order
CREATE TABLE #TempSheetVariables(
	Var_Order			INT IDENTITY,
	Sheet_Id				INT,
	Var_Id				INT,
	Title					VARCHAR(255)
)


SET @Titles = ISNULL(@Titles, '')
SET @SecondaryIDs = ISNULL(@SecondaryIDs, '')

--Getting primary line description and sheet desc
SET @PrimaryLineDesc = (SELECT PL_Desc FROM dbo.Prod_Lines WHERE PL_Id = @PrimaryLineID)
SET @PrimarySheetDesc = (Select AT_Desc FROM dbo.Alarm_Templates WHERE AT_Id = @PrimarySheetID)
	
--Building @SheetVariables
IF LEN(@Titles) > 0 BEGIN
	INSERT #Titles(Item_Id, Title_Order, Title_Desc)
	EXECUTE spLocal_PCMT_ParseString @Titles, '[FLD]', '[REC]', 'INT', 'VARCHAR(255)'
END

IF @VarIDs01 IS NOT NULL AND LEN(@VarIDs01) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs01, 'F', 'R', 'INT', 'INT'
END

IF @VarIDs02 IS NOT NULL AND LEN(@VarIDs02) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs02, 'F', 'R', 'INT', 'INT'
END

IF @VarIDs03 IS NOT NULL AND LEN(@VarIDs03) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs03, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs04 IS NOT NULL AND LEN(@VarIDs04) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs04, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs05 IS NOT NULL AND LEN(@VarIDs05) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs05, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs06 IS NOT NULL AND LEN(@VarIDs06) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs06, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs07 IS NOT NULL AND LEN(@VarIDs07) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs07, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs08 IS NOT NULL AND LEN(@VarIDs08) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs08, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs09 IS NOT NULL AND LEN(@VarIDs09) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs09, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs10 IS NOT NULL AND LEN(@VarIDs10) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs10, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs11 IS NOT NULL AND LEN(@VarIDs11) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs11, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs12 IS NOT NULL AND LEN(@VarIDs12) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs12, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs13 IS NOT NULL AND LEN(@VarIDs13) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs13, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs14 IS NOT NULL AND LEN(@VarIDs14) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs14, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs15 IS NOT NULL AND LEN(@VarIDs15) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs15, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs16 IS NOT NULL AND LEN(@VarIDs16) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs16, 'F', 'R', 'INT', 'INT'
END
IF @VarIDs17 IS NOT NULL AND LEN(@VarIDs17) > 0 BEGIN
	INSERT #Variables(Item_Id, Var_Order, Var_Id)
	EXECUTE spLocal_PCMT_ParseString @VarIDs17, 'F', 'R', 'INT', 'INT'
END
	
INSERT @SheetVariables (Var_Order, Title)
SELECT Title_Order, Title_Desc FROM #Titles
INSERT @SheetVariables (Var_Order, Var_Id)
SELECT Var_Order, Var_Id FROM #Variables

--Building primary display information table
INSERT @PrimaryDisplay (Item_Desc, PU_Desc, PU_Desc_Short, PL_Desc, Sheet_Id, Var_Id)
SELECT
	CASE WHEN SV.Var_Id IS NULL THEN Title ELSE Var_Desc END,
	PU_Desc,
	REPLACE(PU_Desc, PL_Desc, ''),
	PL_Desc,
	@PrimarySheetID,
	V.Var_Id
FROM
	@SheetVariables SV
	LEFT JOIN dbo.Variables V ON (SV.Var_Id = V.Var_Id)
	LEFT JOIN dbo.Prod_Units PU ON (PU.PU_Id = V.PU_Id)
	LEFT JOIN dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id)
ORDER BY
	SV.Var_Order

--Updating primary display
IF @ProcessFlag = 1 BEGIN
	
	DELETE FROM dbo.Sheet_Variables WHERE Sheet_Id = @PrimarySheetID
	INSERT dbo.Sheet_Variables (Sheet_Id, Var_Id, Var_Order, Title)
	SELECT 
		P.Sheet_Id, V.Var_Id, P.Item_Id, CASE WHEN P.PU_Desc IS NULL THEN Item_Desc ELSE NULL END AS [Title] 
	FROM 
		@PrimaryDisplay P
		LEFT JOIN dbo.Prod_Lines PL ON (P.PL_Desc = PL.PL_Desc)
		LEFT JOIN dbo.Prod_Units PU ON (PU.PL_Id = PL.PL_Id AND PU.PU_Desc = P.PU_Desc)
		LEFT JOIN dbo.Variables V ON (V.PU_Id = PU.PU_Id AND V.Var_Desc = Item_Desc)
	ORDER BY 
		Item_Id

END


--Getting all secondary IDs
IF LEN(@SecondaryIDs) > 0 BEGIN
	INSERT #SecondaryIDs(Item_Id, Sheet_Id, PL_Id)
	EXECUTE spLocal_PCMT_ParseString @SecondaryIDs, '[FLD]', '[REC]', 'INT', 'INT'
END


------------------------------------------
-- Building messages for model template --
------------------------------------------
--Variables added to model template
INSERT @Messages (Item_Desc, PU_Desc, PL_Desc, Message, Var_Id, Sheet_Id)
SELECT 
	P.Item_Desc, P.PU_Desc, P.PL_Desc, 'Variable will be added to template [' + @PrimarySheetDesc + ']', Var_Id, P.Sheet_Id
FROM 
	@PrimaryDisplay P
WHERE
	(Var_Id NOT IN (SELECT Var_Id FROM dbo.Alarm_Template_Var_Data WHERE AT_Id = @PrimarySheetID AND Var_Id IS NOT NULL)
	 AND Var_Id IS NOT NULL)

--Variables removed from model template
INSERT @Messages (Item_Desc, PU_Desc, PL_Desc, Message, Var_Id, Sheet_Id)
SELECT 
	V.Var_Desc,
	PU.PU_Desc,
	PL.PL_Desc,
	'Variable will be removed from template [' + @PrimarySheetDesc + ']',
	SV.Var_Id,
	@PrimarySheetID
FROM
	dbo.Alarm_Template_Var_Data SV
	LEFT JOIN dbo.Variables V ON (SV.Var_Id = V.Var_Id)
	LEFT JOIN dbo.Prod_Units PU ON (V.PU_Id = PU.PU_Id)
	LEFT JOIN dbo.Prod_Lines PL ON (PU.PL_Id = PL.PL_Id)
WHERE
	SV.Var_Id NOT IN (SELECT Var_Id FROM @PrimaryDisplay)
	AND SV.AT_Id = @PrimarySheetID
	AND SV.ATVRD_Id IS NULL


--Processing each secondary display
SET @SheetCount = (SELECT COUNT(1) FROM #SecondaryIDs)
SET @LoopCounter = 1
SET @Sheet_Id = (SELECT Sheet_Id FROM #SecondaryIDs WHERE Item_Id = @LoopCounter)
SET @Sheet_Desc = (SELECT AT_Desc FROM dbo.Alarm_Templates WHERE AT_Id = @Sheet_Id)
SET @PL_Id = (SELECT PL_Id FROM #SecondaryIDs WHERE Item_Id = @LoopCounter)
SET @PL_Desc = (SELECT PL_Desc FROM dbo.Prod_Lines WHERE PL_Id = @PL_Id)

WHILE @LoopCounter <= @SheetCount BEGIN

	--Building secondary display information table
	INSERT @SecondaryDisplay (Item_Desc, PU_Desc, PU_Desc_Short, PL_Desc, Sheet_Id, Var_Id)
	SELECT
		Var_Desc,
		PU_Desc,
		REPLACE(PU_Desc, PL_Desc, ''),
		PL_Desc,
		@Sheet_Id,
		V.Var_Id
	FROM
		dbo.Alarm_Template_Var_Data SV
		LEFT JOIN dbo.Variables V ON (SV.Var_Id = V.Var_Id)
		LEFT JOIN dbo.Prod_Units PU ON (PU.PU_Id = V.PU_Id)
		LEFT JOIN dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id)
		LEFT JOIN dbo.Alarm_Templates S ON (SV.AT_Id = S.AT_Id)
	WHERE
		SV.AT_Id = @Sheet_Id
		AND SV.ATVRD_Id IS NULL
	--ORDER BY
		--SV.Var_Order

	SET @PU_Desc = (SELECT TOP 1 PU_Desc FROM @SecondaryDisplay)

	----------------------------------------------
	-- Building messages for secondary template --
	----------------------------------------------
	IF @ProcessFlag = 0 BEGIN
	
		--Variables that are only on the secondary line display
		INSERT @Messages (Item_Desc, PU_Desc, PL_Desc, Message, Var_Id, Sheet_Id)
		SELECT 
			S.Item_Desc, S.PU_Desc, S.PL_Desc, 'Variable will be removed from template [' + @Sheet_Desc + ']', S.Var_Id, S.Sheet_Id
		FROM 
			@SecondaryDisplay S
		WHERE
			NOT EXISTS (SELECT * FROM @PrimaryDisplay WHERE PU_Desc_Short = S.PU_Desc_Short AND Item_Desc = S.Item_Desc)
			AND S.PU_Desc IS NOT NULL	

		--Variables that are on the primary line display but not on the secondary line
		INSERT @Messages (Item_Desc, PU_Desc, PL_Desc, Message)
		SELECT 
			P.Item_Desc, P.PU_Desc, P.PL_Desc, 'Missing on line [' + @PL_Desc + ']' 
			--P.Item_Desc, P.PU_Desc, P.PL_Desc, 'Equivalent not found on line [' + @PL_Desc + ']' 
		FROM 
			@PrimaryDisplay P
		WHERE
			NOT EXISTS (
							SELECT 
								*
							FROM
								dbo.Variables V
								LEFT JOIN dbo.Prod_Units PU ON (PU.PU_Id = V.PU_Id)
								LEFT JOIN dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id)
							WHERE
								PL.PL_Desc = @PL_Desc AND REPLACE(PU_Desc, PL_Desc, '') = P.PU_Desc_Short AND Var_Desc = P.Item_Desc)
			AND P.PU_Desc IS NOT NULL
	
		--Variables that are on the primary line display, on secondary line, but not on secondary line display
		INSERT @Messages (Item_Desc, PU_Desc, PL_Desc, Message, P.Var_Id, Sheet_Id)
		SELECT 
			P.Item_Desc, @PL_Desc + P.PU_Desc_Short, @PL_Desc, 'Variable will be added to template [' + @Sheet_Desc + ']', Var_Id, @Sheet_Id  
			--P.Item_Desc, P.PU_Desc, P.PL_Desc, 'Equivalent found on line [' + @PL_Desc + ']. Variable will be added to display [' + @Sheet_Desc + ']'  
		FROM 
			@PrimaryDisplay P
		WHERE
			EXISTS (
							SELECT 
								*
							FROM
								dbo.Variables V
								LEFT JOIN dbo.Prod_Units PU ON (PU.PU_Id = V.PU_Id)
								LEFT JOIN dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id)

							WHERE
								PL.PL_Desc = @PL_Desc 
								AND REPLACE(PU_Desc, PL_Desc, '') = P.PU_Desc_Short 
								AND Var_Desc = P.Item_Desc)

			
			AND NOT EXISTS (SELECT * FROM @SecondaryDisplay WHERE PU_Desc_Short = P.PU_Desc_Short AND Item_Desc = P.Item_Desc)
			AND P.PU_Desc IS NOT NULL END


	--Updating secondary display	
	ELSE BEGIN
	
		--Variables that are on the primary line display and also on secondary line or any primary display title
		INSERT #TempSheetVariables (Sheet_Id, Var_Id, Title)
		SELECT 
			@Sheet_Id AS [Sheet_Id], V.Var_Id, CASE WHEN P.PU_Desc IS NULL THEN Item_Desc ELSE NULL END AS [Title]
		FROM 
			@PrimaryDisplay P
			LEFT JOIN dbo.Prod_Lines PL ON (REPLACE(P.PL_Desc, @PrimaryLineDesc, @PL_Desc) = PL.PL_Desc)
			LEFT JOIN dbo.Prod_Units PU ON (PU.PL_Id = PL.PL_Id AND PU.PU_Desc = REPLACE(P.PU_Desc, @PrimaryLineDesc, @PL_Desc))
			LEFT JOIN dbo.Variables V ON (V.PU_Id = PU.PU_Id AND V.Var_Desc = Item_Desc)
		WHERE
			(EXISTS (
							SELECT 
								*
							FROM
								dbo.Variables V
								LEFT JOIN dbo.Prod_Units PU ON (PU.PU_Id = V.PU_Id)
								LEFT JOIN dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id)
							WHERE
								PL.PL_Desc = @PL_Desc AND REPLACE(PU_Desc, PL_Desc, '') = P.PU_Desc_Short AND Var_Desc = P.Item_Desc)
		
			AND P.PU_Desc IS NOT NULL)
			OR P.PU_Desc IS NULL
		ORDER BY
			P.Item_Id














		DELETE FROM dbo.Sheet_Variables WHERE Sheet_Id = @Sheet_Id
		INSERT dbo.Sheet_Variables (Sheet_Id, Var_Id, Var_Order, Title)
		SELECT
			Sheet_Id, Var_Id, Var_Order, Title
		FROM
			#TempSheetVariables
		ORDER BY
			Var_Order

	END

	SET @LoopCounter = @LoopCounter + 1
	SET @Sheet_Id = (SELECT Sheet_Id FROM #SecondaryIDs WHERE Item_Id = @LoopCounter)
	SET @Sheet_Desc = (SELECT AT_Desc FROM dbo.Alarm_Templates WHERE AT_Id = @Sheet_Id)
	SET @PL_Id = (SELECT PL_Id FROM #SecondaryIDs WHERE Item_Id = @LoopCounter)
	SET @PL_Desc = (SELECT PL_Desc FROM dbo.Prod_Lines WHERE PL_Id = @PL_Id)


	DELETE FROM @SecondaryDisplay
	TRUNCATE TABLE #TempSheetVariables

END --WHILE

--Showing messages
IF @ProcessFlag = 0 BEGIN

	SET @NbrOfChanges = (SELECT COUNT(1) FROM @Messages WHERE Message LIKE '%removed%' OR Message LIKE '%added%')

	SELECT 
		Item_Id, Item_Desc AS [Variable], PU_Desc AS [Production Unit], PL_Desc AS [Production Line], Message, @NbrOfChanges AS [Number of Changes], Var_Id, Sheet_Id
	FROM 
		@Messages 
	ORDER BY 
		Item_Id

END

DROP TABLE #Titles
DROP TABLE #Variables
DROP TABLE #SecondaryIDs
DROP TABLE #TempSheetVariables






SET NOCOUNT OFF





















