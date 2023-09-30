CREATE TABLE [dbo].[Email_Group_Xref] (
    [EG_XRef_Id] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [EG_Id]      INT NOT NULL,
    [Key_Id]     INT NOT NULL,
    [Table_Id]   INT NOT NULL,
    CONSTRAINT [EGXRef_PK_EGXRefId] PRIMARY KEY NONCLUSTERED ([EG_XRef_Id] ASC),
    CONSTRAINT [EGXRef_FK_EmailGroup] FOREIGN KEY ([EG_Id]) REFERENCES [dbo].[Email_Groups] ([EG_Id]) ON DELETE CASCADE,
    CONSTRAINT [EGXRef_FK_Tables] FOREIGN KEY ([Table_Id]) REFERENCES [dbo].[Tables] ([TableId])
);

