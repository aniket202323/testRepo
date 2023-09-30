CREATE TABLE [dbo].[COA] (
    [COA_Id]        INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [COA_Model]     VARCHAR (100) NULL,
    [COA_Name]      VARCHAR (50)  NOT NULL,
    [COA_Trigger]   TINYINT       NOT NULL,
    [Comment_Id]    INT           NULL,
    [Group_Id]      INT           NULL,
    [Option_1]      VARCHAR (100) NULL,
    [Option_2]      VARCHAR (100) NULL,
    [Option_3]      VARCHAR (100) NULL,
    [Option_4]      VARCHAR (100) NULL,
    [Option_5]      VARCHAR (100) NULL,
    [Template_Path] VARCHAR (255) NULL,
    CONSTRAINT [COA_PK_COAId] PRIMARY KEY CLUSTERED ([COA_Id] ASC),
    CONSTRAINT [COA_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id])
);

