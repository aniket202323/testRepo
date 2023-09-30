CREATE TABLE [dbo].[PrdExec_Path_Unit_Starts] (
    [PEPUS_Id]   INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id] INT      NULL,
    [End_Time]   DATETIME NULL,
    [Path_Id]    INT      NOT NULL,
    [PU_Id]      INT      NOT NULL,
    [Start_Time] DATETIME NOT NULL,
    [User_Id]    INT      NULL,
    CONSTRAINT [PrdExecPathsUStarts_PK_PEPUSId] PRIMARY KEY NONCLUSTERED ([PEPUS_Id] ASC),
    CONSTRAINT [PrdExec_Path_Unit_Starts_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [PrdExecPathsUStarts_FK_PrdExecPath] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id])
);


GO
CREATE CLUSTERED INDEX [PrdExecPathUnitStarts_IDX_PUIdSTime]
    ON [dbo].[PrdExec_Path_Unit_Starts]([PU_Id] ASC, [Start_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [PrdExecPathUnitStarts_IDX_PathId]
    ON [dbo].[PrdExec_Path_Unit_Starts]([Path_Id] ASC);


GO
CREATE TRIGGER [dbo].[PrdExec_Path_Unit_Starts_History_Upd]
 ON  [dbo].[PrdExec_Path_Unit_Starts]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 420
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into PrdExec_Path_Unit_Starts_History
 	  	   (Comment_Id,End_Time,Path_Id,PEPUS_Id,PU_Id,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.End_Time,a.Path_Id,a.PEPUS_Id,a.PU_Id,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[PrdExec_Path_Unit_Starts_History_Ins]
 ON  [dbo].[PrdExec_Path_Unit_Starts]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 420
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into PrdExec_Path_Unit_Starts_History
 	  	   (Comment_Id,End_Time,Path_Id,PEPUS_Id,PU_Id,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.End_Time,a.Path_Id,a.PEPUS_Id,a.PU_Id,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.PrdExec_Path_Unit_Starts_Del
  ON dbo.PrdExec_Path_Unit_Starts
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE PrdExec_Path_Unit_Starts_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN PrdExec_Path_Unit_Starts_Del_Cursor 
--
--
Fetch_Next_PrdExec_Path_Unit_Starts_Del:
FETCH NEXT FROM PrdExec_Path_Unit_Starts_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Next_PrdExec_Path_Unit_Starts_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in PrdExec_Path_Unit_Starts_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE PrdExec_Path_Unit_Starts_Del_Cursor 

GO
CREATE TRIGGER [dbo].[PrdExec_Path_Unit_Starts_History_Del]
 ON  [dbo].[PrdExec_Path_Unit_Starts]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 420
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into PrdExec_Path_Unit_Starts_History
 	  	   (Comment_Id,End_Time,Path_Id,PEPUS_Id,PU_Id,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.End_Time,a.Path_Id,a.PEPUS_Id,a.PU_Id,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
