CREATE TABLE [dbo].[TaskInstanceData] (
    [VariableDefinitionId] NVARCHAR (64)    NOT NULL,
    [Value]                SQL_VARIANT      NULL,
    [Version]              BIGINT           NULL,
    [TaskInstanceId]       UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([TaskInstanceId] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [TaskInstanceData_TaskInstance_Relation1] FOREIGN KEY ([TaskInstanceId]) REFERENCES [dbo].[TaskInstance] ([Id])
);

