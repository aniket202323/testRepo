 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetMaterialDispenseInfo]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500)	OUTPUT,
		@MaterialId		INT,
		@UserId			INT
AS	
 
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Get dispense information link, required interval between reading,	se
-- and the last time the user accessed the dispense information
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetMaterialDispenseInfo @ErrorCode, @ErrorMessage, 6511,1
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build Author  
-- 25-Nov-2015  001     001    <Priyanka> <Surti> (GEIP)  Initial development	
-- 19-May-2016	001		002		Gopinath K				  Used Table Variable
--														  to suit iFIX needs.
-- 06-Jun-2016	001		003		Jim Cameron (GEIP)			Added DispenseReadRequired to result set.
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE	@oDataSet	TABLE
	(
	Id							INT			IDENTITY(1,1),
	LastReadTimestamp			DATETIME,
	DispenseInfoInterval		FLOAT,
	DispenseInfoLink			VARCHAR(255)
	)
	
DECLARE	@LastReadTimestamp		DATETIME,			-- date time stamp of dispense info read UDE by this user, null if never read 
		@DispenseInfoInterval	FLOAT,				-- interval between readings from material property, 0 if no interval specified
		@DispenseInfoLink		VARCHAR(255),		-- link to the dispense info from material property
		@ClassName				VARCHAR(255),
		@PUId					INT
 
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
		SELECT	@DispenseInfoInterval	= CONVERT(FLOAT, CONVERT(VARCHAR(255), Prop_MaterialDef.Value))
						FROM	[dbo].[Products_Aspect_MaterialDefinition]  Prod_MaterialDef			WITH (NOLOCK)
						JOIN    [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef		WITH (NOLOCK)  
						ON		Prod_MaterialDef.Prod_Id				= @MaterialId
						AND		Prop_MaterialDef.Class					= 'Pre-Weigh'
						AND		Prop_MaterialDef.Name					=  'DispenseInfoInterval'
						AND		Prop_MaterialDef.MaterialDefinitionId	= Prod_MaterialDef.Origin1MaterialDefinitionId
						
		SELECT	@DispenseInfoLink = CONVERT(VARCHAR(255), Prop_MaterialDef.Value)
						FROM	[dbo].[Products_Aspect_MaterialDefinition]  Prod_MaterialDef			WITH (NOLOCK)
						JOIN    [dbo].[Property_MaterialDefinition_MaterialClass] Prop_MaterialDef		WITH (NOLOCK)  
						ON		Prod_MaterialDef.Prod_Id				= @MaterialId
						AND		Prop_MaterialDef.Class					= 'Pre-Weigh'
						AND		Prop_MaterialDef.Name					=  'DispenseInfoLink'
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
		--  GET SiteWide class name
		------------------------------------------------------------------------------
		EXEC	dbo.spLocal_MPWS_GENL_GetSiteProperty NULL,NULL, 
				@ClassName OUTPUT,  'Class Names.SiteWide-PU'		
						
		SELECT	@PUId	= PAS.PU_Id
				FROM	EquipmentClass_EquipmentObject EE		WITH (NOLOCK)
				JOIN	PAEquipment_Aspect_SOAEquipment PAS		WITH (NOLOCK)
				ON		EE.EquipmentId			= PAS.Origin1EquipmentId
				AND		EE.EquipmentClassName	= @ClassName
								
 
------------------------------------------------------------------------------
--  Find last time this user read the dispenseInfo (stored as a UDE)
------------------------------------------------------------------------------
IF @UserId IS NOT NULL
BEGIN
		 SELECT		@LastReadTimestamp				= MAX(UDE.Start_Time)
					FROM	dbo.User_Defined_Events UDE		WITH (NOLOCK)
					JOIN	dbo.Event_Subtypes ES			WITH (NOLOCK)
					ON		UDE.Event_Subtype_Id	= ES.Event_Subtype_Id
					AND		ES.Event_Subtype_Desc	= 'DispenseInfoRead'
					AND		UDE.PU_Id				= @PUId
					AND		UDE.User_Id				= @UserId
					AND		UDE.UDE_Desc			LIKE '' + (SELECT Prod_Code FROM dbo.Products_Base WHERE Prod_Id = @MaterialId) + '%'
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
INSERT INTO @oDataSet (DispenseInfoLink, DispenseInfoInterval, LastReadTimestamp)
	SELECT @DispenseInfoLink, @DispenseInfoInterval, @LastReadTimestamp	
 
SELECT	DispenseInfoLink		DispenseInfoLink,
		DispenseInfoInterval	DispenseInfoInterval,
		LastReadTimestamp		LastReadTimestamp,
		CAST(CASE WHEN  (DATEDIFF(HOUR, LastReadTimestamp, GETDATE()) > DispenseInfoInterval) OR (LastReadTimestamp IS NULL)
			THEN 1.0
			ELSE 0.0
		END AS INT) AS DispenseReadRequired
	FROM @oDataSet 
			
 
