CREATE TABLE [dbo].[eSop_TaskStep] (
    [Id]                  UNIQUEIDENTIFIER NOT NULL,
    [Name]                NVARCHAR (MAX)   NULL,
    [DisplayName]         NVARCHAR (MAX)   NULL,
    [LocationAssignment]  NVARCHAR (MAX)   NULL,
    [PersonnelAssignment] NVARCHAR (MAX)   NULL,
    [Sequence]            INT              NOT NULL,
    [Enabled]             BIT              NOT NULL,
    [ExpirationTicks]     BIGINT           NOT NULL,
    [WorkInstructionsId]  UNIQUEIDENTIFIER NOT NULL,
    [StepDefinitionId]    NVARCHAR (MAX)   NULL,
    [AssignmentOverride]  BIT              NOT NULL,
    [Task_Id]             UNIQUEIDENTIFIER NOT NULL,
    [LastModified]        DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_TaskStep] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_TaskStep_dbo.eSop_Task_Task_Id] FOREIGN KEY ([Task_Id]) REFERENCES [dbo].[eSop_Task] ([Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Task_Id]
    ON [dbo].[eSop_TaskStep]([Task_Id] ASC);

