CREATE TABLE [dbo].[Web_Report_Triggers] (
    [WRT_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [WRT_Desc] VARCHAR (50) NULL,
    CONSTRAINT [PK_Web_Report_Triggers] PRIMARY KEY NONCLUSTERED ([WRT_Id] ASC)
);

