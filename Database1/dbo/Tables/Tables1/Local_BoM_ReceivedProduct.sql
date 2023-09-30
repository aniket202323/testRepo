CREATE TABLE [dbo].[Local_BoM_ReceivedProduct] (
    [FPPId]              INT           IDENTITY (1, 1) NOT NULL,
    [SubmittedTimestamp] DATETIME      NULL,
    [UniqueId]           VARCHAR (100) NULL,
    [Description]        VARCHAR (255) NULL,
    [GCAS]               VARCHAR (25)  NULL,
    [ObjectType]         VARCHAR (100) NULL,
    [RawMessage]         XML           NULL,
    CONSTRAINT [LocalBoMReceivedProduct_PK_FPPId] PRIMARY KEY CLUSTERED ([FPPId] ASC)
);

