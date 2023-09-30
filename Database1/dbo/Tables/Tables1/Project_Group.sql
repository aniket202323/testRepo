CREATE TABLE [dbo].[Project_Group] (
    [Project_Group_Id]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Project_Group_Name] NVARCHAR (50) NOT NULL,
    CONSTRAINT [ProjectGroup_PK_Id] PRIMARY KEY NONCLUSTERED ([Project_Group_Id] ASC),
    CONSTRAINT [ProjectGroup_CC_EmptyName] CHECK (len([Project_Group_Name])>(0))
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [ProjectGroup_UC_ProjectGroupName]
    ON [dbo].[Project_Group]([Project_Group_Name] ASC);

