

CREATE FUNCTION [PR_EquipmentProvisioning].[ufn_GetClassIdFromName]
(
	@ClassName nvarchar(50)
)
RETURNS uniqueidentifier
AS
BEGIN
	DECLARE @ClassId uniqueidentifier

	SELECT @ClassId = [Id] FROM [dbo].[EquipmentClass]
    WHERE EquipmentClassName = @ClassName

	RETURN @ClassId

END