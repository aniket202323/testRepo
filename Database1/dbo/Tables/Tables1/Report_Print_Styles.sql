CREATE TABLE [dbo].[Report_Print_Styles] (
    [Style_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Style_Name] VARCHAR (20) NOT NULL,
    CONSTRAINT [PK_Report_Print_Styles] PRIMARY KEY NONCLUSTERED ([Style_Id] ASC)
);

