CREATE TABLE [dbo].[Dependency_History] (
    [Dependency_History_Id]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [Dependency_Name]        NVARCHAR (50)  NULL,
    [User_Id]                INT            NULL,
    [Dependency_Desc]        NVARCHAR (300) NULL,
    [Entry_On]               DATETIME       NULL,
    [Dependency_Id]          INT            NULL,
    [Modified_On]            DATETIME       NULL,
    [DBTT_Id]                TINYINT        NULL,
    [Column_Updated_BitMask] VARCHAR (15)   NULL,
    CONSTRAINT [Dependency_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Dependency_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [DependencyHistory_IX_DependencyIdModifiedOn]
    ON [dbo].[Dependency_History]([Dependency_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Dependency_History_UpdDel]
 ON  [dbo].[Dependency_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
