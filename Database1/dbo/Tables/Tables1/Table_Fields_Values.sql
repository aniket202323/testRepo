CREATE TABLE [dbo].[Table_Fields_Values] (
    [KeyId]          INT            NOT NULL,
    [Table_Field_Id] INT            NOT NULL,
    [TableId]        INT            NOT NULL,
    [Value]          VARCHAR (7000) NULL,
    CONSTRAINT [TableFieldsValues_PK_TableIdKeyIdTableFieldId] PRIMARY KEY CLUSTERED ([TableId] ASC, [KeyId] ASC, [Table_Field_Id] ASC),
    CONSTRAINT [TableFieldsData_FK_TableFields] FOREIGN KEY ([Table_Field_Id]) REFERENCES [dbo].[Table_Fields] ([Table_Field_Id]),
    CONSTRAINT [TableFieldsValues_FK_TableId] FOREIGN KEY ([TableId]) REFERENCES [dbo].[Tables] ([TableId])
);


GO
CREATE NONCLUSTERED INDEX [TableFieldsValues_IDX_Linda_TableId]
    ON [dbo].[Table_Fields_Values]([TableId] ASC);


GO
CREATE NONCLUSTERED INDEX [TableFieldsValues_IDX_KeyIdTableId]
    ON [dbo].[Table_Fields_Values]([KeyId] ASC, [TableId] ASC);


GO
CREATE NONCLUSTERED INDEX [TableFieldValues_KeyId_TableId]
    ON [dbo].[Table_Fields_Values]([KeyId] ASC, [TableId] ASC);


GO
CREATE NONCLUSTERED INDEX [TableFieldValues_TableId]
    ON [dbo].[Table_Fields_Values]([TableId] ASC);


GO
CREATE TRIGGER [dbo].[Table_Fields_Values_History_Upd]
 ON  [dbo].[Table_Fields_Values]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 442
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Table_Fields_Values_History
 	  	   (KeyId,Table_Field_Id,TableId,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.KeyId,a.Table_Field_Id,a.TableId,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Table_Fields_Values_History_Del]
 ON  [dbo].[Table_Fields_Values]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 442
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Table_Fields_Values_History
 	  	   (KeyId,Table_Field_Id,TableId,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.KeyId,a.Table_Field_Id,a.TableId,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Table_Fields_Values_History_Ins]
 ON  [dbo].[Table_Fields_Values]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 442
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Table_Fields_Values_History
 	  	   (KeyId,Table_Field_Id,TableId,Value,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.KeyId,a.Table_Field_Id,a.TableId,a.Value,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
