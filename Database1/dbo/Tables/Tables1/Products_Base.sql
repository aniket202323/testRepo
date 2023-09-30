CREATE TABLE [dbo].[Products_Base] (
    [Prod_Id]                         INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alias_For_Product]               INT                       NULL,
    [Comment_Id]                      INT                       NULL,
    [Event_Esignature_Level]          INT                       NULL,
    [Extended_Info]                   VARCHAR (255)             NULL,
    [External_Link]                   [dbo].[Varchar_Ext_Link]  NULL,
    [Is_Active_Product]               TINYINT                   NULL,
    [Is_Manufacturing_Product]        TINYINT                   NULL,
    [Is_Sales_Product]                TINYINT                   NULL,
    [Prod_Code]                       [dbo].[Varchar_Prod_Code] NOT NULL,
    [Prod_Desc]                       [dbo].[Varchar_Desc]      NOT NULL,
    [Prod_Desc_Global]                VARCHAR (50)              NULL,
    [Product_Change_Esignature_Level] INT                       NULL,
    [Product_Family_Id]               INT                       CONSTRAINT [Products_DF_ProdFamilyId] DEFAULT ((1)) NULL,
    [Tag]                             VARCHAR (50)              NULL,
    [Use_Manufacturing_Product]       INT                       NULL,
    CONSTRAINT [PK___7__12] PRIMARY KEY CLUSTERED ([Prod_Id] ASC),
    CONSTRAINT [Products_FK_ProdFamilyId] FOREIGN KEY ([Product_Family_Id]) REFERENCES [dbo].[Product_Family] ([Product_Family_Id]),
    CONSTRAINT [Products_By_Code] UNIQUE NONCLUSTERED ([Prod_Code] ASC)
);


GO
CREATE TRIGGER [dbo].[Products_History_Upd]
 ON  [dbo].[Products_Base]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 424
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Product_History
 	  	   (Alias_For_Product,Comment_Id,Event_Esignature_Level,Extended_Info,External_Link,Is_Active_Product,Is_Manufacturing_Product,Is_Sales_Product,Prod_Code,Prod_Desc,Prod_Id,Product_Change_Esignature_Level,Product_Family_Id,Tag,Use_Manufacturing_Product,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias_For_Product,a.Comment_Id,a.Event_Esignature_Level,a.Extended_Info,a.External_Link,a.Is_Active_Product,a.Is_Manufacturing_Product,a.Is_Sales_Product,a.Prod_Code,a.Prod_Desc,a.Prod_Id,a.Product_Change_Esignature_Level,a.Product_Family_Id,a.Tag,a.Use_Manufacturing_Product,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Products_Base_trg
		ON dbo.Products_Base
		AFTER UPDATE, INSERT, DELETE
	  AS
		BEGIN
			UPDATE dbo.Products_Base_Modified  SET isModified=1;
		END
GO
CREATE TRIGGER dbo.Products_Del ON dbo.Products_Base
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Products_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Products_Del_Cursor 
--
--
Fetch_Products_Del:
FETCH NEXT FROM Products_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Products_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Products_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Products_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Products_History_Ins]
 ON  [dbo].[Products_Base]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 424
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Product_History
 	  	   (Alias_For_Product,Comment_Id,Event_Esignature_Level,Extended_Info,External_Link,Is_Active_Product,Is_Manufacturing_Product,Is_Sales_Product,Prod_Code,Prod_Desc,Prod_Id,Product_Change_Esignature_Level,Product_Family_Id,Tag,Use_Manufacturing_Product,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias_For_Product,a.Comment_Id,a.Event_Esignature_Level,a.Extended_Info,a.External_Link,a.Is_Active_Product,a.Is_Manufacturing_Product,a.Is_Sales_Product,a.Prod_Code,a.Prod_Desc,a.Prod_Id,a.Product_Change_Esignature_Level,a.Product_Family_Id,a.Tag,a.Use_Manufacturing_Product,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Products_History_Del]
 ON  [dbo].[Products_Base]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 424
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Product_History
 	  	   (Alias_For_Product,Comment_Id,Event_Esignature_Level,Extended_Info,External_Link,Is_Active_Product,Is_Manufacturing_Product,Is_Sales_Product,Prod_Code,Prod_Desc,Prod_Id,Product_Change_Esignature_Level,Product_Family_Id,Tag,Use_Manufacturing_Product,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alias_For_Product,a.Comment_Id,a.Event_Esignature_Level,a.Extended_Info,a.External_Link,a.Is_Active_Product,a.Is_Manufacturing_Product,a.Is_Sales_Product,a.Prod_Code,a.Prod_Desc,a.Prod_Id,a.Product_Change_Esignature_Level,a.Product_Family_Id,a.Tag,a.Use_Manufacturing_Product,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Products_TableFieldValue_Del]
 ON  [dbo].[Products_Base]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Prod_Id
 WHERE tfv.TableId = 23
