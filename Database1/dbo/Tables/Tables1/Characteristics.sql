CREATE TABLE [dbo].[Characteristics] (
    [Char_Id]                INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Char_Code]              VARCHAR (50)             NULL,
    [Characteristic_Type]    TINYINT                  NULL,
    [Comment_Id]             INT                      NULL,
    [Derived_From_Exception] INT                      NULL,
    [Derived_From_Parent]    INT                      NULL,
    [Exception_Type]         TINYINT                  NULL,
    [Extended_Info]          VARCHAR (255)            NULL,
    [External_Link]          [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]               INT                      NULL,
    [Next_Exception]         INT                      NULL,
    [Prod_Id]                INT                      NULL,
    [Prop_Id]                INT                      NOT NULL,
    [Tag]                    VARCHAR (50)             NULL,
    [Char_Desc_Global]       [dbo].[Varchar_Desc]     NULL,
    [Char_Desc_Local]        [dbo].[Varchar_Desc]     NOT NULL,
    [Char_Desc]              AS                       (case when (@@options&(512))=(0) then isnull([Char_Desc_Global],[Char_Desc_Local]) else [Char_Desc_Local] end),
    CONSTRAINT [Char_PK_CharId] PRIMARY KEY CLUSTERED ([Char_Id] ASC),
    CONSTRAINT [Char_FK_PropId] FOREIGN KEY ([Prop_Id]) REFERENCES [dbo].[Product_Properties] ([Prop_Id]),
    CONSTRAINT [Char_UC_CharDescPropIdLocal] UNIQUE NONCLUSTERED ([Char_Desc_Local] ASC, [Prop_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Char_IDX_PropId]
    ON [dbo].[Characteristics]([Prop_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Char_IDX_DerivedFromParent]
    ON [dbo].[Characteristics]([Derived_From_Parent] ASC);


GO
CREATE NONCLUSTERED INDEX [Char_IDX_ProdId]
    ON [dbo].[Characteristics]([Prod_Id] ASC);


GO
CREATE TRIGGER [dbo].[Characteristics_History_Ins]
 ON  [dbo].[Characteristics]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 451
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Characteristic_History
 	  	   (Char_Code,Char_Desc,Char_Id,Characteristic_Type,Comment_Id,Derived_From_Exception,Derived_From_Parent,Exception_Type,Extended_Info,External_Link,Group_Id,Next_Exception,Prod_Id,Prop_Id,Tag,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Char_Code,a.Char_Desc,a.Char_Id,a.Characteristic_Type,a.Comment_Id,a.Derived_From_Exception,a.Derived_From_Parent,a.Exception_Type,a.Extended_Info,a.External_Link,a.Group_Id,a.Next_Exception,a.Prod_Id,a.Prop_Id,a.Tag,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Characteristics_Del ON dbo.Characteristics
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Characteristics_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Characteristics_Del_Cursor 
--
--
Fetch_Next_Characteristics:
FETCH NEXT FROM Characteristics_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Next_Characteristics
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Characteristics_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Characteristics_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Characteristics_TableFieldValue_Del]
 ON  [dbo].[Characteristics]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Char_Id
 WHERE tfv.TableId = 41

GO
CREATE TRIGGER [dbo].[Characteristics_History_Del]
 ON  [dbo].[Characteristics]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 451
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Characteristic_History
 	  	   (Char_Code,Char_Desc,Char_Id,Characteristic_Type,Comment_Id,Derived_From_Exception,Derived_From_Parent,Exception_Type,Extended_Info,External_Link,Group_Id,Next_Exception,Prod_Id,Prop_Id,Tag,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Char_Code,a.Char_Desc,a.Char_Id,a.Characteristic_Type,a.Comment_Id,a.Derived_From_Exception,a.Derived_From_Parent,a.Exception_Type,a.Extended_Info,a.External_Link,a.Group_Id,a.Next_Exception,a.Prod_Id,a.Prop_Id,a.Tag,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Characteristics_History_Upd]
 ON  [dbo].[Characteristics]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 451
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Characteristic_History
 	  	   (Char_Code,Char_Desc,Char_Id,Characteristic_Type,Comment_Id,Derived_From_Exception,Derived_From_Parent,Exception_Type,Extended_Info,External_Link,Group_Id,Next_Exception,Prod_Id,Prop_Id,Tag,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Char_Code,a.Char_Desc,a.Char_Id,a.Characteristic_Type,a.Comment_Id,a.Derived_From_Exception,a.Derived_From_Parent,a.Exception_Type,a.Extended_Info,a.External_Link,a.Group_Id,a.Next_Exception,a.Prod_Id,a.Prop_Id,a.Tag,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
