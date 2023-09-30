CREATE TABLE [dbo].[Report_WebPage_Dependencies] (
    [RWD_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RDT_Id] INT           NOT NULL,
    [RWP_Id] INT           NOT NULL,
    [Value]  VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_Report_WebPage_Dependencies] PRIMARY KEY NONCLUSTERED ([RWD_Id] ASC),
    CONSTRAINT [Report_WebPage_DependencieS_UC_RWP_RDT_Value] UNIQUE NONCLUSTERED ([RWP_Id] ASC, [RDT_Id] ASC, [Value] ASC)
);

