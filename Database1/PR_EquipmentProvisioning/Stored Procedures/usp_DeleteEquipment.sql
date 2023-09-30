
-- =============================================
-- Author:		Ryan Berry
-- Description:	Deletes an equipment instance
-- =============================================
CREATE PROCEDURE [PR_EquipmentProvisioning].[usp_DeleteEquipment]
@EquipmentId UNIQUEIDENTIFIER 
AS
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		IF (SELECT COUNT(EquipmentId) FROM dbo.Equipment WHERE EquipmentId = @EquipmentId) = 0
		BEGIN
			RAISERROR('Invalid equipment instance.', 11, 1);
			RETURN 1
		END

		-- Recursively delete children
		DECLARE @childEquipmentId uniqueidentifier
		DECLARE childCursor CURSOR LOCAL FAST_FORWARD FOR
			SELECT EquipmentId FROM [dbo].[Equipment] WHERE ParentEquipmentId= @EquipmentId

		OPEN childCursor

		FETCH NEXT FROM childCursor into @childEquipmentId
		WHILE @@FETCH_STATUS = 0 BEGIN
			EXEC [PR_EquipmentProvisioning].[usp_DeleteEquipment] @childEquipmentId

			FETCH NEXT FROM childCursor into @childEquipmentId
		END

		CLOSE childCursor
		DEALLOCATE childCursor

		DECLARE @equipmentClassName nvarchar(36)
		SET @equipmentClassName = LOWER(CONVERT(nvarchar(36), @EquipmentId))

		DELETE FROM [dbo].[Property_Equipment_EquipmentClass] 
		WHERE EquipmentId = @EquipmentId;

		DELETE FROM [dbo].[Property_EquipmentClass] 
		WHERE EquipmentClassName = @equipmentClassName;

		DELETE FROM [dbo].[StructuredTypeProperty] 
		WHERE TypeOwnerName = @equipmentClassName;

		DELETE FROM [dbo].[EquipmentClass_EquipmentObject]
		WHERE EquipmentId = @EquipmentId;

		DELETE FROM [dbo].[EquipmentClass]
		WHERE Id = @EquipmentId;

		DELETE FROM [dbo].[EquipmentPropertyHistory]
		WHERE EquipmentId = @EquipmentId;

		DELETE FROM [dbo].[Equipment]
		WHERE EquipmentId = @EquipmentId;

		DELETE FROM [dbo].[StructuredType] 
		WHERE Id = @EquipmentId;
	END TRY
	BEGIN CATCH
		DECLARE @message nvarchar(1000) = ERROR_MESSAGE();
		-- if a child transaction failed, the transaction is already rolled back. Check that transaction is still open
		 IF @@TRANCOUNT > 0
			ROLLBACK
		
		RAISERROR(@message, 11, 1);
		RETURN 1
	END CATCH

	COMMIT
	RETURN 0
END