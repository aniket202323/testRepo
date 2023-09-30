CREATE TABLE [dbo].[Product_Properties] (
    [Prop_Id]           INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Auto_Sync_Chars]   TINYINT                  CONSTRAINT [ProductProperties_DF_AutoSyncChars] DEFAULT ((0)) NOT NULL,
    [Comment_Id]        INT                      NULL,
    [Default_Size]      REAL                     NULL,
    [Eng_Units]         VARCHAR (50)             NULL,
    [External_Link]     [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]          INT                      NULL,
    [Is_Hidden]         TINYINT                  NULL,
    [Is_Unit_Specific]  TINYINT                  NULL,
    [Product_Family_Id] INT                      NULL,
    [Prop_Desc_Global]  [dbo].[Varchar_Desc]     NULL,
    [Prop_Desc_Local]   [dbo].[Varchar_Desc]     NOT NULL,
    [Property_Order]    INT                      NULL,
    [Property_Type_Id]  INT                      CONSTRAINT [ProductProp_DF_PropTypeId] DEFAULT ((1)) NULL,
    [PU_Id]             INT                      NULL,
    [Tag]               VARCHAR (50)             NULL,
    [Prop_Desc]         AS                       (case when (@@options&(512))=(0) then isnull([Prop_Desc_Global],[Prop_Desc_Local]) else [Prop_Desc_Local] end),
    CONSTRAINT [ProdProps_FK_PropId] PRIMARY KEY CLUSTERED ([Prop_Id] ASC),
    CONSTRAINT [ProdProp_FK_FamilyId] FOREIGN KEY ([Product_Family_Id]) REFERENCES [dbo].[Product_Family] ([Product_Family_Id]),
    CONSTRAINT [ProdProps_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [ProductProp_FK_PropTypeId] FOREIGN KEY ([Property_Type_Id]) REFERENCES [dbo].[Property_Types] ([Property_Type_Id]),
    CONSTRAINT [ProdProps_UC_PropDescLocal] UNIQUE NONCLUSTERED ([Prop_Desc_Local] ASC)
);


GO
CREATE TRIGGER [dbo].[Product_Properties_History_Ins]
 ON  [dbo].[Product_Properties]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 425
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Properties_History
 	  	   (Auto_Sync_Chars,Comment_Id,Default_Size,Eng_Units,External_Link,Group_Id,Is_Hidden,Is_Unit_Specific,Product_Family_Id,Prop_Desc,Prop_Id,Property_Order,Property_Type_Id,PU_Id,Tag,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Auto_Sync_Chars,a.Comment_Id,a.Default_Size,a.Eng_Units,a.External_Link,a.Group_Id,a.Is_Hidden,a.Is_Unit_Specific,a.Product_Family_Id,a.Prop_Desc,a.Prop_Id,a.Property_Order,a.Property_Type_Id,a.PU_Id,a.Tag,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Properties_History_Del]
 ON  [dbo].[Product_Properties]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 425
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Properties_History
 	  	   (Auto_Sync_Chars,Comment_Id,Default_Size,Eng_Units,External_Link,Group_Id,Is_Hidden,Is_Unit_Specific,Product_Family_Id,Prop_Desc,Prop_Id,Property_Order,Property_Type_Id,PU_Id,Tag,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Auto_Sync_Chars,a.Comment_Id,a.Default_Size,a.Eng_Units,a.External_Link,a.Group_Id,a.Is_Hidden,a.Is_Unit_Specific,a.Product_Family_Id,a.Prop_Desc,a.Prop_Id,a.Property_Order,a.Property_Type_Id,a.PU_Id,a.Tag,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Product_Properties_TableFieldValue_Del]
 ON  [dbo].[Product_Properties]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Prop_Id
 WHERE tfv.TableId = 54

GO
CREATE TRIGGER [dbo].[Product_Properties_History_Upd]
 ON  [dbo].[Product_Properties]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 425
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Properties_History
 	  	   (Auto_Sync_Chars,Comment_Id,Default_Size,Eng_Units,External_Link,Group_Id,Is_Hidden,Is_Unit_Specific,Product_Family_Id,Prop_Desc,Prop_Id,Property_Order,Property_Type_Id,PU_Id,Tag,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Auto_Sync_Chars,a.Comment_Id,a.Default_Size,a.Eng_Units,a.External_Link,a.Group_Id,a.Is_Hidden,a.Is_Unit_Specific,a.Product_Family_Id,a.Prop_Desc,a.Prop_Id,a.Property_Order,a.Property_Type_Id,a.PU_Id,a.Tag,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Product_Properties_Del ON dbo.Product_Properties
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Product_Properties_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Product_Properties_Del_Cursor 
--
--
Fetch_Product_Properties_Del:
FETCH NEXT FROM Product_Properties_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Product_Properties_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Product_Properties_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Product_Properties_Del_Cursor 
