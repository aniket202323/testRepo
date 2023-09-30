CREATE TABLE [dbo].[eSop_Task] (
    [Id]                  UNIQUEIDENTIFIER NOT NULL,
    [Name]                NVARCHAR (MAX)   NULL,
    [Description]         NVARCHAR (MAX)   NULL,
    [Group]               NVARCHAR (MAX)   NULL,
    [DisplayName]         NVARCHAR (MAX)   NULL,
    [LocationAssignment]  NVARCHAR (MAX)   NULL,
    [PersonnelAssignment] NVARCHAR (MAX)   NULL,
    [Enabled]             BIT              NOT NULL,
    [Priority]            INT              NOT NULL,
    [ExpirationTicks]     BIGINT           NOT NULL,
    [TaskTemplate_Id]     UNIQUEIDENTIFIER NULL,
    [LastModified]        DATETIME         DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_dbo.eSop_Task] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_dbo.eSop_Task_dbo.eSop_TaskTemplate_TaskTemplate_Id] FOREIGN KEY ([TaskTemplate_Id]) REFERENCES [dbo].[eSop_TaskTemplate] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_TaskTemplate_Id]
    ON [dbo].[eSop_Task]([TaskTemplate_Id] ASC);

