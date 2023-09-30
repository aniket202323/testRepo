CREATE TABLE [dbo].[TaskInstance] (
    [Id]                         UNIQUEIDENTIFIER NOT NULL,
    [CancelReason]               NVARCHAR (255)   NULL,
    [CompletedTime]              DATETIME         NULL,
    [DisplayName]                NVARCHAR (80)    NULL,
    [ExpiryComment]              NVARCHAR (255)   NULL,
    [ExpiryState]                INT              NULL,
    [ExpiryTimeLeft]             BIGINT           NULL,
    [InstancingMethod]           INT              NULL,
    [LastExpiryUpdateTime]       DATETIME         NULL,
    [LastModifiedTime]           DATETIME         NULL,
    [Priority]                   BIGINT           NULL,
    [StartTime]                  DATETIME         NULL,
    [State]                      INT              NULL,
    [WorkflowDefinitionId]       UNIQUEIDENTIFIER NULL,
    [WorkflowDefinitionRevision] BIGINT           NULL,
    [WorkflowScheduleId]         UNIQUEIDENTIFIER NULL,
    [WorkflowScheduleRevision]   BIGINT           NULL,
    [WorkflowInstanceId]         UNIQUEIDENTIFIER NULL,
    [Version]                    BIGINT           NULL,
    [Categories]                 IMAGE            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

