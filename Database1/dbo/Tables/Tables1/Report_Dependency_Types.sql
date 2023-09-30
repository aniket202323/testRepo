CREATE TABLE [dbo].[Report_Dependency_Types] (
    [RDT_Id]      INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Description] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Report_Dependency_Types] PRIMARY KEY NONCLUSTERED ([RDT_Id] ASC)
);

