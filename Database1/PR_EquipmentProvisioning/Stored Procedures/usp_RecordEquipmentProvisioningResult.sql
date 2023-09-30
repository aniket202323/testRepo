
-- =============================================
-- Author:	R Berry
-- Description:	Removes a command from the equipment provisioning table
-- =============================================
CREATE PROCEDURE [PR_EquipmentProvisioning].[usp_RecordEquipmentProvisioningResult]
	@commandId bigint,
	@status tinyint,
	@error nvarchar(1000)
AS
BEGIN
		INSERT INTO [PR_EquipmentProvisioning].EquipmentProvisioningResults (
			[CommandId],
			[Command],
			[EquipmentName],
			[EquipmentClassName],
			[EquipmentType],
			[EquipmentDescription],
			[PropertyName],
			[PropertyDataType],
			[PropertyValue],
			[PropertyUnitOfMeasure],
			[PropertyDescription],
			[HistorianServerName],
			[Parent1],
			[Parent2],
			[Parent3],
			[Parent4],
			[Parent5],
			[Parent6],
			[Parent7],
			[Parent8],
			[Parent9],
			[Status],
			[ProcessedTime],
			[ErrorMessage])
		SELECT 
			[CommandId],
			[Command],
			[EquipmentName],
			[EquipmentClassName],
			[EquipmentType],
			[EquipmentDescription],
			[PropertyName],
			[PropertyDataType],
			[PropertyValue],
			[PropertyUnitOfMeasure],
			[PropertyDescription],
			[HistorianServerName],
			[Parent1],
			[Parent2],
			[Parent3],
			[Parent4],
			[Parent5],
			[Parent6],
			[Parent7],
			[Parent8],
			[Parent9],
			@status,
			SYSUTCDATETIME(),
			@error
		FROM [PR_EquipmentProvisioning].EquipmentProvisioning
		WHERE CommandId = @commandId
		
		DELETE FROM  [PR_EquipmentProvisioning].EquipmentProvisioning
		WHERE CommandId = @commandId

END