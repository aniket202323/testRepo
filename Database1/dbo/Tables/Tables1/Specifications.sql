CREATE TABLE [dbo].[Specifications] (
    [Spec_Id]               INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Array_Size]            INT                       NULL,
    [Comment_Id]            INT                       NULL,
    [Data_Type_Id]          INT                       NOT NULL,
    [Eng_Units]             VARCHAR (50)              NULL,
    [Extended_Info]         VARCHAR (255)             NULL,
    [External_Link]         [dbo].[Varchar_Ext_Link]  NULL,
    [Group_Id]              INT                       NULL,
    [Parent_Id]             INT                       NULL,
    [Prop_Id]               INT                       NOT NULL,
    [Retention_Limit]       INT                       NULL,
    [Spec_Desc_Global]      [dbo].[Varchar_Desc]      NULL,
    [Spec_Desc_Local]       [dbo].[Varchar_Desc]      NOT NULL,
    [Spec_Order]            INT                       NULL,
    [Spec_Precision]        [dbo].[Tinyint_Precision] NULL,
    [Specification_Type_Id] INT                       NULL,
    [Tag]                   VARCHAR (50)              NULL,
    [Unit_Conversion]       REAL                      NULL,
    [Var_Id]                INT                       NULL,
    [Spec_Desc]             AS                        (case when (@@options&(512))=(0) then isnull([Spec_Desc_Global],[Spec_Desc_Local]) else [Spec_Desc_Local] end),
    CONSTRAINT [PK___6__12] PRIMARY KEY CLUSTERED ([Spec_Id] ASC),
    CONSTRAINT [Specs_FK_DataTypeId] FOREIGN KEY ([Data_Type_Id]) REFERENCES [dbo].[Data_Type] ([Data_Type_Id]),
    CONSTRAINT [Specs_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [Specs_FK_PropId] FOREIGN KEY ([Prop_Id]) REFERENCES [dbo].[Product_Properties] ([Prop_Id]),
    CONSTRAINT [Specs_UC_PropIdSpecDescLocal] UNIQUE NONCLUSTERED ([Prop_Id] ASC, [Spec_Desc_Local] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Specifications_UX_SpecOrder]
    ON [dbo].[Specifications]([Spec_Order] ASC);


GO
CREATE NONCLUSTERED INDEX [Specifications_IDX_Tag]
    ON [dbo].[Specifications]([Tag] ASC);


GO
CREATE NONCLUSTERED INDEX [Specifications_IDX_DataTypeId]
    ON [dbo].[Specifications]([Data_Type_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Specifications_UC_DescLocal]
    ON [dbo].[Specifications]([Spec_Desc_Local] ASC);


GO
CREATE TRIGGER [dbo].[Specifications_TableFieldValue_Del]
 ON  [dbo].[Specifications]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Spec_Id
 WHERE tfv.TableId = 40

GO
CREATE TRIGGER [dbo].[Specifications_History_Del]
 ON  [dbo].[Specifications]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 450
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Specification_History
 	  	   (Array_Size,Comment_Id,Data_Type_Id,Eng_Units,Extended_Info,External_Link,Group_Id,Parent_Id,Prop_Id,Retention_Limit,Spec_Desc,Spec_Id,Spec_Order,Spec_Precision,Specification_Type_Id,Tag,Unit_Conversion,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Array_Size,a.Comment_Id,a.Data_Type_Id,a.Eng_Units,a.Extended_Info,a.External_Link,a.Group_Id,a.Parent_Id,a.Prop_Id,a.Retention_Limit,a.Spec_Desc,a.Spec_Id,a.Spec_Order,a.Spec_Precision,a.Specification_Type_Id,a.Tag,a.Unit_Conversion,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER dbo.Specifications_Del ON dbo.Specifications
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Specifications_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Specifications_Del_Cursor 
--
--
Fetch_Specifications_Del:
FETCH NEXT FROM Specifications_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Specifications_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Specifications_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Specifications_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Specifications_History_Upd]
 ON  [dbo].[Specifications]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 450
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Specification_History
 	  	   (Array_Size,Comment_Id,Data_Type_Id,Eng_Units,Extended_Info,External_Link,Group_Id,Parent_Id,Prop_Id,Retention_Limit,Spec_Desc,Spec_Id,Spec_Order,Spec_Precision,Specification_Type_Id,Tag,Unit_Conversion,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Array_Size,a.Comment_Id,a.Data_Type_Id,a.Eng_Units,a.Extended_Info,a.External_Link,a.Group_Id,a.Parent_Id,a.Prop_Id,a.Retention_Limit,a.Spec_Desc,a.Spec_Id,a.Spec_Order,a.Spec_Precision,a.Specification_Type_Id,a.Tag,a.Unit_Conversion,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Specifications_History_Ins]
 ON  [dbo].[Specifications]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 450
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Specification_History
 	  	   (Array_Size,Comment_Id,Data_Type_Id,Eng_Units,Extended_Info,External_Link,Group_Id,Parent_Id,Prop_Id,Retention_Limit,Spec_Desc,Spec_Id,Spec_Order,Spec_Precision,Specification_Type_Id,Tag,Unit_Conversion,Var_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Array_Size,a.Comment_Id,a.Data_Type_Id,a.Eng_Units,a.Extended_Info,a.External_Link,a.Group_Id,a.Parent_Id,a.Prop_Id,a.Retention_Limit,a.Spec_Desc,a.Spec_Id,a.Spec_Order,a.Spec_Precision,a.Specification_Type_Id,a.Tag,a.Unit_Conversion,a.Var_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
