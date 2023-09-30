CREATE TABLE [dbo].[Local_Nexus_Message_Reprocessing_Parts] (
    [MessagePartsId]    INT           IDENTITY (1, 1) NOT NULL,
    [MessageId]         INT           NOT NULL,
    [ReceivedDate]      VARCHAR (25)  NULL,
    [ExpiryDate]        VARCHAR (25)  NULL,
    [ManufacturingLine] VARCHAR (50)  NULL,
    [PrecedingNexusId]  VARCHAR (255) NULL,
    [ReportTimestamp]   VARCHAR (25)  NULL,
    [ReportTimezone]    VARCHAR (25)  NULL,
    [SystemId]          VARCHAR (25)  NULL,
    [ProcessOrder]      VARCHAR (25)  NULL,
    [ProductGCAS]       VARCHAR (25)  NULL,
    [SampleCopies]      INT           NULL,
    [SampleType]        VARCHAR (25)  NULL,
    [Subresource]       VARCHAR (50)  NULL,
    [BatchDesc]         VARCHAR (200) NULL,
    CONSTRAINT [LocalNexusMessageReprocessingParts_PK_MessagePartsId] PRIMARY KEY CLUSTERED ([MessagePartsId] ASC),
    CONSTRAINT [LocalNexusMessageReprocessingParts_FK_MessageId] FOREIGN KEY ([MessageId]) REFERENCES [dbo].[Local_Nexus_Message_Reprocessing] ([MessageId])
);


GO
CREATE NONCLUSTERED INDEX [LocalNexusMessageReprocessingParts_IDX_MessageId]
    ON [dbo].[Local_Nexus_Message_Reprocessing_Parts]([MessageId] ASC);

