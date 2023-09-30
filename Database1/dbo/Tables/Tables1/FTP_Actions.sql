CREATE TABLE [dbo].[FTP_Actions] (
    [FA_Id]   TINYINT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FA_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [FTPActions_PK_FAId] PRIMARY KEY CLUSTERED ([FA_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FTP_Action_UC_FA_Desc]
    ON [dbo].[FTP_Actions]([FA_Desc] ASC);

