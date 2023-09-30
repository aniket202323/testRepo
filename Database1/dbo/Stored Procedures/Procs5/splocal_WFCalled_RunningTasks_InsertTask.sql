CREATE PROCEDURE [dbo].[splocal_WFCalled_RunningTasks_InsertTask]
@InstanceId VARCHAR (100) NULL, @TaskDefinitionId VARCHAR (100) NULL, @TaskStepSequenceId INT NULL, @TaskType VARCHAR (100) NULL, @TaskName VARCHAR (100) NULL, @TaskDisplayName VARCHAR (100) NULL, @TaskStepName VARCHAR (100) NULL, @CustomPanelData VARCHAR (MAX) NULL, @MeasureVariableName VARCHAR (MAX) NULL, @InspectionPoint VARCHAR (50) NULL, @StartTime DATETIME NULL, @DurationInMinutes INT NULL, @TypeValue VARCHAR (100) NULL, @WhenValue VARCHAR (100) NULL, @GetProductSpecAtValue VARCHAR (100) NULL, @Category VARCHAR (100) NULL, @IsSafetyRelated BIT NULL, @IsReleaseRelated BIT NULL, @IsAutoPopulateProperties BIT NULL, @IsPeriodicWorkflow BIT NULL, @PeriodicWorkflowFrequency INT NULL, @PeriodicWorkflowStartDate DATETIME NULL, @WorkflowLastExecutionTime DATETIME NULL, @IsESignEnabled BIT NULL, @EquipmentId VARCHAR (2000) NULL, @EquipmentName VARCHAR (255) NULL, @ProductCode VARCHAR (100) NULL, @ProcessOrder VARCHAR (100) NULL, @WorkInstructions VARCHAR (MAX) NULL, @IsWorkInstructionsInRTF BIT NULL, @Result VARCHAR (100) NULL, @TaskStepId VARCHAR (100) NULL, @TaskStepInstanceId VARCHAR (100) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


