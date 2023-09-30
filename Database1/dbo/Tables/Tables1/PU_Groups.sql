CREATE TABLE [dbo].[PU_Groups] (
    [PUG_Id]          INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]      INT                      NULL,
    [External_Link]   [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]        INT                      NULL,
    [PU_Id]           INT                      NOT NULL,
    [PUG_Desc_Global] [dbo].[Varchar_Desc]     NULL,
    [PUG_Desc_Local]  [dbo].[Varchar_Desc]     NOT NULL,
    [PUG_Order]       INT                      NOT NULL,
    [PUG_Desc]        AS                       (case when (@@options&(512))=(0) then isnull([PUG_Desc_Global],[PUG_Desc_Local]) else [PUG_Desc_Local] end),
    CONSTRAINT [PU_Groups_PK_PUGId] PRIMARY KEY CLUSTERED ([PUG_Id] ASC),
    CONSTRAINT [PU_Groups_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [PU_Groups_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [PU_Groups_UC_PUIdPUGDescLocal] UNIQUE NONCLUSTERED ([PU_Id] ASC, [PUG_Desc_Local] ASC)
);


GO
CREATE TRIGGER [dbo].[PU_Groups_History_Upd]
 ON  [dbo].[PU_Groups]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 447
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into PU_Group_History
 	  	   (Comment_Id,External_Link,Group_Id,PU_Id,PUG_Desc,PUG_Id,PUG_Order,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.External_Link,a.Group_Id,a.PU_Id,a.PUG_Desc,a.PUG_Id,a.PUG_Order,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.PU_Groups_Del ON dbo.PU_Groups
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE PU_Groups_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN PU_Groups_Del_Cursor 
--
--
Fetch_PU_Groups_Del:
FETCH NEXT FROM PU_Groups_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_PU_Groups_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in PU_Groups_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE PU_Groups_Del_Cursor 

GO
CREATE TRIGGER [dbo].[PU_Groups_History_Ins]
 ON  [dbo].[PU_Groups]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 447
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into PU_Group_History
 	  	   (Comment_Id,External_Link,Group_Id,PU_Id,PUG_Desc,PUG_Id,PUG_Order,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.External_Link,a.Group_Id,a.PU_Id,a.PUG_Desc,a.PUG_Id,a.PUG_Order,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[PU_Groups_TableFieldValue_Del]
 ON  [dbo].[PU_Groups]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.PUG_Id
 WHERE tfv.TableId = 19

GO
CREATE TRIGGER [dbo].[PU_Groups_History_Del]
 ON  [dbo].[PU_Groups]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 447
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into PU_Group_History
 	  	   (Comment_Id,External_Link,Group_Id,PU_Id,PUG_Desc,PUG_Id,PUG_Order,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.External_Link,a.Group_Id,a.PU_Id,a.PUG_Desc,a.PUG_Id,a.PUG_Order,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
