CREATE TABLE [dbo].[Report_Engines] (
    [Engine_Id]    INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Engine_Name]  VARCHAR (50) NULL,
    [Service_Name] VARCHAR (20) NOT NULL,
    CONSTRAINT [PK_Report_Engines] PRIMARY KEY NONCLUSTERED ([Engine_Id] ASC)
);

