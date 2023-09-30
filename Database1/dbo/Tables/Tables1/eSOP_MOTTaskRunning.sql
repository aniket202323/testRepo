CREATE TABLE [dbo].[eSOP_MOTTaskRunning] (
    [InstanceId]                UNIQUEIDENTIFIER NOT NULL,
    [TaskDefinitionId]          UNIQUEIDENTIFIER NOT NULL,
    [TaskStepSequenceId]        INT              NOT NULL,
    [TaskStepId]                UNIQUEIDENTIFIER NULL,
    [TaskStepInstanceId]        UNIQUEIDENTIFIER NULL,
    [TaskType]                  VARCHAR (100)    NOT NULL,
    [TaskName]                  VARCHAR (100)    NOT NULL,
    [TaskDisplayName]           VARCHAR (100)    NOT NULL,
    [TaskStepName]              VARCHAR (100)    NOT NULL,
    [CustomPanelData]           VARCHAR (MAX)    NULL,
    [MeasureVariableName]       VARCHAR (MAX)    NULL,
    [InspectionPoint]           VARCHAR (50)     NULL,
    [StartTime]                 DATETIME         NULL,
    [DurationInMinutes]         INT              NULL,
    [TypeValue]                 VARCHAR (100)    NULL,
    [WhenValue]                 VARCHAR (100)    NULL,
    [GetProductSpecAtValue]     VARCHAR (100)    NULL,
    [Category]                  VARCHAR (100)    NULL,
    [IsSafetyRelated]           BIT              NULL,
    [IsReleaseRelated]          BIT              NULL,
    [IsAutoPopulateProperties]  BIT              NULL,
    [IsPeriodicWorkflow]        BIT              NULL,
    [PeriodicWorkflowFrequency] INT              NULL,
    [PeriodicWorkflowStartDate] DATETIME         NULL,
    [WorkflowLastExecutionTime] DATETIME         NULL,
    [IsESignEnabled]            BIT              NULL,
    [EquipmentID]               VARCHAR (2000)   NULL,
    [EquipmentName]             VARCHAR (255)    NULL,
    [ProductCode]               VARCHAR (100)    NULL,
    [ProcessOrder]              VARCHAR (100)    NULL,
    [WorkInstructions]          VARCHAR (MAX)    NULL,
    [IsWorkInstructionsInRTF]   BIT              NULL,
    [Result]                    VARCHAR (100)    NULL
);


GO
CREATE CLUSTERED INDEX [IndexInstanceId_Clustered]
    ON [dbo].[eSOP_MOTTaskRunning]([InstanceId] ASC);

