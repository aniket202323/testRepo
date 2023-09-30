CREATE TABLE [dbo].[Pending_SystemCompleteActivities] (
    [Activity_Id]                   BIGINT   NOT NULL,
    [System_Complete_Duration_time] DATETIME NULL,
    [Activity_Type_Id]              INT      NULL,
    CONSTRAINT [FK_Pending_SystemCompleteActivities_Activities] FOREIGN KEY ([Activity_Id]) REFERENCES [dbo].[Activities] ([Activity_Id]),
    CONSTRAINT [U_Activity_Id] UNIQUE NONCLUSTERED ([Activity_Id] ASC)
);

