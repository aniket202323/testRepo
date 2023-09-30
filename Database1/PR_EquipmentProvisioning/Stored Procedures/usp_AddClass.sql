
-- =============================================
-- Author:		Ryan Berry
-- Description:	Adds a class to an equipment instance
-- =============================================
CREATE PROCEDURE [PR_EquipmentProvisioning].[usp_AddClass]
@EquipmentId UNIQUEIDENTIFIER, 
@EquipmentClassName nvarchar(50)
AS
BEGIN
	
	IF (SELECT COUNT(EquipmentId) FROM dbo.Equipment WHERE EquipmentId = @EquipmentId) = 0
		BEGIN
			RAISERROR('Invalid equipment instance.', 11, 1);
			RETURN 1
		END
	ELSE IF (SELECT COUNT(EquipmentClassName) FROM dbo.EquipmentClass WHERE EquipmentClassName = @EquipmentClassName) = 0
		BEGIN
			RAISERROR('Invalid equipment class.', 11, 1);
			RETURN 1
		END
	ELSE IF (SELECT COUNT(EquipmentClassName) FROM dbo.EquipmentClass_EquipmentObject WHERE EquipmentClassName = @EquipmentClassName AND EquipmentId = @EquipmentId) > 0
		BEGIN
			RAISERROR('Class has already been added to this equipment.', 11, 1);
			RETURN 1
		END

	BEGIN TRANSACTION
	BEGIN TRY

	-- RB: ClassOrder seems irrelevant
	INSERT INTO [dbo].[EquipmentClass_EquipmentObject] (ClassOrder, Version, EquipmentClassName, EquipmentId)
	VALUES (1, 1, @EquipmentClassName, @EquipmentId)

	-- Add each class property to the equipment instance
	INSERT INTO [dbo].[Property_Equipment_EquipmentClass] (
            Name,
            Class,
            Constant,
            Id,
            IsTemplate,
            Description,
            UnitOfMeasure,
            IsUnitOfMeasureOverridden,
            IsDescriptionOverridden,
            IsValueOverridden,
            TimeStamp,
            Value,
            Version,
            EquipmentId,
            ItemId)
	SELECT
            PropertyName,
   			@EquipmentClassName,
   			0,			
   			NEWID(),	
   			NULL,		
   			Description,   
			UnitOfMeasure, 
   			0,			
   			0,			
   			0,			
   			SYSUTCDATETIME(),
			Value,
   			1,		
   			@EquipmentId,
   			NULL
	FROM [dbo].[Property_EquipmentClass]
    WHERE EquipmentClassName = @EquipmentClassName

	END TRY
	BEGIN CATCH
		ROLLBACK
		DECLARE @message nvarchar(1000) = ERROR_MESSAGE();
		RAISERROR(@message, 11, 1);
		RETURN 1
	END CATCH

	COMMIT
	RETURN 0
END