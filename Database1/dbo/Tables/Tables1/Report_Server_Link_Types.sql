CREATE TABLE [dbo].[Report_Server_Link_Types] (
    [Link_Type_Id]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Link_Type_Desc] VARCHAR (255) NOT NULL,
    [Link_Type_Name] VARCHAR (50)  NOT NULL,
    CONSTRAINT [PK_Table1] PRIMARY KEY CLUSTERED ([Link_Type_Id] ASC)
);

