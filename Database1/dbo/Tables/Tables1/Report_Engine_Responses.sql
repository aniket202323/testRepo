CREATE TABLE [dbo].[Report_Engine_Responses] (
    [Response_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Response_Desc] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Report_Engine_Responses] PRIMARY KEY NONCLUSTERED ([Response_Id] ASC)
);

