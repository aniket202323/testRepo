CREATE TABLE [dbo].[Saved_Queries] (
    [Query_Id]     INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]   INT                       NULL,
    [PU_Id]        INT                       NULL,
    [Query_Name]   [dbo].[Varchar_Long_Desc] NOT NULL,
    [Query_String] VARCHAR (5000)            NULL,
    [Query_Type]   INT                       NOT NULL,
    [Timestamp]    DATETIME                  NOT NULL,
    [User_Id]      INT                       NULL,
    CONSTRAINT [SavedQueries_PK_QueryId] PRIMARY KEY NONCLUSTERED ([Query_Id] ASC)
);

