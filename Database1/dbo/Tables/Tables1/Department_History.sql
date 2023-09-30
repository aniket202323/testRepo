CREATE TABLE [dbo].[Department_History] (
    [Department_History_Id]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [Dept_Desc]              VARCHAR (50)  NULL,
    [Comment_Id]             INT           NULL,
    [Extended_Info]          VARCHAR (255) NULL,
    [Tag]                    VARCHAR (255) NULL,
    [Time_Zone]              VARCHAR (100) NULL,
    [Dept_Id]                INT           NULL,
    [Modified_On]            DATETIME      NULL,
    [DBTT_Id]                TINYINT       NULL,
    [Column_Updated_BitMask] VARCHAR (15)  NULL,
    CONSTRAINT [Department_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Department_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [DepartmentHistory_IX_DeptIdModifiedOn]
    ON [dbo].[Department_History]([Dept_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Department_History_UpdDel]
 ON  [dbo].[Department_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
