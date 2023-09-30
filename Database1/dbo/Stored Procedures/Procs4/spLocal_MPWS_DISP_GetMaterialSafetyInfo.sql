 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetMaterialSafetyInfo]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500)	OUTPUT,
		@MaterialId		INT,
		@UserId			Int
AS	
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Get dispense information link, required interval between reading,
-- and the last time the user accessed the dispense information
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetMaterialSafetyInfo @ErrorCode, @ErrorMessage, 6511,1
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build Author  
-- 25-Nov-2015  001     001    Priyanka Surti (GEIP)  Initial development	
-- 19-May-2016	001		002		Gopinath K				  Used Table Variable
--														  to suit iFIX needs.
-- 06-Jun-2016	001		003		Jim Cameron (GEIP)			Added SafetyReadRequired to result set.
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE	@oDataSet	TABLE
	(
	Id							INT			IDENTITY(1,1),
	LastReadTimestamp			DATETIME,
	SafetyInfoInterval			FLOAT,
	SafetyInfoLink				VARCHAR(255)
	)
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE	@LastReadTimestamp		DATETIME	,		-- date time stamp of dispense info read UDE by this user, null if never read 
		@SafetyInfoInterval		FLOAT		,		-- interval between readings from material property, 0 if no interval specified
		@SafetyInfoLink			VARCHAR(255)		-- link to the dispense info from material property
------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
-------------------------------------------------------------------------------
-- Return Dispense-related properties for the passed in material
-------------------------------------------------------------------------------
IF		@MaterialId IS NOT NULL
BEGIN
		SELECT	@SafetyInfoInterval	= CONVERT(FLOAT, CONVERT(VARCHAR(255), Prop_MaterialDef.Value))
						FROM	[dbo].[Products_Aspect_MaterialDefinition]  Prod_MaterialDef			WITH (NOLOCK)
						JOIN    [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef		WITH (NOLOCK)  
						ON		Prod_MaterialDef.Prod_Id				= @MaterialId
						AND		Prop_MaterialDef.Class					= 'Pre-Weigh'
						AND		Prop_MaterialDef.Name					=  'SafetyInfoInterval'
						AND		Prop_MaterialDef.MaterialDefinitionId	= Prod_MaterialDef.Origin1MaterialDefinitionId
						
		SELECT	@SafetyInfoLink = CONVERT(VARCHAR(255), Prop_MaterialDef.Value)
						FROM	[dbo].[Products_Aspect_MaterialDefinition]  Prod_MaterialDef			WITH (NOLOCK)
						JOIN    [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef		WITH (NOLOCK)  
						ON		Prod_MaterialDef.Prod_Id				= @MaterialId
						AND		Prop_MaterialDef.Class					= 'Pre-Weigh'
						AND		Prop_MaterialDef.Name					=  'SafetyInfoLink'
						AND		Prop_MaterialDef.MaterialDefinitionId	= Prod_MaterialDef.Origin1MaterialDefinitionId						
END
ELSE
BEGIN
		-------------------------------------------------------------------------------
		-- Return error message if material does not exist
		-------------------------------------------------------------------------------
		SELECT	@ErrorCode		= -1,
				@ErrorMessage	= 'Material Id was not provided'
		RETURN		
END
------------------------------------------------------------------------------
--  Find last time this user read the SafetyInfo (stored as a UDE)
------------------------------------------------------------------------------
IF @UserId IS NOT NULL
BEGIN
		 SELECT		@LastReadTimestamp				= MAX(UDE.Start_Time)
					FROM	dbo.User_Defined_Events UDE		WITH (NOLOCK)
					JOIN	dbo.Event_Subtypes ES			WITH (NOLOCK)
					ON		UDE.Event_Subtype_Id	= ES.Event_Subtype_Id
					AND		ES.Event_Subtype_Desc	= 'SafetyInfoRead'
					AND		UDE.User_Id				= @UserId		
END
ELSE
BEGIN
		-------------------------------------------------------------------------------
		-- Return error message if User Id does not exist
		-------------------------------------------------------------------------------
		SELECT	@ErrorCode		= -2,
				@ErrorMessage	= 'User Id was not provided'
		RETURN		
END
------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
--2016-05-19
INSERT INTO @oDataSet (SafetyInfoLink, SafetyInfoInterval, LastReadTimestamp)
	SELECT @SafetyInfoLink, @SafetyInfoInterval, @LastReadTimestamp	
SELECT	SafetyInfoLink			SafetyInfoLink,
		SafetyInfoInterval		ReadInterval,
		LastReadTimestamp		LastReadTimestamp,
		CAST(CASE WHEN (DATEDIFF(HOUR, LastReadTimestamp, GETDATE()) > SafetyInfoInterval) OR (LastReadTimestamp IS NULL)
			THEN 1.0
			ELSE 0.0
		END AS INT) AS SafetyReadRequired	
	FROM @oDataSet 	
			
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_GetMaterialSafetyInfo] TO [public]
 
 
 
 
 
 
 
 
