
--=====================================================================================================================
--	This Function will return the App Info such as Min and Max Prompt values for a given App Name
-----------------------------------------------------------------------------------------------------------------------
--	How to execute it: Example
-----------------------------------------------------------------------------------------------------------------------
/*
	 SELECT	*
	 FROM	dbo.fnLocal_SSI_Cmn_GetAppInfo('CETFinishingLine')
*/
-----------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who				What
--	==========	=====		===				====
--	1.0			2011-05-20	Luis Chaves		Original Development
--	1.1			2012-09-06	Renata Piedmont	LIBRARY-236: Added a comment to get the version script added to the sp
--=====================================================================================================================

CREATE FUNCTION[dbo].[fnLocal_SSI_Cmn_GetAppInfo]
(	@p_vchAppName	VARCHAR(25)
)
 RETURNS	@tblAppInfo		TABLE		(
			AppId			INT			,
			AppVersion		VARCHAR(25)	,
			MinPrompt		INT			,
			MaxPrompt		INT			)
AS
BEGIN
	--=================================================================================================================
	--	Define all variables.
	--=================================================================================================================
	--=================================================================================================================
	--	Initialize all variables.  The only items hard-coded within this stored procedure are items that are specific to
	--	this application and are unlikely to be used by any other application.  Acceptable items are Variable Aliases and
	--	Display Option Descriptions.
	--=================================================================================================================
	INSERT INTO	@tblAppInfo	(
				AppId		,
				AppVersion	,
				MinPrompt	,
				MaxPrompt	)
	SELECT		App_Id		AS	[AppId]			,
				App_Version	AS	[AppVersion]	,
				Min_Prompt	AS	[MinPrompt]		,
				Max_Prompt	AS	[MaxPrompt]
	FROM	dbo.AppVersions	WITH(NOLOCK)
	WHERE	App_Name	= @p_vchAppName
	--=================================================================================================================
	-- Finish
	--=================================================================================================================	
	RETURN
END
