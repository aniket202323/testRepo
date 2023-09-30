-- =============================================
-- Author:		Ryan Berry
-- Description:	Creates a historian tag link for an equipment instance property
-- =============================================
CREATE PROCEDURE [PR_EquipmentProvisioning].[usp_CreateHistorianLink]
@EquipmentId UNIQUEIDENTIFIER, 
@PropertyName NVARCHAR(80),
@HistorianServer NVARCHAR(255),
@HistorianTag NVARCHAR(655)
AS
BEGIN
	Declare @propertyId nvarchar(255)
	Declare @tagId uniqueidentifier
	DECLARE @historianServerId uniqueidentifier
	DECLARE @linkDisplayName nvarchar(400)
	DECLARE @binaryItemId uniqueidentifier
				
	IF NOT EXISTS (SELECT 1 FROM dbo.Equipment WHERE EquipmentId = @EquipmentId)
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

	Set @historianServerId = (SELECT Id FROM dbo.Historian_Server WHERE Name = @HistorianServer)
	IF (@historianServerId is null)
		BEGIN
			RAISERROR('Invalid historian server name.', 11, 1);
			RETURN 1
		END

	SET @tagId = (SELECT Id FROM dbo.Historian_Tag WHERE
		Name = @HistorianTag AND
		HistorianId = @historianServerId)

	IF (@tagId IS NULL)
		BEGIN
			RAISERROR('Invalid tag name.', 11, 1);
			RETURN 1
		END

	Set @linkDisplayName = @HistorianServer + '.' + @HistorianTag

	IF (SELECT COUNT(*) FROM dbo.EquipmentHistorianLink WHERE EquipmentId = @EquipmentId AND EquipmentPropertyName = @PropertyName) = 0
		INSERT INTO dbo.EquipmentHistorianLink(EquipmentId, EquipmentPropertyName, HistorianTagId, LinkDisplayName) 
			VALUES(@EquipmentId,@PropertyName, @tagId, @linkDisplayName)
	ELSE 
		UPDATE dbo.EquipmentHistorianLink
		SET HistorianTagId = @tagId, LinkDisplayName = @linkDisplayName
		WHERE EquipmentId = @EquipmentId AND EquipmentPropertyName = @PropertyName

	-- Clear out any existing CDO links that might have been set for the equipment
	IF @binaryItemId IS NOT NULL
		BEGIN
			UPDATE dbo.Property_Equipment_EquipmentClass SET ItemId = NULL WHERE Id=@propertyId
			DELETE FROM dbo.BinaryItem WHERE ItemId = @binaryItemId
		END

	RETURN 0
END