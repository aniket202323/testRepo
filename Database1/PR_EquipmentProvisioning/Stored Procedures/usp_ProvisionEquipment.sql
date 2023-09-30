--===================================
-- Author:		Ryan Berry
-- Description:	Process the records in the EquipmentProvisioning table and performs the required actions
-- =============================================
CREATE PROCEDURE [PR_EquipmentProvisioning].[usp_ProvisionEquipment]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    /* @Command parameter allowed values
 *
 *  1 - Create Equipment
 *  2 - Remove Equipment
 *  3 - Set Property Value
 *  4 - Set Linked Property
 *  5 - Add Class
 *  6 - Add Property
 */
	DECLARE @commandId bigint
	DECLARE @equipmentName nvarchar(50)
	DECLARE @equipmentDescription nvarchar(255)
	DECLARE @equipmentType nvarchar(50)
	DECLARE @parent1 nvarchar(50)
	DECLARE @parent2 nvarchar(50)
	DECLARE @parent3 nvarchar(50)
	DECLARE @parent4 nvarchar(50)
	DECLARE @parent5 nvarchar(50)
	DECLARE @parent6 nvarchar(50)
	DECLARE @parent7 nvarchar(50)
	DECLARE @parent8 nvarchar(50)
	DECLARE @parent9 nvarchar(50)
	DECLARE @parentEquipmentId uniqueidentifier
	DECLARE @equipmentId uniqueidentifier
	DECLARE @propertyName nvarchar(255)
	DECLARE @propertyValue nvarchar(255)
	DECLARE @propertyDataType int
	DECLARE @propertyUnitOfMeasure nvarchar(255)
	DECLARE @propertyDescription nvarchar(255)
	DECLARE @equipmentClassName nvarchar(200)
	DECLARE @historianServer nvarchar(200)
	DECLARE @errorMessage nvarchar(1000)
	DECLARE @commandResult tinyint
	DECLARE @errorsOccurred bit

	SET @errorsOccurred = 0

	-- create cursor for delete commands
	DECLARE deleteCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT CommandId, EquipmentName, Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9
		from [PR_EquipmentProvisioning].EquipmentProvisioning WHERE Command=2

	OPEN deleteCursor
	DECLARE @equipmentIdToDelete uniqueidentifier
	FETCH NEXT FROM deleteCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9

	WHILE @@FETCH_STATUS = 0 BEGIN
		BEGIN TRY
			SET @errorMessage = NULL
			--execute delete on each row
			--determine equipment ID based on provided hierarchy.
			EXEC PR_EquipmentProvisioning.usp_GetEquipmentIdFromHierarchy @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9, @equipmentId =  @equipmentId OUTPUT 
			
			EXEC @commandResult = PR_EquipmentProvisioning.usp_DeleteEquipment @equipmentId
		END TRY
		BEGIN CATCH
			SET @errorMessage = ERROR_MESSAGE()
			SET @commandResult = 1
			SET @errorsOccurred = 1
		END CATCH

		EXEC PR_EquipmentProvisioning.usp_RecordEquipmentProvisioningResult @commandId, @commandResult, @errorMessage

		FETCH NEXT FROM deleteCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9
	END


	CLOSE deleteCursor
	DEALLOCATE deleteCursor

	--------------------------------------------------

	-- create cursor for create commands order by hierarchy (highest levels first)
	DECLARE createCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT CommandId, EquipmentName, EquipmentDescription, EquipmentType, Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9
		from [PR_EquipmentProvisioning].EquipmentProvisioning WHERE Command=1 
		ORDER BY Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9

	OPEN createCursor
	FETCH NEXT FROM createCursor into @commandId, @equipmentName, @equipmentDescription, @equipmentType, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9

	WHILE @@FETCH_STATUS = 0 BEGIN
		BEGIN TRY
			SET @errorMessage = NULL
			--execute create on each row
			--determine parent ID based on provided hierarchy. Commands must be processed from highest level down to ensure parents exist. Hence the ordering in the cursor select
			IF (@parent1 IS NULL)
				SET @parentEquipmentId = NULL
			ELSE
				EXEC PR_EquipmentProvisioning.usp_GetParentIdFromHierarchy @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9, @parentId = @parentEquipmentId OUTPUT

			EXEC @commandResult = PR_EquipmentProvisioning.usp_CreateEquipment @equipmentName, @equipmentDescription, @equipmentType, @parentEquipmentId
		END TRY
		BEGIN CATCH
			SET @errorMessage = ERROR_MESSAGE()
			SET @commandResult = 1
			SET @errorsOccurred = 1
		END CATCH

		EXEC PR_EquipmentProvisioning.usp_RecordEquipmentProvisioningResult @commandId, @commandResult, @errorMessage

		FETCH NEXT FROM createCursor into @commandId, @equipmentName, @equipmentDescription, @equipmentType, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9
	END

	CLOSE createCursor
	DEALLOCATE createCursor

	--------------------------------------------

	-- create cursor for add class commands
	DECLARE addClassCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT CommandId, EquipmentName, Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9, EquipmentClassName
		from [PR_EquipmentProvisioning].EquipmentProvisioning WHERE Command=5

	OPEN addClassCursor

	FETCH NEXT FROM addClassCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9, @equipmentClassName

	WHILE @@FETCH_STATUS = 0 BEGIN
		BEGIN TRY
			SET @errorMessage = NULL
		EXEC PR_EquipmentProvisioning.usp_GetEquipmentIdFromHierarchy @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9, @equipmentId =  @equipmentId OUTPUT 
			EXEC @commandResult = [PR_EquipmentProvisioning].[usp_AddClass] @equipmentId, @equipmentClassName
		END TRY
		BEGIN CATCH
			SET @commandResult = 1
			SET @errorMessage = ERROR_MESSAGE();
			SET @errorsOccurred = 1
		END CATCH

		EXEC [PR_EquipmentProvisioning].[usp_RecordEquipmentProvisioningResult] @commandId, @commandResult, @errorMessage

		FETCH NEXT FROM addClassCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9, @equipmentClassName
	END

	CLOSE addClassCursor
	DEALLOCATE addClassCursor

	-------------------------------------------------

	-- create cursor for add property commands
	DECLARE propertyCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT CommandId, EquipmentName, Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9,
		 PropertyName, PropertyDataType, PropertyValue, PropertyUnitOfMeasure, PropertyDescription
		from [PR_EquipmentProvisioning].EquipmentProvisioning WHERE Command=6

	OPEN propertyCursor

	FETCH NEXT FROM propertyCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9,
		@propertyName, @propertyDataType, @propertyValue, @propertyUnitOfMeasure, @propertyDescription

	WHILE @@FETCH_STATUS = 0 BEGIN
		BEGIN TRY
			SET @errorMessage = NULL
			EXEC PR_EquipmentProvisioning.usp_GetEquipmentIdFromHierarchy @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9, @equipmentId =  @equipmentId OUTPUT 
			EXEC @commandResult = [PR_EquipmentProvisioning].[usp_AddProperty] @equipmentId, @propertyName, @propertyDataType, @propertyValue, @propertyUnitOfMeasure, @propertyDescription
		END TRY
		BEGIN CATCH
			SET @commandResult = 1
			SET @errorMessage = ERROR_MESSAGE();
			SET @errorsOccurred = 1
		END CATCH

		EXEC PR_EquipmentProvisioning.usp_RecordEquipmentProvisioningResult @commandId, @commandResult, @errorMessage

		FETCH NEXT FROM propertyCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9,
			 @propertyName, @propertyDataType, @propertyValue, @propertyUnitOfMeasure, @propertyDescription
	END

	CLOSE propertyCursor
	DEALLOCATE propertyCursor


	--------------------------------------------------

	-- create cursor for set property commands
	DECLARE propertyValueCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT CommandId, EquipmentName, Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9,
		 PropertyName, PropertyValue
		FROM [PR_EquipmentProvisioning].EquipmentProvisioning WHERE Command=3

	OPEN propertyValueCursor

	FETCH NEXT FROM propertyValueCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9,
		@propertyName, @propertyValue

	WHILE @@FETCH_STATUS = 0 BEGIN
		BEGIN TRY
			SET @errorMessage = NULL
			EXEC PR_EquipmentProvisioning.usp_GetEquipmentIdFromHierarchy @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9, @equipmentId =  @equipmentId OUTPUT 
			EXEC @commandResult = [PR_EquipmentProvisioning].[usp_SetPropertyValue] @equipmentId, @propertyName, @propertyValue
		END TRY
		BEGIN CATCH
			SET @errorMessage = ERROR_MESSAGE()
			SET @commandResult = 1
			SET @errorsOccurred = 1
		END CATCH

		EXEC PR_EquipmentProvisioning.usp_RecordEquipmentProvisioningResult @commandId, @commandResult, @errorMessage

		FETCH NEXT FROM propertyValueCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9,
			 @propertyName, @propertyValue
	END

	CLOSE propertyValueCursor
	DEALLOCATE propertyValueCursor

		--------------------------------------------------

	-- create cursor for historian link commands
	DECLARE historianLinkCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT CommandId, EquipmentName, Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9,
		 PropertyName, PropertyValue, HistorianServerName
		FROM [PR_EquipmentProvisioning].EquipmentProvisioning WHERE Command=4

	OPEN historianLinkCursor

	FETCH NEXT FROM historianLinkCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9,
		@propertyName, @propertyValue, @historianServer

	WHILE @@FETCH_STATUS = 0 BEGIN
		BEGIN TRY
			SET @errorMessage = NULL
			EXEC PR_EquipmentProvisioning.usp_GetEquipmentIdFromHierarchy @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9, @equipmentId =  @equipmentId OUTPUT 
			EXEC @commandResult = [PR_EquipmentProvisioning].[usp_CreateHistorianLink] @equipmentId, @propertyName, @historianServer, @propertyValue
		END TRY
		BEGIN CATCH
			SET @errorMessage = ERROR_MESSAGE()
			SET @commandResult = 1
			SET @errorsOccurred = 1
		END CATCH

		EXEC PR_EquipmentProvisioning.usp_RecordEquipmentProvisioningResult @commandId, @commandResult, @errorMessage

		FETCH NEXT FROM historianLinkCursor into @commandId, @equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9,
			 @propertyName, @propertyValue, @historianServer
	END

	CLOSE historianLinkCursor
	DEALLOCATE historianLinkCursor

	------------------------------------------------
	-- any remaining commands are not recognized; record as errors and clear out table

	INSERT INTO [PR_EquipmentProvisioning].EquipmentProvisioningResults
		(CommandId, Command, EquipmentName, EquipmentClassName, PropertyName, PropertyDataType, PropertyValue, 
		Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9, Status, ProcessedTime, ErrorMessage)
	SELECT CommandId, Command, EquipmentName, EquipmentClassName, PropertyName, PropertyDataType, PropertyValue, 
		Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9, 1, SYSUTCDATETIME(), 'Invalid Command'
	FROM [PR_EquipmentProvisioning].EquipmentProvisioning

	IF @@ROWCOUNT > 0 
		SET @errorsOccurred = 1

	DELETE FROM  [PR_EquipmentProvisioning].EquipmentProvisioning

	


	
	-----------------------------------------------

	RETURN @errorsOccurred
END