CREATE TABLE [dbo].[FTP_Post_Actions] (
    [FPA_Id]   TINYINT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FPA_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [FTP_Post_Actions_PK_FPAId] PRIMARY KEY CLUSTERED ([FPA_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FTP_Post_Actions_UC_FPADesc]
    ON [dbo].[FTP_Post_Actions]([FPA_Desc] ASC);

