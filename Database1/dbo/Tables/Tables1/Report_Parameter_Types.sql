CREATE TABLE [dbo].[Report_Parameter_Types] (
    [RPT_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RPT_Name] VARCHAR (20) NOT NULL,
    CONSTRAINT [PK_Report_Parameter_Types] PRIMARY KEY NONCLUSTERED ([RPT_Id] ASC)
);

