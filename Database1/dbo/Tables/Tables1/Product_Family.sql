CREATE TABLE [dbo].[Product_Family] (
    [Product_Family_Id]          INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]                 INT                      NULL,
    [External_Link]              [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]                   INT                      NULL,
    [Product_Family_Desc_Global] [dbo].[Varchar_Desc]     NULL,
    [Product_Family_Desc_Local]  [dbo].[Varchar_Desc]     NOT NULL,
    [Product_Family_Desc]        AS                       (case when (@@options&(512))=(0) then isnull([Product_Family_Desc_Global],[Product_Family_Desc_Local]) else [Product_Family_Desc_Local] end),
    CONSTRAINT [ProductFamily_PK_ProdFamilyId] PRIMARY KEY CLUSTERED ([Product_Family_Id] ASC),
    CONSTRAINT [ProductFamily_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [ProductFamily_UC_ProdDescLocal] UNIQUE NONCLUSTERED ([Product_Family_Desc_Local] ASC)
);


GO
CREATE TRIGGER [dbo].[Product_Family_History_Del]
 ON  [dbo].[Product_Family]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 449
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_Family_History
 	  	   (Comment_Id,External_Link,Group_Id,Product_Family_Desc,Product_Family_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.External_Link,a.Group_Id,a.Product_Family_Desc,a.Product_Family_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Product_Family_TableFieldValue_Del]
 ON  [dbo].[Product_Family]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Product_Family_Id
 WHERE tfv.TableId = 21

GO
CREATE TRIGGER [dbo].[Product_Family_History_Upd]
 ON  [dbo].[Product_Family]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 449
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_Family_History
 	  	   (Comment_Id,External_Link,Group_Id,Product_Family_Desc,Product_Family_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.External_Link,a.Group_Id,a.Product_Family_Desc,a.Product_Family_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Product_Family_History_Ins]
 ON  [dbo].[Product_Family]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 449
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_Family_History
 	  	   (Comment_Id,External_Link,Group_Id,Product_Family_Desc,Product_Family_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.External_Link,a.Group_Id,a.Product_Family_Desc,a.Product_Family_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
