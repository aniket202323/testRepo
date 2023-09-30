
CREATE FUNCTION [PR_EquipmentProvisioning].[ufn_GetEnterpriseIdFromName]
(
	@EquipmentName nvarchar(50)
)
RETURNS uniqueidentifier
AS
BEGIN
	-- Declare the return variable here
	DECLARE @EquipmentId uniqueidentifier

	SELECT @EquipmentId = EquipmentId from [dbo].Equipment
	WHERE ParentEquipmentId is NULL
	and S95Id = @EquipmentName
	
	-- Return the result of the function
	RETURN @EquipmentId

END