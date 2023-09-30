CREATE TABLE [dbo].[Crew_Schedule] (
    [CS_Id]      INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id] INT          NULL,
    [Crew_Desc]  VARCHAR (10) NOT NULL,
    [End_Time]   DATETIME     NOT NULL,
    [PU_Id]      INT          NOT NULL,
    [Shift_Desc] VARCHAR (10) NOT NULL,
    [Start_Time] DATETIME     NOT NULL,
    [User_Id]    INT          NULL,
    CONSTRAINT [Crew_PK_CSId] PRIMARY KEY NONCLUSTERED ([CS_Id] ASC),
    CONSTRAINT [Crew_FK_PUID] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [CrewSchedule_FK_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Crew_UC_PUStartTime] UNIQUE CLUSTERED ([PU_Id] ASC, [Start_Time] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Crew_IDX_PUCrewStart]
    ON [dbo].[Crew_Schedule]([PU_Id] ASC, [Crew_Desc] ASC, [Start_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [Crew_IDX_PUShiftStart]
    ON [dbo].[Crew_Schedule]([PU_Id] ASC, [Shift_Desc] ASC, [Start_Time] ASC);


GO
CREATE TRIGGER [dbo].[Crew_Schedule_History_Ins]
 ON  [dbo].[Crew_Schedule]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 443
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Crew_Schedule_History
 	  	   (Comment_Id,Crew_Desc,CS_Id,End_Time,PU_Id,Shift_Desc,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Crew_Desc,a.CS_Id,a.End_Time,a.PU_Id,a.Shift_Desc,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Crew_Schedule_History_Upd]
 ON  [dbo].[Crew_Schedule]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 443
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Crew_Schedule_History
 	  	   (Comment_Id,Crew_Desc,CS_Id,End_Time,PU_Id,Shift_Desc,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Crew_Desc,a.CS_Id,a.End_Time,a.PU_Id,a.Shift_Desc,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Crew_Schedule_History_Del]
 ON  [dbo].[Crew_Schedule]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 443
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Crew_Schedule_History
 	  	   (Comment_Id,Crew_Desc,CS_Id,End_Time,PU_Id,Shift_Desc,Start_Time,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Crew_Desc,a.CS_Id,a.End_Time,a.PU_Id,a.Shift_Desc,a.Start_Time,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
