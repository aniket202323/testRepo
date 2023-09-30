CREATE TABLE [dbo].[Report_Def_Webpages] (
    [RDW_Id]        INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Page_Order]    INT NOT NULL,
    [Report_Def_Id] INT NOT NULL,
    [RWP_Id]        INT NOT NULL,
    CONSTRAINT [PK_Report_Def_Webpages] PRIMARY KEY NONCLUSTERED ([RDW_Id] ASC),
    CONSTRAINT [FK_Report_Def_Webpages_Report_WebPages] FOREIGN KEY ([RWP_Id]) REFERENCES [dbo].[Report_WebPages] ([RWP_Id]),
    CONSTRAINT [ReportDefWebpages_FK_ReportId] FOREIGN KEY ([Report_Def_Id]) REFERENCES [dbo].[Report_Definitions] ([Report_Id])
);

