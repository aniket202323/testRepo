CREATE TABLE [dbo].[Return_Error_Codes] (
    [Code_Id]    INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [App_Id]     INT          NULL,
    [Code_Desc]  VARCHAR (50) NOT NULL,
    [Code_Value] VARCHAR (10) NULL,
    [Group_Id]   INT          NULL,
    CONSTRAINT [PK_Return_Error_Codes] PRIMARY KEY NONCLUSTERED ([Code_Id] ASC),
    CONSTRAINT [FK_Return_Error_Codes_Return_Error_Groups] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Return_Error_Groups] ([Group_Id])
);

