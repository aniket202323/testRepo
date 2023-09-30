CREATE TABLE [dbo].[FTP_Transfer_Types] (
    [FTT_Id]   TINYINT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FTT_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [FTP_Transfer_Types_PK_FTTId] PRIMARY KEY CLUSTERED ([FTT_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FTP_Transfer_Types_UC_FTTDesc]
    ON [dbo].[FTP_Transfer_Types]([FTT_Desc] ASC);

