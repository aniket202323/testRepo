CREATE TABLE [dbo].[Table_Fields_Values_History] (
    [Table_Fields_Values_History_Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [KeyId]                          INT            NULL,
    [Table_Field_Id]                 INT            NULL,
    [TableId]                        INT            NULL,
    [Value]                          VARCHAR (7000) NULL,
    [Modified_On]                    DATETIME       NULL,
    [DBTT_Id]                        TINYINT        NULL,
    [Column_Updated_BitMask]         VARCHAR (15)   NULL,
    CONSTRAINT [Table_Fields_Values_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Table_Fields_Values_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [TableFieldsValuesHistory_IX_TableIdTableFieldIdKeyIdModifiedOn]
    ON [dbo].[Table_Fields_Values_History]([TableId] ASC, [Table_Field_Id] ASC, [KeyId] ASC, [Modified_On] ASC);


GO
CREATE NONCLUSTERED INDEX [TableFieldsValuesHistory_IX_TableIdModifiedOn]
    ON [dbo].[Table_Fields_Values_History]([TableId] ASC, [Modified_On] ASC);


GO
CREATE NONCLUSTERED INDEX [TableFieldsValuesHistory_IX_KeyIdTableIdModifiedOn]
    ON [dbo].[Table_Fields_Values_History]([KeyId] ASC, [TableId] ASC, [Modified_On] ASC);


GO
CREATE NONCLUSTERED INDEX [TableFieldsValuesHistory_IX_TableFieldID]
    ON [dbo].[Table_Fields_Values_History]([Table_Field_Id] ASC);


GO
CREATE TRIGGER [dbo].[Table_Fields_Values_History_UpdDel]
 ON  [dbo].[Table_Fields_Values_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Table_Fields_Values_History
 	 FROM Table_Fields_Values_History a 
 	 JOIN  Deleted b on b.TableId = a.TableId
 	 and b.KeyId = a.KeyId
 	 and b.Table_Field_Id = a.Table_Field_Id
END
