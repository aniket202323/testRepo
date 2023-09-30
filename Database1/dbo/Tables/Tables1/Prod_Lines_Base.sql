CREATE TABLE [dbo].[Prod_Lines_Base] (
    [PL_Id]              INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]         INT                      NULL,
    [Dept_Id]            INT                      NULL,
    [Extended_Info]      VARCHAR (255)            NULL,
    [External_Link]      [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]           INT                      NULL,
    [OverView_Positions] TEXT                     NULL,
    [PL_Desc]            [dbo].[Varchar_Desc]     NOT NULL,
    [PL_Desc_Global]     VARCHAR (50)             NULL,
    [Tag]                VARCHAR (50)             NULL,
    [User_Defined1]      VARCHAR (255)            NULL,
    [User_Defined2]      VARCHAR (255)            NULL,
    [User_Defined3]      VARCHAR (255)            NULL,
    [LineOEEMode]        INT                      NULL,
    CONSTRAINT [Prod_Lines_PK_PLId] PRIMARY KEY CLUSTERED ([PL_Id] ASC),
    CONSTRAINT [Prod_Lines_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [ProdLines_FK_Departments] FOREIGN KEY ([Dept_Id]) REFERENCES [dbo].[Departments_Base] ([Dept_Id]),
    CONSTRAINT [Prod_Lines_UC_PLDesc] UNIQUE NONCLUSTERED ([PL_Desc] ASC)
);


GO
CREATE TRIGGER [dbo].[Prod_Lines_History_Upd]
 ON  [dbo].[Prod_Lines_Base]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 423
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Prod_Line_History
 	  	   (Comment_Id,Dept_Id,Extended_Info,External_Link,Group_Id,LineOEEMode,PL_Desc,PL_Id,Tag,User_Defined1,User_Defined2,User_Defined3,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Dept_Id,a.Extended_Info,a.External_Link,a.Group_Id,a.LineOEEMode,a.PL_Desc,a.PL_Id,a.Tag,a.User_Defined1,a.User_Defined2,a.User_Defined3,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Prod_Lines_History_Del]
 ON  [dbo].[Prod_Lines_Base]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 423
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Prod_Line_History
 	  	   (Comment_Id,Dept_Id,Extended_Info,External_Link,Group_Id,LineOEEMode,PL_Desc,PL_Id,Tag,User_Defined1,User_Defined2,User_Defined3,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Dept_Id,a.Extended_Info,a.External_Link,a.Group_Id,a.LineOEEMode,a.PL_Desc,a.PL_Id,a.Tag,a.User_Defined1,a.User_Defined2,a.User_Defined3,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Prod_Lines_History_Ins]
 ON  [dbo].[Prod_Lines_Base]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 423
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Prod_Line_History
 	  	   (Comment_Id,Dept_Id,Extended_Info,External_Link,Group_Id,LineOEEMode,PL_Desc,PL_Id,Tag,User_Defined1,User_Defined2,User_Defined3,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Dept_Id,a.Extended_Info,a.External_Link,a.Group_Id,a.LineOEEMode,a.PL_Desc,a.PL_Id,a.Tag,a.User_Defined1,a.User_Defined2,a.User_Defined3,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Prod_Lines_TableFieldValue_Del]
 ON  [dbo].[Prod_Lines_Base]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.PL_Id
 WHERE tfv.TableId = 18

GO
CREATE TRIGGER dbo.Prod_Lines_Del 
  ON dbo.Prod_Lines_Base
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Prod_Lines_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Prod_Lines_Del_Cursor 
--
--
Fetch_Next_Prod_Lines_Del:
FETCH NEXT FROM Prod_Lines_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Next_Prod_Lines_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Prod_Lines_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Prod_Lines_Del_Cursor 
