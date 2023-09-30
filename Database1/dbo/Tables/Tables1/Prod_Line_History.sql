CREATE TABLE [dbo].[Prod_Line_History] (
    [Prod_Line_History_Id]   BIGINT                   IDENTITY (1, 1) NOT NULL,
    [PL_Desc]                [dbo].[Varchar_Desc]     NULL,
    [Comment_Id]             INT                      NULL,
    [Dept_Id]                INT                      NULL,
    [Extended_Info]          VARCHAR (255)            NULL,
    [External_Link]          [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]               INT                      NULL,
    [Tag]                    VARCHAR (50)             NULL,
    [User_Defined1]          VARCHAR (255)            NULL,
    [User_Defined2]          VARCHAR (255)            NULL,
    [User_Defined3]          VARCHAR (255)            NULL,
    [PL_Id]                  INT                      NULL,
    [Modified_On]            DATETIME                 NULL,
    [DBTT_Id]                TINYINT                  NULL,
    [Column_Updated_BitMask] VARCHAR (15)             NULL,
    [LineOEEMode]            INT                      NULL,
    CONSTRAINT [Prod_Line_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Prod_Line_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProdLineHistory_IX_PLIdModifiedOn]
    ON [dbo].[Prod_Line_History]([PL_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Prod_Line_History_UpdDel]
 ON  [dbo].[Prod_Line_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
