CREATE TABLE [dbo].[Production_Setup_Detail] (
    [PP_Setup_Detail_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]         INT           NULL,
    [Element_Number]     INT           NOT NULL,
    [Element_Status]     TINYINT       NOT NULL,
    [Extended_Info]      VARCHAR (255) NULL,
    [Order_Line_Id]      INT           NULL,
    [PP_Setup_Id]        INT           NOT NULL,
    [Prod_Id]            INT           NULL,
    [Target_Dimension_A] REAL          NULL,
    [Target_Dimension_X] REAL          NULL,
    [Target_Dimension_Y] REAL          NULL,
    [Target_Dimension_Z] REAL          NULL,
    [User_General_1]     VARCHAR (255) NULL,
    [User_General_2]     VARCHAR (255) NULL,
    [User_General_3]     VARCHAR (255) NULL,
    [User_Id]            INT           NULL,
    CONSTRAINT [Production_SetupDet_PK_PPDetId] PRIMARY KEY CLUSTERED ([PP_Setup_Detail_Id] ASC),
    CONSTRAINT [FK_ProdSetupDetails_ProdSetup] FOREIGN KEY ([PP_Setup_Id]) REFERENCES [dbo].[Production_Setup] ([PP_Setup_Id])
);


GO
CREATE NONCLUSTERED INDEX [ProductionSetupDetail_IDX_PPSetupIdElementNumber]
    ON [dbo].[Production_Setup_Detail]([PP_Setup_Id] ASC, [Element_Number] ASC);


GO
CREATE TRIGGER [dbo].[Production_Setup_Detail_History_Ins]
 ON  [dbo].[Production_Setup_Detail]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 412
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Production_Setup_Detail_History
 	  	   (Comment_Id,Element_Number,Element_Status,Extended_Info,Order_Line_Id,PP_Setup_Detail_Id,PP_Setup_Id,Prod_Id,Target_Dimension_A,Target_Dimension_X,Target_Dimension_Y,Target_Dimension_Z,User_General_1,User_General_2,User_General_3,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Element_Number,a.Element_Status,a.Extended_Info,a.Order_Line_Id,a.PP_Setup_Detail_Id,a.PP_Setup_Id,a.Prod_Id,a.Target_Dimension_A,a.Target_Dimension_X,a.Target_Dimension_Y,a.Target_Dimension_Z,a.User_General_1,a.User_General_2,a.User_General_3,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Production_Setup_Detail_Ins
  ON dbo.Production_Setup_Detail
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id int
Declare Production_Setup_Detail_Ins_Cursor INSENSITIVE CURSOR
  For (Select PP_Setup_Detail_Id From INSERTED)
  For Read Only
  Open Production_Setup_Detail_Ins_Cursor  
Fetch_Loop:
  Fetch Next From Production_Setup_Detail_Ins_Cursor Into @@Id
  If (@@Fetch_Status = 0)
    Begin
      Execute spServer_CmnAddScheduledTask @@Id,9
      Goto Fetch_Loop
    End
Close Production_Setup_Detail_Ins_Cursor
Deallocate Production_Setup_Detail_Ins_Cursor

GO
CREATE TRIGGER dbo.Production_Setup_Detail_Upd
  ON dbo.Production_Setup_Detail
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id int
Declare Production_Setup_Detail_Upd_Cursor INSENSITIVE CURSOR
  For (Select PP_Setup_Detail_Id From INSERTED)
  For Read Only
  Open Production_Setup_Detail_Upd_Cursor  
Fetch_Loop:
  Fetch Next From Production_Setup_Detail_Upd_Cursor Into @@Id
  If (@@Fetch_Status = 0)
    Begin
      Execute spServer_CmnAddScheduledTask @@Id,9
      Goto Fetch_Loop
    End
Close Production_Setup_Detail_Upd_Cursor
Deallocate Production_Setup_Detail_Upd_Cursor

GO
CREATE TRIGGER dbo.Production_Setup_Detail_Del
  ON dbo.Production_Setup_Detail
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id int,
 	 @Comment_Id int
Declare Production_Setup_Detail_Del_Cursor INSENSITIVE CURSOR
  For (Select PP_Setup_Detail_Id, Comment_Id From DELETED)
  For Read Only
  Open Production_Setup_Detail_Del_Cursor  
Fetch_Loop:
  Fetch Next From Production_Setup_Detail_Del_Cursor Into @@Id,@Comment_Id
  If (@@Fetch_Status = 0)
    Begin
      If @Comment_Id is NOT NULL 
        BEGIN
          Delete From Comments Where TopOfChain_Id = @Comment_Id 
          Delete From Comments Where Comment_Id = @Comment_Id   
        END
      Execute spServer_CmnRemoveScheduledTask @@Id,9
      Goto Fetch_Loop
    End
Close Production_Setup_Detail_Del_Cursor
Deallocate Production_Setup_Detail_Del_Cursor

GO
CREATE TRIGGER [dbo].[Production_Setup_Detail_TableFieldValue_Del]
 ON  [dbo].[Production_Setup_Detail]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.PP_Setup_Detail_Id
 WHERE tfv.TableId = 9

GO
CREATE TRIGGER [dbo].[Production_Setup_Detail_History_Del]
 ON  [dbo].[Production_Setup_Detail]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 412
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Production_Setup_Detail_History
 	  	   (Comment_Id,Element_Number,Element_Status,Extended_Info,Order_Line_Id,PP_Setup_Detail_Id,PP_Setup_Id,Prod_Id,Target_Dimension_A,Target_Dimension_X,Target_Dimension_Y,Target_Dimension_Z,User_General_1,User_General_2,User_General_3,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Element_Number,a.Element_Status,a.Extended_Info,a.Order_Line_Id,a.PP_Setup_Detail_Id,a.PP_Setup_Id,a.Prod_Id,a.Target_Dimension_A,a.Target_Dimension_X,a.Target_Dimension_Y,a.Target_Dimension_Z,a.User_General_1,a.User_General_2,a.User_General_3,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Production_Setup_Detail_History_Upd]
 ON  [dbo].[Production_Setup_Detail]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 412
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Production_Setup_Detail_History
 	  	   (Comment_Id,Element_Number,Element_Status,Extended_Info,Order_Line_Id,PP_Setup_Detail_Id,PP_Setup_Id,Prod_Id,Target_Dimension_A,Target_Dimension_X,Target_Dimension_Y,Target_Dimension_Z,User_General_1,User_General_2,User_General_3,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Element_Number,a.Element_Status,a.Extended_Info,a.Order_Line_Id,a.PP_Setup_Detail_Id,a.PP_Setup_Id,a.Prod_Id,a.Target_Dimension_A,a.Target_Dimension_X,a.Target_Dimension_Y,a.Target_Dimension_Z,a.User_General_1,a.User_General_2,a.User_General_3,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
