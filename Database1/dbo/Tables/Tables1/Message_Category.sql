CREATE TABLE [dbo].[Message_Category] (
    [Category_Id]  INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Display_Name] NVARCHAR (50)  NOT NULL,
    [Name]         NVARCHAR (200) NOT NULL,
    [Parent_Id]    INT            NULL,
    CONSTRAINT [MessageCategory_PK_CategoryId] PRIMARY KEY NONCLUSTERED ([Category_Id] ASC),
    CONSTRAINT [MessageCategory_FK_ParentId] FOREIGN KEY ([Parent_Id]) REFERENCES [dbo].[Message_Category] ([Category_Id])
);


GO
CREATE UNIQUE CLUSTERED INDEX [MessageCategory_UC_Name]
    ON [dbo].[Message_Category]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [MessageCategory_IDX_ParentId]
    ON [dbo].[Message_Category]([Parent_Id] ASC);

