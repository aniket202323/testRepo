CREATE TABLE [dbo].[Prdexec_Paths] (
    [Path_Id]                INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]             INT          NULL,
    [Create_Children]        BIT          CONSTRAINT [Prdexec_Paths_DF_Create_Children] DEFAULT ((0)) NOT NULL,
    [Is_Line_Production]     BIT          NOT NULL,
    [Is_Schedule_Controlled] BIT          NOT NULL,
    [Path_Code]              VARCHAR (50) NOT NULL,
    [Path_Desc]              VARCHAR (50) NOT NULL,
    [PL_Id]                  INT          NOT NULL,
    [Schedule_Control_Type]  TINYINT      NULL,
    CONSTRAINT [PrdexecPaths_PK_PathId] PRIMARY KEY CLUSTERED ([Path_Id] ASC),
    CONSTRAINT [PrdexecPaths_FK_ProdLines] FOREIGN KEY ([PL_Id]) REFERENCES [dbo].[Prod_Lines_Base] ([PL_Id]),
    CONSTRAINT [PrdexecPaths_UC_PathCode] UNIQUE NONCLUSTERED ([Path_Code] ASC)
);


GO
CREATE TRIGGER [dbo].[PrdExec_Paths_History_Ins]
 ON  [dbo].[PrdExec_Paths]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 448
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into PrdExec_Path_History
 	  	   (Comment_Id,Create_Children,Is_Line_Production,Is_Schedule_Controlled,Path_Code,Path_Desc,Path_Id,PL_Id,Schedule_Control_Type,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Create_Children,a.Is_Line_Production,a.Is_Schedule_Controlled,a.Path_Code,a.Path_Desc,a.Path_Id,a.PL_Id,a.Schedule_Control_Type,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[PrdExec_Paths_History_Del]
 ON  [dbo].[PrdExec_Paths]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 448
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into PrdExec_Path_History
 	  	   (Comment_Id,Create_Children,Is_Line_Production,Is_Schedule_Controlled,Path_Code,Path_Desc,Path_Id,PL_Id,Schedule_Control_Type,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Create_Children,a.Is_Line_Production,a.Is_Schedule_Controlled,a.Path_Code,a.Path_Desc,a.Path_Id,a.PL_Id,a.Schedule_Control_Type,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[PrdExec_Paths_History_Upd]
 ON  [dbo].[PrdExec_Paths]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 448
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into PrdExec_Path_History
 	  	   (Comment_Id,Create_Children,Is_Line_Production,Is_Schedule_Controlled,Path_Code,Path_Desc,Path_Id,PL_Id,Schedule_Control_Type,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Create_Children,a.Is_Line_Production,a.Is_Schedule_Controlled,a.Path_Code,a.Path_Desc,a.Path_Id,a.PL_Id,a.Schedule_Control_Type,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[PrdExec_Paths_TableFieldValue_Del]
 ON  [dbo].[PrdExec_Paths]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Path_Id
 WHERE tfv.TableId = 13
