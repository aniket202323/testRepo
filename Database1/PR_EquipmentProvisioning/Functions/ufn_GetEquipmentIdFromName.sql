
CREATE FUNCTION [PR_EquipmentProvisioning].[ufn_GetEquipmentIdFromName]
(
	@EquipmentName nvarchar(50),
	@ParentEquipmentId uniqueidentifier
)
RETURNS uniqueidentifier
AS
BEGIN
	-- Declare the return variable here
	DECLARE @EquipmentId uniqueidentifier

	SELECT @EquipmentId = EquipmentId FROM [dbo].Equipment
	WHERE ParentEquipmentId = @ParentEquipmentId
	AND S95Id = @EquipmentName

	-- Return the result of the function
	RETURN @EquipmentId

END