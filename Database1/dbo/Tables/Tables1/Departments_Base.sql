CREATE TABLE [dbo].[Departments_Base] (
    [Dept_Id]          INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]       INT           NULL,
    [Dept_Desc]        VARCHAR (50)  NOT NULL,
    [Dept_Desc_Global] VARCHAR (50)  NULL,
    [Extended_Info]    VARCHAR (255) NULL,
    [Tag]              VARCHAR (255) NULL,
    [Time_Zone]        VARCHAR (100) NULL,
    CONSTRAINT [Departments_PK_DeptId] PRIMARY KEY CLUSTERED ([Dept_Id] ASC),
    CONSTRAINT [Departments_UC_DeptDesc] UNIQUE NONCLUSTERED ([Dept_Desc] ASC)
);


GO
CREATE TRIGGER [dbo].[Departments_History_Del]
 ON  [dbo].[Departments_Base]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 446
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Department_History
 	  	   (Comment_Id,Dept_Desc,Dept_Id,Extended_Info,Tag,Time_Zone,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Dept_Desc,a.Dept_Id,a.Extended_Info,a.Tag,a.Time_Zone,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Departments_History_Upd]
 ON  [dbo].[Departments_Base]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 446
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Department_History
 	  	   (Comment_Id,Dept_Desc,Dept_Id,Extended_Info,Tag,Time_Zone,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Dept_Desc,a.Dept_Id,a.Extended_Info,a.Tag,a.Time_Zone,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Departments_History_Ins]
 ON  [dbo].[Departments_Base]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 446
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Department_History
 	  	   (Comment_Id,Dept_Desc,Dept_Id,Extended_Info,Tag,Time_Zone,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Dept_Desc,a.Dept_Id,a.Extended_Info,a.Tag,a.Time_Zone,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Departments_TableFieldValue_Del]
 ON  [dbo].[Departments_Base]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Dept_Id
 WHERE tfv.TableId = 17
