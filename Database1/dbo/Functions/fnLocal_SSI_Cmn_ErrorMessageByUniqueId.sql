
--=====================================================================================================================
-- Store Procedure: 	fnLocal_SSI_Cmn_ErrorMessageByUniqueId
-- Author:				Luis Rodriguez
-- Date Created:		2010-04-29
-- Sp Type:				Function
-- Editor Tab Spacing: 	4	
-----------------------------------------------------------------------------------------------------------------------
-- DESCRIPTION: this function returns Error Table based on the Error Uniqueidentifier.
-----------------------------------------------------------------------------------------------------------------------
-- CALLED BY:
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2010-04-29	Luis Rodriguez		Initial Development
-- 1.1			2010-05-12	Luis Rodriguez		Updated VARCHARS Lengths
-- 1.2			2013-06-18	Michel St-Arnaud	Removed GRANT SELECT.
-- 1.3			2015-09-08	Santosha Spickard	Added Grant select back. 
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-----------------------------------------------------------------------------------------------------------------------
-- SELECT * FROM fnLocal_SSI_Cmn_ErrorMessageByUniqueId ('78771F9E-9943-406B-A225-050FA6F90C81')
--=====================================================================================================================
CREATE  FUNCTION	dbo.fnLocal_SSI_Cmn_ErrorMessageByUniqueId(
					@p_uiErrorId	UNIQUEIDENTIFIER	)	

RETURNS 
@tblErrorLog TABLE	(
RcdIdx					INT IDENTITY(1,1)	,
ErrorId					UNIQUEIDENTIFIER	,
NestingLevel			INT					,
DetailId				INT					,
PrimaryObjectName		NVARCHAR(512)		,
ObjectName				VARCHAR(512)		,
ErrorSection			VARCHAR(100)		,
ErrorMessage			VARCHAR(4096)		,
SeverityLevelId			INT					,
SeverityLevel			VARCHAR(25)			,
[TimeStamp]				DATETIME			)				
-----------------------------------------------------------------------------------------------------------------------
AS  
BEGIN
	--=================================================================================================================
	-- Note: options (e.g. SET NOCOUNT OFF) cannot be set inside a function 
	--=================================================================================================================
	DECLARE
		@vchInformational	VARCHAR(25)	,
		@vchWarning			VARCHAR(25)	,
		@vchCritical		VARCHAR(25)
	-------------------------------------------------------------------------------------------------------------------
	--	Populate the values
	--	Informational
	-------------------------------------------------------------------------------------------------------------------
	SELECT	@vchInformational	= Severity_Level_Desc
	FROM	dbo.Local_SSI_ErrorSeverityLevel
	WHERE	Severity_Level_Id	= 2
	-------------------------------------------------------------------------------------------------------------------
	--	Warning
	-------------------------------------------------------------------------------------------------------------------
	SELECT	@vchWarning	= Severity_Level_Desc
	FROM	dbo.Local_SSI_ErrorSeverityLevel
	WHERE	Severity_Level_Id	= 1
	-------------------------------------------------------------------------------------------------------------------
	--	Critical
	-------------------------------------------------------------------------------------------------------------------
	SELECT	@vchCritical	= Severity_Level_Desc
	FROM	dbo.Local_SSI_ErrorSeverityLevel
	WHERE	Severity_Level_Id	= -1
	-------------------------------------------------------------------------------------------------------------------
	--	Get Error from dbo.Local_SSI_ErrorLogDetail based on hte ErrorId = @op_uiErrorId
	-------------------------------------------------------------------------------------------------------------------
	INSERT INTO @tblErrorLog(
		ErrorId				,
		NestingLevel		,
		DetailId			,
		ObjectName			,
		ErrorSection		,
		ErrorMessage		,
		SeverityLevelId		,
		SeverityLevel		,
		[TimeStamp]			)
	SELECT
		eld.Error_Id				,
		eld.Nesting_Level			,
		eld.Detail_Id				,
		eld.[Object_Name]			,
		eld.Error_Section			,
		eld.Error_Message			,
		eld.Error_Severity_Level	,
		CASE
			WHEN	eld.Error_Severity_Level	< 0
			THEN	@vchCritical
			WHEN	eld.Error_Severity_Level	= 2
			THEN	@vchInformational
			WHEN	eld.Error_Severity_Level	> 0
			THEN	@vchWarning
		END,
		eld.[TimeStamp]				
	FROM	dbo.Local_SSI_ErrorLogDetail		eld WITH(NOLOCK)
	WHERE	eld.Error_Id = @p_uiErrorId
	-------------------------------------------------------------------------------------------------------------------
	--	Update PrimaryObjectName from dbo.Local_SSI_ErrorLogHeader
	-------------------------------------------------------------------------------------------------------------------
	UPDATE el
	SET	PrimaryObjectName = eh.Primary_Object_Name
	FROM		@tblErrorLog					el
		JOIN	dbo.Local_SSI_ErrorLogHeader	eh	WITH(NOLOCK)
													ON	el.ErrorId	=	eh.Error_Id
	-------------------------------------------------------------------------------------------------------------------
	-- Return table
	-------------------------------------------------------------------------------------------------------------------
	RETURN
END

