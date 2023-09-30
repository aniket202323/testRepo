CREATE TABLE [dbo].[Product_Groups] (
    [Product_Grp_Id]          INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]              INT                      NULL,
    [External_Link]           [dbo].[Varchar_Ext_Link] NULL,
    [Tag]                     VARCHAR (50)             NULL,
    [Product_Grp_Desc_Global] [dbo].[Varchar_Desc]     NULL,
    [Product_Grp_Desc_Local]  [dbo].[Varchar_Desc]     NOT NULL,
    [Product_Grp_Desc]        AS                       (case when (@@options&(512))=(0) then isnull([Product_Grp_Desc_Global],[Product_Grp_Desc_Local]) else [Product_Grp_Desc_Local] end),
    CONSTRAINT [ProdGrps_PK_ProdGrpId] PRIMARY KEY CLUSTERED ([Product_Grp_Id] ASC),
    CONSTRAINT [ProductGroups_By_DescriptionLocal] UNIQUE NONCLUSTERED ([Product_Grp_Desc_Local] ASC)
);


GO
CREATE TRIGGER dbo.Product_Groups_Del ON dbo.Product_Groups
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Product_Groups_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Product_Groups_Del_Cursor 
--
--
Fetch_Next_Product_Groups_Del:
FETCH NEXT FROM Product_Groups_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Next_Product_Groups_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Product_Groups_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Product_Groups_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Product_Groups_TableFieldValue_Del]
 ON  [dbo].[Product_Groups]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Product_Grp_Id
 WHERE tfv.TableId = 22
