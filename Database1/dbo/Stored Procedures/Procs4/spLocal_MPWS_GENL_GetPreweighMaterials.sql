 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetPreweighMaterials]
		@ErrorCode		INT				OUTPUT		,
		@ErrorMessage	VARCHAR(500)	OUTPUT		
--WITH ENCRYPTION
AS				
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Distinct list of Preweigh Materials (materials that have Preweigh class attached)
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_GENL_GetPreweighMaterials @ErrorCode output, @ErrorMessage output
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build Author  
-- 13-Nov-2017  001     001    Susan Lee (GE Digital)  Initial development
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Initialized'
 
	
-------------------------------------------------------------------------------
-- Validate Parameters
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Return list of materials
------------------------------------------------------------------------------- 

SELECT
	p.Prod_Id,
	p.Prod_Code,
	p.Prod_Desc
FROM dbo.Products_Aspect_MaterialDefinition			prodDef		WITH (NOLOCK)
JOIN dbo.Property_MaterialDefinition_MaterialClass	propDef		WITH (NOLOCK)
	ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
JOIN dbo.Products_Base								p 			WITH (NOLOCK)
	ON p.Prod_Id = prodDef.Prod_Id
WHERE propDef.Class LIKE 'Pre-Weigh'
	AND propDef.Name = 'MaterialClass'

