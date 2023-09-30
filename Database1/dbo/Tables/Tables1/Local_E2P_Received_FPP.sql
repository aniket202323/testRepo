CREATE TABLE [dbo].[Local_E2P_Received_FPP] (
    [FPPId]              INT           IDENTITY (1, 1) NOT NULL,
    [SubmittedTimestamp] DATETIME      NOT NULL,
    [UniqueId]           VARCHAR (100) NOT NULL,
    [Description]        VARCHAR (255) NOT NULL,
    [GCAS]               VARCHAR (25)  NOT NULL,
    [Version]            VARCHAR (10)  NOT NULL,
    [RawMessage]         XML           NOT NULL,
    [ProcessingStatus]   INT           NOT NULL,
    [AssignedUserId]     INT           NULL,
    [IsLegacy]           TINYINT       NULL,
    [LastModifiedOn]     DATETIME      NULL,
    [SubSector]          VARCHAR (50)  NULL,
    [CommentId]          INT           NULL,
    CONSTRAINT [LocalE2PReceivedFPP_PK_FPPId] PRIMARY KEY CLUSTERED ([FPPId] ASC),
    CONSTRAINT [FK_Local_E2P_Received_FPP_Local_E2P_Received_FPP_Statuses] FOREIGN KEY ([ProcessingStatus]) REFERENCES [dbo].[Local_E2P_Received_FPP_Statuses] ([StatusId])
);

