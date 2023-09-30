
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PQ_QV_NextStep_B]
/*
-------------------------------------------------------------------------------------------------------
Stored Procedure		:		spLocal_QV_NextStep_B
Author					:		Ugo Lapierre (System Technologies for Industry Inc)
Date Created			:		?
SP Type					:		
Editor Tab Spacing	:		3

Description:
===========
Looks at the rule violated and the Variable type, then gets the value 
			from the correct Next_ stored procedure.

CALLED BY				:  Proficy Calculation (QV_Next Step.)

Revision	Date			Who						What
========	====			===						====
4.1.0           2019-05-16      Ketki Pophali(Capgemini)       FO-03488: App version entry in stored procedures using Appversions table
4.0.0		2015-10-6	Fernando Rio			Make the calculation to send @Rp when the Reevaluation status is confirmed.
												Fix missed ELSE statement that makes the calculation not to work properly.

3.0.0		2005-05-19	Vincent Rouleau, STI	Add processing for the Core Hang Time variable

2.0.0		2005-10-25	Linda Hudon, STI		Redesign of SP (Compliant with Proficy 3 and 4).
														Added [dbo] template when referencing objects.
														Use now the standard proficy language table.
									
														Prompt number used :
														80000164 	Samples Missing
														80000135 	Single Point OOS
														80000134 	Subgroup Average OOC
														80000102 	3 Subgroup OOW
														80000235 	7 Subgroup OOT

1.4.0		2005-03-30	Ugo lapierre, STI		Allow diag variable to be OOS and OOC instead of only OOC

1.3.0		2004-04-15	Marc Charest, STI		Some changes for Rule of D.
														(see all b2004-04-15, e2004-04-15 and be2004-04-15 comments)

1.2.1		2003-07-01	Tim Rogers, PG			Account for EQP set up checks

1.2.0		2001-11-01	Ugo Lapierre, STI		use Local_PG_Translations instead of PG_Translations
														use Local_PG_Languages instead of PG_Languages

1.1.0		2001-11-05	Ugo Lapierre, STI		Make SP use Local_PG_Translations table instead of hardcoding text.
														variables added : @Active_Lang_id,@Open,@Return,@RP,@OOSx,@OOCx,@OOWx
														

--3-04-2016	JSJ	Removed reference to GBDB
--				Removed app version reference
--				Checked for if exists														
---------------------------------------------------------------------------------------------------------------------------------------
*/
@OutputValue 		varchar(25) OUTPUT,
@Type_id 			int,
@Rule_id 			int,
@OOS_id 				int,
@OOC_id 				int,
@OOW_id 				int,
@Temps 				varchar(30),
@SETUP_id 			int,
@CHT_NS				varchar(30)

AS
SET NOCOUNT ON

DECLARE
@Type 				varchar(30),
@Rule 				varchar(30),
@OOS 					varchar(30),
@OOC 					varchar(30),
@OOW 					varchar(30),
@OOC2 				varchar(30),
@Setup 				varchar(30),
@Active_Lang_id	int,
@Open					varchar(50),
@RP					varchar(50),
@Return				varchar(50),
@OOSx 				varchar(30),
@OOCx 				varchar(30),
@OOWx 				varchar(30),
@OOTx 				varchar(30),	--bezzz
@CHT					varchar(30)		--vr2006-05-19

SET @Outputvalue = ''

-- Get the Active Language ID
SET @Active_lang_id = (SELECT value FROM [dbo].[Site_Parameters] WITH(NOLOCK) WHERE parm_id = 8)

SELECT @Open = dbo.fnLocal_GetPrompt(@Active_Lang_id, 80000103) --Open
SELECT @RP = dbo.fnLocal_GetPrompt(@Active_Lang_id, 80000157) --Reevaluate Product
SELECT @Return = dbo.fnLocal_GetPrompt(@Active_Lang_id, 80000098) --Return to normal Sampling
SELECT @OOSx = dbo.fnLocal_GetPrompt(@Active_Lang_id, 80000135) --Single Point OOS
SELECT @OOCx = dbo.fnLocal_GetPrompt(@Active_Lang_id, 80000134) --Subgroup Average OOC
SELECT @OOWx = dbo.fnLocal_GetPrompt(@Active_Lang_id, 80000102) --3 Subgroup OOW
SELECT @OOTx = dbo.fnLocal_GetPrompt(@Active_Lang_id, 80000235) --7 Subgroup OOT

--VR 2006-05-19 Get the prompts for the CHT
SET @CHT = dbo.fnLocal_GetPrompt(@Active_Lang_id, 80000255)	--CHT

SET @OutputValue = @Open

--check the variables type
SET @Type = (SELECT result FROM [dbo].[Tests] WITH(NOLOCK) WHERE result_on = @temps AND var_id = @type_id)

--check the violated rule
SET @rule = (SELECT result FROM [dbo].[Tests] WITH(NOLOCK) WHERE result_on = @temps AND var_id = @rule_id)

IF @type LIKE '%PQM%' OR @type LIKE '%MON%' OR @type LIKE '%MA%'
BEGIN
	
	--if single point out of specs
	IF @rule = @OOSx
	BEGIN
		SET @OOS = (SELECT result FROM [dbo].[Tests] WITH(NOLOCK) WHERE result_on = @temps AND var_id = @OOS_id)
		IF @OOS = @RP
		BEGIN
			SET @outputvalue = @RP
		END
		ELSE
		BEGIN
		   SET @outputvalue = @OOS
		END
		RETURN
	END

	--if subgroup out of control
	IF @rule = @OOCx
	BEGIN
		SET @OOC = (SELECT result FROM [dbo].[Tests] WITH(NOLOCK) WHERE result_on = @temps AND var_id = @OOC_id)
		IF @OOC = @RP
		BEGIN
			SET @outputvalue = @RP
		END
		ELSE
		BEGIN
			SET @outputvalue=@OOC
		END
		RETURN
	END
		 
	--if 2 out of 3 subgroups out of warning or 7 consecutive subgroups out of target
	IF @rule = @OOWx OR @rule = @OOTx	--bezzz
	BEGIN
		SET @OOW = (SELECT result FROM [dbo].[Tests] WITH(NOLOCK) WHERE result_on = @temps AND var_id = @OOW_id)
		IF @OOW = @RP
		BEGIN
			SET @outputvalue = @RP
		END
		ELSE
		BEGIN
			SET @outputvalue=@OOW
		END
		RETURN
	END

END
ELSE 
BEGIN
	IF @Type = @CHT		--If the type is CHT, we process differently
	BEGIN
		IF @CHT_NS = @RP
		BEGIN
			SET @outputvalue = @RP
		END
		ELSE
		BEGIN
		   SET @outputvalue = @CHT_NS
		END
	END
END

IF @type LIKE '%SET%' OR @type LIKE '%EQP%'
BEGIN
	SET @setup = (SELECT result FROM [dbo].[Tests] WITH(NOLOCK) WHERE result_on = @temps AND var_id = @setup_id)
	IF @setup = @RP
	BEGIN
		SET @outputvalue = @RP
	END
	ELSE
	BEGIN
		SET @outputvalue=@setup
	END
	RETURN
END


IF @type LIKE '%DIA%'
BEGIN
	--if subgroup out of control
	IF (@rule =@OOCx OR @rule =@OOSx)
	BEGIN
		SET @OOW = (SELECT result FROM [dbo].[Tests] WITH(NOLOCK) WHERE result_on = @temps AND var_id = @OOW_id)
		IF @OOW = @RP
		BEGIN
			SET @outputvalue = @RP
		END
		ELSE
		BEGIN
		   SET @outputvalue=@OOW
		END
		RETURN
	END
END

SET NOCOUNT OFF
