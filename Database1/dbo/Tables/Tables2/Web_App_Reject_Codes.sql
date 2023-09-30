CREATE TABLE [dbo].[Web_App_Reject_Codes] (
    [WARC_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [WARC_Code] INT          NOT NULL,
    [WARC_Desc] VARCHAR (50) NULL,
    [WAT_Id]    INT          NOT NULL,
    CONSTRAINT [PK_Web_App_Reject_Codes] PRIMARY KEY NONCLUSTERED ([WARC_Id] ASC),
    CONSTRAINT [WARC_WA] FOREIGN KEY ([WAT_Id]) REFERENCES [dbo].[Web_App_Types] ([WAT_Id])
);

