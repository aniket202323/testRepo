CREATE TABLE [dbo].[Report_WebPage_Parameters] (
    [Rpt_WebPage_Param_Id] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RP_Id]                INT NOT NULL,
    [RWP_Id]               INT NOT NULL,
    CONSTRAINT [PK_Report_WebPage_Parameters] PRIMARY KEY NONCLUSTERED ([Rpt_WebPage_Param_Id] ASC),
    CONSTRAINT [FK_Report_WebPage_Parameters_Report_Parameters] FOREIGN KEY ([RP_Id]) REFERENCES [dbo].[Report_Parameters] ([RP_Id]),
    CONSTRAINT [FK_Report_WebPage_Parameters_Report_WebPages] FOREIGN KEY ([RWP_Id]) REFERENCES [dbo].[Report_WebPages] ([RWP_Id])
);


GO
CREATE NONCLUSTERED INDEX [Report_WebPage_Parameters_UC_RP_RWP]
    ON [dbo].[Report_WebPage_Parameters]([RP_Id] ASC, [RWP_Id] ASC);

