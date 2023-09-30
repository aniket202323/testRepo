CREATE TABLE [dbo].[Local_Nexus_Message_Reprocessing] (
    [MessageId]          INT            IDENTITY (1, 1) NOT NULL,
    [Command]            VARCHAR (50)   NOT NULL,
    [MessageType]        VARCHAR (50)   NOT NULL,
    [MessageVerb]        VARCHAR (50)   NOT NULL,
    [MessageBody]        XML            NULL,
    [RetryAttempt]       INT            NOT NULL,
    [SubmittedTimestamp] DATETIME       NOT NULL,
    [ProcessedTimestamp] DATETIME       NULL,
    [HTTPResponseCode]   INT            NULL,
    [SampleUDEIds]       VARCHAR (1000) NULL,
    [NexusBatchId]       VARCHAR (255)  NULL,
    [BatchUDEId]         INT            NULL,
    [PPId]               INT            NULL,
    [ChangeoverFlag]     BIT            NULL,
    [CompleteFlag]       VARCHAR (1)    NOT NULL,
    CONSTRAINT [LocalNexusMessageReprocessing_PK_MessageId] PRIMARY KEY CLUSTERED ([MessageId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalNexusMessageReprocessing_IDX_SubmittedTimestamp]
    ON [dbo].[Local_Nexus_Message_Reprocessing]([SubmittedTimestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalNexusMessageReprocessing_IDX_PPId]
    ON [dbo].[Local_Nexus_Message_Reprocessing]([PPId] ASC);

