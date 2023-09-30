CREATE TABLE [dbo].[Defect_Details] (
    [Defect_Detail_Id]    INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Action_Comment_Id]   INT        NULL,
    [Action1]             INT        NULL,
    [Action2]             INT        NULL,
    [Action3]             INT        NULL,
    [Action4]             INT        NULL,
    [Amount]              FLOAT (53) NULL,
    [Cause_Comment_Id]    INT        NULL,
    [Cause1]              INT        NULL,
    [Cause2]              INT        NULL,
    [Cause3]              INT        NULL,
    [Cause4]              INT        NULL,
    [Defect_Type_Id]      INT        NULL,
    [Dimension_A]         FLOAT (53) NULL,
    [Dimension_X]         FLOAT (53) NULL,
    [Dimension_Y]         FLOAT (53) NULL,
    [Dimension_Z]         FLOAT (53) NULL,
    [End_Position_Y]      FLOAT (53) NULL,
    [End_Time]            DATETIME   NULL,
    [Entry_On]            DATETIME   NOT NULL,
    [Event_Id]            INT        NULL,
    [Event_Subtype_Id]    INT        NULL,
    [PU_ID]               INT        NULL,
    [Repeat]              INT        NULL,
    [Research_Close_Date] DATETIME   NULL,
    [Research_Comment_Id] INT        NULL,
    [Research_Open_Date]  DATETIME   NULL,
    [Research_Status_Id]  INT        NULL,
    [Research_User_Id]    INT        NULL,
    [Severity]            INT        NULL,
    [Source_PU_Id]        INT        NULL,
    [Start_Coordinate_A]  FLOAT (53) NULL,
    [Start_Coordinate_X]  FLOAT (53) NULL,
    [Start_Coordinate_Y]  FLOAT (53) NULL,
    [Start_Coordinate_Z]  FLOAT (53) NULL,
    [Start_Time]          DATETIME   NULL,
    [User_Id]             INT        NOT NULL,
    CONSTRAINT [DefecDet_PK_DefectDetId] PRIMARY KEY NONCLUSTERED ([Defect_Detail_Id] ASC),
    CONSTRAINT [Defect_Details_FK_RUserId] FOREIGN KEY ([Research_User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE NONCLUSTERED INDEX [DefectDet_By_EventId]
    ON [dbo].[Defect_Details]([Event_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [DefectDet_PK_PUIdEventSTId]
    ON [dbo].[Defect_Details]([PU_ID] ASC, [Event_Subtype_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [DefectDetails_IDX_PUIdDefectTypeId]
    ON [dbo].[Defect_Details]([PU_ID] ASC, [Defect_Type_Id] ASC);


GO
CREATE TRIGGER [dbo].[Defect_Details_History_Upd]
 ON  [dbo].[Defect_Details]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 406
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Defect_Details_History
 	  	   (Action_Comment_Id,Action1,Action2,Action3,Action4,Amount,Cause_Comment_Id,Cause1,Cause2,Cause3,Cause4,Defect_Detail_Id,Defect_Type_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,End_Position_Y,End_Time,Entry_On,Event_Id,Event_Subtype_Id,PU_ID,Repeat,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Severity,Source_PU_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action1,a.Action2,a.Action3,a.Action4,a.Amount,a.Cause_Comment_Id,a.Cause1,a.Cause2,a.Cause3,a.Cause4,a.Defect_Detail_Id,a.Defect_Type_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.End_Position_Y,a.End_Time,a.Entry_On,a.Event_Id,a.Event_Subtype_Id,a.PU_ID,a.Repeat,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Severity,a.Source_PU_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Defect_Details_History_Ins]
 ON  [dbo].[Defect_Details]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 406
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Defect_Details_History
 	  	   (Action_Comment_Id,Action1,Action2,Action3,Action4,Amount,Cause_Comment_Id,Cause1,Cause2,Cause3,Cause4,Defect_Detail_Id,Defect_Type_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,End_Position_Y,End_Time,Entry_On,Event_Id,Event_Subtype_Id,PU_ID,Repeat,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Severity,Source_PU_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action1,a.Action2,a.Action3,a.Action4,a.Amount,a.Cause_Comment_Id,a.Cause1,a.Cause2,a.Cause3,a.Cause4,a.Defect_Detail_Id,a.Defect_Type_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.End_Position_Y,a.End_Time,a.Entry_On,a.Event_Id,a.Event_Subtype_Id,a.PU_ID,a.Repeat,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Severity,a.Source_PU_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Defect_Details_Del 
  ON dbo.Defect_Details 
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id1 int,
 	 @Comment_Id2 int,
 	 @Comment_Id3 int
DECLARE Defect_Details_Del_Cursor CURSOR
  FOR SELECT Research_Comment_Id, Action_Comment_Id, Cause_Comment_Id FROM DELETED
  FOR READ ONLY
OPEN Defect_Details_Del_Cursor 
--
--
Fetch_Next_Defect_Details:
FETCH NEXT FROM Defect_Details_Del_Cursor INTO @Comment_Id1, @Comment_Id2, @Comment_Id3
IF @@FETCH_STATUS = 0
  BEGIN
    IF @Comment_Id1 IS NOT NULL 
      BEGIN
        Delete From Comments Where TopOfChain_Id = @Comment_Id1 
        Delete From Comments Where Comment_Id = @Comment_Id1 
      END
    IF @Comment_Id2 IS NOT NULL 
      BEGIN
        Delete From Comments Where TopOfChain_Id = @Comment_Id2
        Delete From Comments Where Comment_Id = @Comment_Id2
      END
    IF @Comment_Id3 IS NOT NULL 
      BEGIN
        Delete From Comments Where TopOfChain_Id = @Comment_Id3
        Delete From Comments Where Comment_Id = @Comment_Id3 
      END
 	   GOTO Fetch_Next_Defect_Details
 	 END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Defect_Details_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Defect_Details_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Defect_Details_History_Del]
 ON  [dbo].[Defect_Details]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 406
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Defect_Details_History
 	  	   (Action_Comment_Id,Action1,Action2,Action3,Action4,Amount,Cause_Comment_Id,Cause1,Cause2,Cause3,Cause4,Defect_Detail_Id,Defect_Type_Id,Dimension_A,Dimension_X,Dimension_Y,Dimension_Z,End_Position_Y,End_Time,Entry_On,Event_Id,Event_Subtype_Id,PU_ID,Repeat,Research_Close_Date,Research_Comment_Id,Research_Open_Date,Research_Status_Id,Research_User_Id,Severity,Source_PU_Id,Start_Coordinate_A,Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Action_Comment_Id,a.Action1,a.Action2,a.Action3,a.Action4,a.Amount,a.Cause_Comment_Id,a.Cause1,a.Cause2,a.Cause3,a.Cause4,a.Defect_Detail_Id,a.Defect_Type_Id,a.Dimension_A,a.Dimension_X,a.Dimension_Y,a.Dimension_Z,a.End_Position_Y,a.End_Time,a.Entry_On,a.Event_Id,a.Event_Subtype_Id,a.PU_ID,a.Repeat,a.Research_Close_Date,a.Research_Comment_Id,a.Research_Open_Date,a.Research_Status_Id,a.Research_User_Id,a.Severity,a.Source_PU_Id,a.Start_Coordinate_A,a.Start_Coordinate_X,a.Start_Coordinate_Y,a.Start_Coordinate_Z,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
