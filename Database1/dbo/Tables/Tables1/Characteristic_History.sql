CREATE TABLE [dbo].[Characteristic_History] (
    [Characteristic_History_Id] BIGINT                   IDENTITY (1, 1) NOT NULL,
    [Char_Desc]                 [dbo].[Varchar_Desc]     NULL,
    [Prop_Id]                   INT                      NULL,
    [Char_Code]                 VARCHAR (50)             NULL,
    [Characteristic_Type]       TINYINT                  NULL,
    [Comment_Id]                INT                      NULL,
    [Derived_From_Exception]    INT                      NULL,
    [Derived_From_Parent]       INT                      NULL,
    [Exception_Type]            TINYINT                  NULL,
    [Extended_Info]             VARCHAR (255)            NULL,
    [External_Link]             [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]                  INT                      NULL,
    [Next_Exception]            INT                      NULL,
    [Prod_Id]                   INT                      NULL,
    [Tag]                       VARCHAR (50)             NULL,
    [Char_Id]                   INT                      NULL,
    [Modified_On]               DATETIME                 NULL,
    [DBTT_Id]                   TINYINT                  NULL,
    [Column_Updated_BitMask]    VARCHAR (15)             NULL,
    CONSTRAINT [Characteristic_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Characteristic_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [CharacteristicHistory_IX_CharIdModifiedOn]
    ON [dbo].[Characteristic_History]([Char_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Characteristic_History_UpdDel]
 ON  [dbo].[Characteristic_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
