CREATE TABLE [dbo].[Return_Error_Groups] (
    [Group_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Group_Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Return_Error_Groups] PRIMARY KEY NONCLUSTERED ([Group_Id] ASC)
);

