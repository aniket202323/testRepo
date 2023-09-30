 
 
 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetSiteProperty]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT,
		@PropertyValue	VARCHAR(255)	OUTPUT,
		@PropertyName	VARCHAR(1000)
AS	
-------------------------------------------------------------------------------
-- Returns the value for the passed in property name for the single equipment
-- object associated with the pre-weigh siteWide class (site equipment)
/*
DECLARE	@e int, @m varchar(255), @v varchar(1000)
exec [spLocal_MPWS_GENL_GetSiteProperty] @e output, @m output, @v output,  'Class Names.Scale'
select @e, @m, @v
*/
-- Date         Version Build Author  
-- 24-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SELECT	@ErrorCode		= 1,
		@ErrorMessage	= 'Success'
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SELECT	@PropertyValue					= CONVERT(VARCHAR(1000), PEEC.Value)
		FROM	dbo.EquipmentClass_EquipmentObject EE			WITH (NOLOCK)
		JOIN	dbo.Property_Equipment_EquipmentClass PEEC		WITH (NOLOCK)
		ON		EE.EquipmentClassName	= 'Pre-Weigh - SiteWide'
		AND		PEEC.Name				= @PropertyName
		
IF		@PropertyValue	IS NULL
BEGIN
		SELECT	@ErrorCode = -1,
				@ErrorMessage = 'Property Not Found'
END
 
 
 
 
 
 
 
 
 
