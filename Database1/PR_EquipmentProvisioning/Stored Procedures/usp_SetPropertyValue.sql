
-- =============================================
-- Author:		Ryan Berry
-- Description:	Sets an equipment instance property to a static value
-- =============================================
CREATE PROCEDURE [PR_EquipmentProvisioning].[usp_SetPropertyValue]
@EquipmentId UNIQUEIDENTIFIER, 
@PropertyName NVARCHAR(80),
@PropertyValue NVARCHAR(255)
AS
BEGIN
	DECLARE @propertyId nvarchar(255)			
	DECLARE @binaryItemId uniqueidentifier
				
	IF (SELECT COUNT(EquipmentId) FROM dbo.Equipment WHERE EquipmentId = @EquipmentId) = 0
		BEGIN
			RAISERROR('Invalid equipment instance.', 11, 1);
			RETURN 1
		END

	SELECT 
	@propertyId = Id, 
	@binaryItemId = ItemId
	FROM dbo.Property_Equipment_EquipmentClass 
     	WHERE EquipmentId = @EquipmentId 
        AND Name = @PropertyName

	IF (@propertyId is null)
		BEGIN
			RAISERROR('Invalid property name.', 11, 1);
			RETURN 1
		END

	-- Remove any previously set HistorianLinkData
	DELETE FROM [dbo].[EquipmentHistorianLink]
	WHERE EquipmentId = @EquipmentId
	AND EquipmentPropertyName = @PropertyName

	-- Clear out any existing CDO links that might have been set
	IF @binaryItemId IS NOT NULL
		BEGIN
			UPDATE dbo.Property_Equipment_EquipmentClass SET ItemId = NULL WHERE Id=@propertyId
			DELETE FROM dbo.BinaryItem WHERE ItemId = @binaryItemId
		END

	UPDATE [dbo].[Property_Equipment_EquipmentClass]
	SET Value = @PropertyValue
	WHERE EquipmentId = @EquipmentId
	AND Name = @PropertyName

	RETURN 0
END