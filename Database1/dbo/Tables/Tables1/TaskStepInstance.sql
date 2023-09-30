CREATE TABLE [dbo].[TaskStepInstance] (
    [Id]                            UNIQUEIDENTIFIER NOT NULL,
    [AssignedLocationAddress]       NVARCHAR (1024)  NULL,
    [AssignedPersonnelAddress]      NVARCHAR (1024)  NULL,
    [CancelReason]                  NVARCHAR (255)   NULL,
    [CompletedTime]                 DATETIME         NULL,
    [CompletionCodeId]              UNIQUEIDENTIFIER NULL,
    [ExpiryComment]                 NVARCHAR (255)   NULL,
    [ExpiryState]                   INT              NULL,
    [ExpiryTimeLeft]                BIGINT           NULL,
    [IsAcquired]                    BIT              NULL,
    [IsAutomaticAcquireEnabled]     BIT              NULL,
    [IsConditional]                 BIT              NULL,
    [IsEnabled]                     BIT              NULL,
    [IsVisible]                     BIT              NULL,
    [LastExpiryUpdateTime]          DATETIME         NULL,
    [LastModifiedTime]              DATETIME         NULL,
    [r_Order]                       INT              NULL,
    [PerformedLocationAddress]      NVARCHAR (1024)  NULL,
    [PerformedPersonnelAddress]     NVARCHAR (1024)  NULL,
    [StartTime]                     DATETIME         NULL,
    [State]                         INT              NULL,
    [StatusMessage]                 NVARCHAR (255)   NULL,
    [StepDefinitionId]              NVARCHAR (64)    NULL,
    [SubprocessDefinitionId]        UNIQUEIDENTIFIER NULL,
    [TaskClientExpanderPosition]    INT              NULL,
    [TaskClientInputVisibility]     BIT              NULL,
    [TaskClientInputState]          INT              NULL,
    [TaskClientDocumentsVisibility] BIT              NULL,
    [TaskClientDocumentsState]      INT              NULL,
    [TaskClientDocumentsView]       INT              NULL,
    [DisplayName]                   NVARCHAR (50)    NULL,
    [Version]                       BIGINT           NULL,
    [TaskInstanceId]                UNIQUEIDENTIFIER NULL,
    [Categories]                    IMAGE            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [TaskStepInstance_TaskInstance_Relation1] FOREIGN KEY ([TaskInstanceId]) REFERENCES [dbo].[TaskInstance] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_TaskStepInstance_TaskInstanceId]
    ON [dbo].[TaskStepInstance]([TaskInstanceId] ASC);

