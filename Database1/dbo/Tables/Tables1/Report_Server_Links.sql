CREATE TABLE [dbo].[Report_Server_Links] (
    [Link_Id]      INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Link_Name]    VARCHAR (50)   NOT NULL,
    [Link_Type_Id] INT            NOT NULL,
    [URL]          VARCHAR (7000) NOT NULL,
    CONSTRAINT [PK_Report_Server_Links] PRIMARY KEY CLUSTERED ([Link_Id] ASC),
    CONSTRAINT [FK_Report_Server_Links_Report_Server_Link_Types] FOREIGN KEY ([Link_Type_Id]) REFERENCES [dbo].[Report_Server_Link_Types] ([Link_Type_Id])
);

