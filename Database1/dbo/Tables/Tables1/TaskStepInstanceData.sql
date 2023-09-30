CREATE TABLE [dbo].[TaskStepInstanceData] (
    [VariableDefinitionId] NVARCHAR (64)    NOT NULL,
    [Value]                SQL_VARIANT      NULL,
    [Version]              BIGINT           NULL,
    [TaskStepInstanceId]   UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([TaskStepInstanceId] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [TaskStepInstanceData_TaskStepInstance_Relation1] FOREIGN KEY ([TaskStepInstanceId]) REFERENCES [dbo].[TaskStepInstance] ([Id])
);

