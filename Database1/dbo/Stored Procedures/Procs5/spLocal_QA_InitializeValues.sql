
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_QA_InitializeValues]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Ketki Pophali (Capgemini)
Date			:	2019-05-23
Version		:	3.1.0
Purpose		: 	FO-03488: App version entry in stored procedures using Appversions table
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-23
Version		:	3.0.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					
					Four parameters were removed (@vcrPad, @vcrPackage, @vcrCase and @vcrGMP).
					They were used to retrieve 'Pad', 'Package', 'Case' and 'GMP' texts from
					Local_PG_Translations table, and returned to spLocal_QA_FireEvents.
					With Reestablish modifications, first, this table is no longer used, and 
					secondly, spLocal_QA_FireEvents is now using splocal_QA_GetSampleNumber
					to retrieve the attribute type.
-------------------------------------------------------------------------------------------------
Altered by 	Marc Charest, Solutions et Technologies Industrielles inc.
Date		2004-09-23
Version 	2.2.0
Purpose		'CASE' --> 'CASEATTR', 'PACKAGE' -> 'PACKAGEATTR'.
---------------------------------------------------------------------------------------------------------------------------------------
Altered by 	Marc Charest, Solutions et Technologies Industrielles inc.
Date		2004-08-16
Version 	2.1.0
Purpose		The @vcrPad, @vcrPackage and @vcrCase outputs are back in business.
---------------------------------------------------------------------------------------------------------------------------------------
Altered by 	Marc Charest, Solutions et Technologies Industrielles inc.
Date		2004-07-28
Version 	2.0.1
Purpose		Fix bug with @dtmTimestamp2 selection (see for '2.0.1 bug fix' comment)
---------------------------------------------------------------------------------------------------------------------------------------
Altered by 	Marc Charest, Solutions et Technologies Industrielles inc.
Date		2004-06-18
Version 	2.0.0
Purpose		The @vcrPad, @vcrPackage and @vcrCase outputs are now replaced with @vcrLocal and @vcrGlobal outputs.
		Need this change since Attribute groups might be named differently from a line to another.
---------------------------------------------------------------------------------------------------------------------------------------
Created by 	Marc Charest, Solutions et Technologies Industrielles inc.
Date		2003-11-14
Version 	1.0.0
Purpose		Gets all needed infos before looping within spLocal_QA_FireEvents SP. That makes spLocal_QA_FireEvents shorter.
		Returns all needed infos before looping.
		Called within spLocal_QA_FireEvents SP.
-------------------------------------------------------------------------------------------------------------------------------------*/
@intPUID 				int,
@dtmTimestamp			datetime,
@intVarIDTC				int,		--Var ID of the 'Test Completed' variable
@vcrEIName 				varchar(25),
@vcrEIName2 			varchar(30),
@vcrEITime 				varchar(25),
@vcrEIVarID 			varchar(25),
@vcrEIFail				varchar(25),
@vcrEIType 				varchar(25),

-- Parameters removed from V3.0.0 (No longer used with Reestablish modifications)
--b16-Aug-04
--@vcrPad					varchar(30) OUTPUT,	--Translated text
--@vcrPackage				varchar(30) OUTPUT,	--Translated text
--@vcrCase					varchar(30) OUTPUT,	--Translated text
--e16-Aug-04
--@vcrGMP					varchar(30) OUTPUT,	--Translated text
---------------------------------

@intRSUserID			int OUTPUT,				--Result set user ID
@intPUIDDev				int OUTPUT,				--Prod units ID of the Deviation
@intIsTCChecked		int OUTPUT,				--Is 'Test Completed' variable checked ?
@intVarIDName 			int OUTPUT,
@intVarIDName2 		int OUTPUT,
@intVarIDTime 			int OUTPUT,
@intVarIDId 			int OUTPUT,
@intVarIDFail 			int OUTPUT,
@intVarIDType 			int OUTPUT,
@intSheetID				int OUTPUT,
@dtmTimestamp1			datetime OUTPUT,
@intColCount			int OUTPUT,
@intSecond				int OUTPUT

AS
SET NOCOUNT ON

Declare
--@intActiveLanguageID	int,
@intPLID					int,
@vcrTestCompleted		varchar(10),	--Value of the 'Test Completed' variable
@dtmTimestamp2			datetime
--b16-Aug-04
--@vcrLocalText 		varchar(50),	
--@vcrGlobalText 		varchar(50)
--e16-Aug-04

-- Removed from V3.0.0 -------------------------------------------------------------------
----Get the translated text and the active language
--select @intActiveLanguageID = language_id from dbo.Local_PG_Languages where is_active = 1
--
----b16-Aug-04
--select @vcrPad = translated_text from dbo.Local_PG_Translations where language_id = @intActiveLanguageID and global_text = 'PRODUCTATTR'
--select @vcrPackage = translated_text from dbo.Local_PG_Translations where language_id = @intActiveLanguageID and global_text = 'PACKAGEATTR'
--select @vcrCase = translated_text from dbo.Local_PG_Translations where language_id = @intActiveLanguageID and global_text = 'CASEATTR'
----b16-Aug-04
--select @vcrGMP = translated_text from dbo.Local_PG_Translations where language_id = @intActiveLanguageID and global_text = 'GMP'
------------------------------------------------------------------------------------------

--get the user id for result_set
select @intRSUserID = user_id from dbo.users_base WITH(NOLOCK) where username = 'QualitySystem'

--Get the proLine id
select @intPLID = pl_id from dbo.prod_units_base WITH(NOLOCK) where pu_id = @intPUID

select @intPUIDDev = p.pu_id from dbo.prod_units_base p WITH(NOLOCK) inner join dbo.variables_base v WITH(NOLOCK) on v.pu_id = p.pu_id where p.PL_id = @intPLID and v.extended_info = @vcrEIName

--Verify if the Test completed variables is checked
--if not checked, exit the SP
select @vcrTestCompleted = result from dbo.tests WITH(NOLOCK) where result_on = @dtmTimestamp and var_id = @intVarIDTC
if @vcrTestCompleted = '0' or @vcrTestCompleted is null or @vcrTestCompleted =''
	BEGIN
		set @intIsTCChecked = 0
		return
	END
else
	BEGIN
		set @intIsTCChecked = 1
	END

select @dtmTimestamp2 = convert(varchar(30), @dtmTimestamp, 20)
--select @dtmTimestamp2 = left(@dtmTimestamp, 16)	--2.0.1 bug fix

--To retrieve the target var_id and the deviation unit id
select @intVarIDName= var_id from dbo.variables_base WITH(NOLOCK) where extended_info = @vcrEIName and pu_id = @intPUIDDev
select @intVarIDName2= var_id from dbo.variables_base WITH(NOLOCK) where extended_info = @vcrEIName2 and pu_id = @intPUIDDev
select @intVarIDTime= var_id from dbo.variables_base WITH(NOLOCK) where extended_info = @vcrEITime and pu_id = @intPUIDDev
select @intVarIDId= var_id from dbo.variables_base WITH(NOLOCK) where extended_info = @vcrEIVarID and pu_id = @intPUIDDev
select @intVarIDFail= var_id from dbo.variables_base WITH(NOLOCK) where extended_info = @vcrEIFail and pu_id = @intPUIDDev
select @intVarIDType= var_id from dbo.variables_base WITH(NOLOCK) where extended_info = @vcrEIType and pu_id = @intPUIDDev

--find sheet_id
select @intSheetID = sheet_id from dbo.sheet_variables WITH(NOLOCK) where var_id = @intVarIDName

--Verify if there is already column created for this column
select @dtmTimestamp1 = dateadd(mi,1,@dtmTimestamp2)

select @intColCount = count(result_on) from dbo.sheet_columns WITH(NOLOCK) where result_on > = @dtmTimestamp2 and result_on < @dtmTimestamp1 and sheet_id = @intSheetID

--Initialize the number of second to add to the timestamp
select @intSecond = 0

SET NOCOUNT OFF


