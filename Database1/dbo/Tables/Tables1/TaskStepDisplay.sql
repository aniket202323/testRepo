CREATE TABLE [dbo].[TaskStepDisplay] (
    [Id]                            UNIQUEIDENTIFIER NOT NULL,
    [CanCancel]                     BIT              NULL,
    [CompletedTime]                 DATETIME         NULL,
    [DisplayAddress]                NVARCHAR (1024)  NULL,
    [InputParameters]               IMAGE            NULL,
    [OutputParameters]              IMAGE            NULL,
    [StartTime]                     DATETIME         NULL,
    [State]                         INT              NULL,
    [RequiresESigOnSubmit]          BIT              NULL,
    [CloseOnFailedESig]             BIT              NULL,
    [OnSubmitESigDescription]       NVARCHAR (255)   NULL,
    [OnSubmitVerifierRequired]      BIT              NULL,
    [OnSubmitPerformerGroupAddress] NVARCHAR (255)   NULL,
    [OnSubmitVerifierGroupAddress]  NVARCHAR (255)   NULL,
    [OnSubmitESigId]                NVARCHAR (255)   NULL,
    [ESigPerformerName]             NVARCHAR (255)   NULL,
    [ESigPerformerSigningTime]      DATETIME         NULL,
    [ESigVerifierName]              NVARCHAR (255)   NULL,
    [ESigVerifierSigningTime]       DATETIME         NULL,
    [TechnologyType]                NVARCHAR (255)   NULL,
    [Version]                       BIGINT           NULL,
    [TaskStepInstanceId]            UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [TaskStepDisplay_TaskStepInstance_Relation1] FOREIGN KEY ([TaskStepInstanceId]) REFERENCES [dbo].[TaskStepInstance] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_TaskStepDisplay_TaskStepInstanceId]
    ON [dbo].[TaskStepDisplay]([TaskStepInstanceId] ASC);

