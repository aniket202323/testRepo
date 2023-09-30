 
 
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS_PLAN_CreateOverrideQuantity]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(255)	OUTPUT,
	@BomfiId		INT,
	@Value			FLOAT
 
AS	
 
/*
-------------------------------------------------------------------------------
	
	Create or Update a OverrideQuantity UDP if the bomfi prod_id allows it
 
-- Date         Version Build Author  
-- 22-Dec-2016  001     001   Jim Cameron (GE Digital)  Initial development	
-- 30-Jun-2017  001     002   Susan Lee (GE Digital)	get error code and messages from UDP update sproc and return.  
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec dbo.spLocal_MPWS_PLAN_CreateOverrideQuantity @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 6391, 23.456
select @ErrorCode, @ErrorMessage
exec dbo.spLocal_MPWS_PLAN_CreateOverrideQuantity @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 5488547, 23.456
select @ErrorCode, @ErrorMessage
 
*/
 
SET NOCOUNT ON;
 
DECLARE
	@CanOverrideQty	VARCHAR(5)
	
SELECT
	@CanOverrideQty = ISNULL(CAST(propDef.Value AS INT), 0)
FROM dbo.Bill_Of_Material_Formulation_Item bomfi
	JOIN dbo.Products_Aspect_MaterialDefinition prodDef ON prodDef.Prod_Id = bomfi.Prod_Id
	JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
WHERE bomfi.BOM_Formulation_Item_Id = @BomfiId
	AND propDef.Class = 'Pre-Weigh'
	AND propDef.Name = 'CanOverrideQty'
 
IF @CanOverrideQty = 1
BEGIN
 
	-- just pass @ErrorCode/@ErrorMessage returned from this EXEC back to the caller.
	EXEC dbo.spLocal_MPWS_GENL_CreateUpdateUDP @ErrorCode OUTPUT, @ErrorMessage OUTPUT, @BomfiId, 'OverrideQuantity', 'Bill_Of_Material_Formulation_Item', @Value
	
	SELECT
		@ErrorCode = @ErrorCode,
		@ErrorMessage = @ErrorMessage;
	
END
ELSE
BEGIN
 
	SELECT
		@ErrorCode = -1,
		@ErrorMessage = 'BOM Item does not allow overriding Quantity';
		
END
 
