--=====================================================================================================================
-- Store Procedure: 	fnLocal_SSI_GetColorScheme
-- Author:				Renata Piedmont
-- Date Created:		2007-02-22
-- Sp Type:				Function
-- Editor Tab Spacing: 	4	
-----------------------------------------------------------------------------------------------------------------------
-- DESCRIPTION: this function returns the proficy color scheme data for a given CS_Id
-- the result set can be filtered by any field
-----------------------------------------------------------------------------------------------------------------------
-- CALLED BY:
-- Many stored procures
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2007-02-22	Renata Piedmont		Initial Development
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-----------------------------------------------------------------------------------------------------------------------
-- SELECT * FROM fnLocal_SSI_GetColorScheme (1)
--=====================================================================================================================
CREATE FUNCTION dbo.fnLocal_SSI_GetColorScheme(
				@p_CSId	INT)	-- Color Scheme Id

RETURNS 
@tblColorScheme TABLE	(
CSId		INT,
CSDesc		VARCHAR(50),
CSCatId		INT,
CSCatDesc	VARCHAR(50),
CSFieldId	INT,
CSFieldDesc	VARCHAR(50),
CSColor		INT,
Error		VARCHAR(250))
-----------------------------------------------------------------------------------------------------------------------
AS  
BEGIN
	--=================================================================================================================
	-- Note: options (e.g. SET NOCOUNT OFF) cannot be set inside a function 
	--=================================================================================================================
	--=================================================================================================================
	-- Function variables
	-------------------------------------------------------------------------------------------------------------------
	--=================================================================================================================
	-- Check that CS_Id Exists
	-------------------------------------------------------------------------------------------------------------------
	IF	EXISTS	(SELECT	CS_Id
					FROM	dbo.Color_Scheme
					WHERE	CS_Id = @p_CSId)
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		-- Get color scheme records
		---------------------------------------------------------------------------------------------------------------
		INSERT INTO	@tblColorScheme	(
					CSId		,
					CSDesc		,
					CSCatId		,
					CSCatDesc	,
					CSFieldId	,
					CSFieldDesc	,
					CSColor		)
		SELECT 	csd.CS_Id						,
				cs.CS_Desc						,
				csf.Color_Scheme_Category_Id	,
				csc.Color_Scheme_Category_Desc	,
				csf.Color_Scheme_Field_Id		, 
				csf.Color_Scheme_Field_Desc		,
				COALESCE(csd.Color_Scheme_Value, csf.Default_Color_Scheme_Color)	Color	
		FROM	dbo.Color_Scheme_Categories		csc	
			LEFT JOIN	dbo.Color_Scheme_Fields	csf	WITH (NOLOCK)
													ON	csc.Color_Scheme_Category_Id = csf.Color_Scheme_Category_Id
			LEFT JOIN	dbo.Color_Scheme_Data	csd	WITH (NOLOCK)
													ON	csf.Color_Scheme_Field_Id = csd.Color_Scheme_Field_Id
													AND	csd.CS_Id = @p_CSId
			LEFT JOIN	dbo.Color_Scheme		cs	WITH (NOLOCK)
													ON	cs.CS_Id = csd.CS_Id
		ORDER BY csf.Color_Scheme_Category_Id, csf.Color_Scheme_Field_Id
	END
	ELSE
	BEGIN
		INSERT INTO	@tblColorScheme (
					Error)
		SELECT		'@p_CSId = ' + CONVERT(VARCHAR(50), @p_CSId) + ' DOES NOT EXISTS IN THE dbo.Color_Scheme TABLE'
	END
	-------------------------------------------------------------------------------------------------------------------
	-- Get color scheme records
	-------------------------------------------------------------------------------------------------------------------
	RETURN
END

