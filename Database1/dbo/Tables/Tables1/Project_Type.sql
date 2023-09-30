CREATE TABLE [dbo].[Project_Type] (
    [Project_Type_Id]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Project_Type_Name] NVARCHAR (50) NOT NULL,
    CONSTRAINT [ProjectType_PK_Id] PRIMARY KEY NONCLUSTERED ([Project_Type_Id] ASC),
    CONSTRAINT [ProjectType_CC_EmptyName] CHECK (len([Project_Type_Name])>(0))
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [ProjectType_UC_ProjectTypeName]
    ON [dbo].[Project_Type]([Project_Type_Name] ASC);

