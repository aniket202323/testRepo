CREATE TABLE [dbo].[Report_Type_WebPages] (
    [RTW_Id]         INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Page_Order]     INT NULL,
    [Report_Type_Id] INT NOT NULL,
    [RWP_Id]         INT NOT NULL,
    CONSTRAINT [PK_Report_Type_WebPages] PRIMARY KEY NONCLUSTERED ([RTW_Id] ASC),
    CONSTRAINT [FK_Report_Type_WebPages_Report_Types] FOREIGN KEY ([Report_Type_Id]) REFERENCES [dbo].[Report_Types] ([Report_Type_Id]),
    CONSTRAINT [FK_Report_Type_WebPages_Report_WebPages] FOREIGN KEY ([RWP_Id]) REFERENCES [dbo].[Report_WebPages] ([RWP_Id]),
    CONSTRAINT [Report_Type_WebPages_UC_RptTypeRWP] UNIQUE NONCLUSTERED ([Report_Type_Id] ASC, [RWP_Id] ASC)
);

