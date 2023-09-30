CREATE TABLE [dbo].[Production_Setup_Detail_History] (
    [Production_Setup_Detail_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Element_Number]                     INT           NULL,
    [Element_Status]                     TINYINT       NULL,
    [PP_Setup_Id]                        INT           NULL,
    [Comment_Id]                         INT           NULL,
    [Extended_Info]                      VARCHAR (255) NULL,
    [Order_Line_Id]                      INT           NULL,
    [Prod_Id]                            INT           NULL,
    [Target_Dimension_A]                 REAL          NULL,
    [Target_Dimension_X]                 REAL          NULL,
    [Target_Dimension_Y]                 REAL          NULL,
    [Target_Dimension_Z]                 REAL          NULL,
    [User_General_1]                     VARCHAR (255) NULL,
    [User_General_2]                     VARCHAR (255) NULL,
    [User_General_3]                     VARCHAR (255) NULL,
    [User_Id]                            INT           NULL,
    [PP_Setup_Detail_Id]                 INT           NULL,
    [Modified_On]                        DATETIME      NULL,
    [DBTT_Id]                            TINYINT       NULL,
    [Column_Updated_BitMask]             VARCHAR (15)  NULL,
    CONSTRAINT [Production_Setup_Detail_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Production_Setup_Detail_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductionSetupDetailHistory_IX_PPSetupDetailIdModifiedOn]
    ON [dbo].[Production_Setup_Detail_History]([PP_Setup_Detail_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Production_Setup_Detail_History_UpdDel]
 ON  [dbo].[Production_Setup_Detail_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
