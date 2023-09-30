CREATE TABLE [WorkOrder].[QueuedJobs] (
    [Id]                      BIGINT             IDENTITY (1, 1) NOT NULL,
    [LastModifiedOn]          DATETIMEOFFSET (7) NOT NULL,
    [JobType]                 NVARCHAR (300)     NOT NULL,
    [JobData]                 NVARCHAR (MAX)     NOT NULL,
    [State]                   INT                NOT NULL,
    [ProcessingAttemptsCount] INT                NOT NULL,
    [CreatedOn]               DATETIMEOFFSET (7) DEFAULT ('0001-01-01T00:00:00.0000000+00:00') NOT NULL,
    [WorkOrderId]             BIGINT             NULL,
    CONSTRAINT [PK_QueuedJobs] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_QueuedJobs_State_JobType]
    ON [WorkOrder].[QueuedJobs]([State] ASC, [JobType] ASC);

