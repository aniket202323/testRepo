CREATE TABLE [dbo].[Activities] (
    [Activity_Id]                   BIGINT         IDENTITY (1, 1) NOT NULL,
    [Activity_Desc]                 VARCHAR (1000) NULL,
    [Activity_Priority]             INT            NOT NULL,
    [Activity_Status]               INT            NOT NULL,
    [Activity_Type_Id]              INT            NULL,
    [Auto_Complete]                 INT            NULL,
    [Comment_Id]                    INT            NULL,
    [End_Time]                      DATETIME       NULL,
    [EntryOn]                       DATETIME       NOT NULL,
    [Execution_Start_Time]          DATETIME       NULL,
    [Extended_Info]                 VARCHAR (255)  NULL,
    [External_Link]                 VARCHAR (255)  NULL,
    [KeyId]                         DATETIME       NULL,
    [KeyId1]                        INT            NULL,
    [Locked]                        TINYINT        NULL,
    [Overdue_Comment_Id]            INT            NULL,
    [PercentComplete]               FLOAT (53)     NULL,
    [PU_Id]                         INT            NULL,
    [Skip_Comment_Id]               INT            NULL,
    [Start_Time]                    DATETIME       NULL,
    [Tag]                           VARCHAR (7000) NULL,
    [Target_Duration]               INT            NOT NULL,
    [Tests_To_Complete]             INT            NULL,
    [Title]                         VARCHAR (255)  NULL,
    [UserId]                        INT            NULL,
    [Sheet_Id]                      INT            NULL,
    [Lock_Activity_Security]        TINYINT        NULL,
    [Overdue_Comment_Security]      TINYINT        NULL,
    [System_Complete_Duration_time] DATETIME       NULL,
    [Complete_Type]                 TINYINT        NULL,
    [Display_Activity_Type_Id]      INT            NULL,
    [HasAvailableCells]             BIT            NULL,
    [ActivityDetail_Comment_Id]     INT            NULL,
    CONSTRAINT [Activities_PK_ActivityId] PRIMARY KEY NONCLUSTERED ([Activity_Id] ASC),
    CONSTRAINT [Activities_FK_ActivityStatuses] FOREIGN KEY ([Activity_Status]) REFERENCES [dbo].[Activity_Statuses] ([ActivityStatus_Id]),
    CONSTRAINT [Activities_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]) ON DELETE CASCADE,
    CONSTRAINT [Activities_FK_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [Activities_UC_TypePUKeyStart] UNIQUE CLUSTERED ([Activity_Type_Id] ASC, [PU_Id] ASC, [KeyId1] ASC, [KeyId] ASC, [Title] ASC, [Sheet_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NONCLS_ACTIVITIES]
    ON [dbo].[Activities]([Activity_Id] ASC)
    INCLUDE([Activity_Desc], [Activity_Priority], [Activity_Status], [Activity_Type_Id], [ActivityDetail_Comment_Id], [Comment_Id], [Complete_Type], [Display_Activity_Type_Id], [End_Time], [HasAvailableCells], [KeyId], [KeyId1], [Locked], [Overdue_Comment_Id], [Overdue_Comment_Security], [PU_Id], [Sheet_Id], [Skip_Comment_Id], [Start_Time], [Title], [UserId]);


GO
CREATE NONCLUSTERED INDEX [IX_ACTIVITIES_STATUS_PUID]
    ON [dbo].[Activities]([Activity_Status] ASC, [PU_Id] ASC, [KeyId] ASC)
    INCLUDE([Activity_Id], [End_Time], [Execution_Start_Time], [PercentComplete], [Sheet_Id], [Target_Duration], [UserId]);


GO
CREATE NONCLUSTERED INDEX [IX_ACTIVITIES_ACTIVITYTYPEID_KEYID_INCLD]
    ON [dbo].[Activities]([Activity_Type_Id] ASC, [KeyId1] ASC)
    INCLUDE([Activity_Desc], [Activity_Id], [KeyId], [PU_Id], [Sheet_Id], [Title]);


GO
CREATE NONCLUSTERED INDEX [IX_ACTIVITIES_SHEETID_STATUS]
    ON [dbo].[Activities]([Sheet_Id] ASC, [Activity_Status] ASC)
    INCLUDE([Activity_Desc], [Activity_Id], [Activity_Type_Id], [Display_Activity_Type_Id], [KeyId], [KeyId1], [Start_Time], [Title]);


GO
CREATE NONCLUSTERED INDEX [IX_ACTIVITIES_STATUS_ENDTIME_PUID]
    ON [dbo].[Activities]([Activity_Status] ASC, [End_Time] ASC, [PU_Id] ASC)
    INCLUDE([Activity_Id], [Execution_Start_Time], [PercentComplete], [Target_Duration], [UserId]);


GO
CREATE TRIGGER [dbo].[Activities_History_Upd]
 ON  [dbo].[Activities]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 458
 If (@Populate_History = 1) and ( Update(Activity_Desc) or Update(Activity_Id) or Update(Activity_Priority) or Update(Activity_Status) or Update(Activity_Type_Id) or Update(ActivityDetail_Comment_Id) or Update(Auto_Complete) or Update(Comment_Id) or Update(Complete_Type) or Update(Display_Activity_Type_Id) or Update(End_Time) or Update(EntryOn) or Update(Execution_Start_Time) or Update(Extended_Info) or Update(External_Link) or Update(HasAvailableCells) or Update(KeyId) or Update(KeyId1) or Update(Lock_Activity_Security) or Update(Locked) or Update(Overdue_Comment_Id) or Update(Overdue_Comment_Security) or Update(PU_Id) or Update(Sheet_Id) or Update(Skip_Comment_Id) or Update(Start_Time) or Update(System_Complete_Duration_time) or Update(Tag) or Update(Target_Duration) or Update(Title) or Update(UserId)) 
   Begin
 	  	   Insert Into Activity_History
 	  	   (Activity_Desc,Activity_Id,Activity_Priority,Activity_Status,Activity_Type_Id,ActivityDetail_Comment_Id,Auto_Complete,Comment_Id,Complete_Type,Display_Activity_Type_Id,End_Time,EntryOn,Execution_Start_Time,Extended_Info,External_Link,HasAvailableCells,KeyId,KeyId1,Lock_Activity_Security,Locked,Overdue_Comment_Id,Overdue_Comment_Security,PU_Id,Sheet_Id,Skip_Comment_Id,Start_Time,System_Complete_Duration_time,Tag,Target_Duration,Title,UserId,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Activity_Desc,a.Activity_Id,a.Activity_Priority,a.Activity_Status,a.Activity_Type_Id,a.ActivityDetail_Comment_Id,a.Auto_Complete,a.Comment_Id,a.Complete_Type,a.Display_Activity_Type_Id,a.End_Time,a.EntryOn,a.Execution_Start_Time,a.Extended_Info,a.External_Link,a.HasAvailableCells,a.KeyId,a.KeyId1,a.Lock_Activity_Security,a.Locked,a.Overdue_Comment_Id,a.Overdue_Comment_Security,a.PU_Id,a.Sheet_Id,a.Skip_Comment_Id,a.Start_Time,a.System_Complete_Duration_time,a.Tag,a.Target_Duration,a.Title,a.UserId,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Activities_History_Del]
 ON  [dbo].[Activities]
  FOR DELETE
  AS
 DECLARE @NEwUserID Int
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 SELECT @NEWUserId =  CONVERT(int, CONVERT(varbinary(4), CONTEXT_INFO()))
 IF NOT EXISTS(Select 1 FROM Users_base WHERE USER_Id = @NEWUserId)
      SET @NEWUserId = Null
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 458
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Activity_History
 	  	   (Activity_Desc,Activity_Id,Activity_Priority,Activity_Status,Activity_Type_Id,ActivityDetail_Comment_Id,Auto_Complete,Comment_Id,Complete_Type,Display_Activity_Type_Id,End_Time,EntryOn,Execution_Start_Time,Extended_Info,External_Link,HasAvailableCells,KeyId,KeyId1,Lock_Activity_Security,Locked,Overdue_Comment_Id,Overdue_Comment_Security,PU_Id,Sheet_Id,Skip_Comment_Id,Start_Time,System_Complete_Duration_time,Tag,Target_Duration,Title,UserId,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Activity_Desc,a.Activity_Id,a.Activity_Priority,a.Activity_Status,a.Activity_Type_Id,a.ActivityDetail_Comment_Id,a.Auto_Complete,a.Comment_Id,a.Complete_Type,a.Display_Activity_Type_Id,a.End_Time,a.EntryOn,a.Execution_Start_Time,a.Extended_Info,a.External_Link,a.HasAvailableCells,a.KeyId,a.KeyId1,a.Lock_Activity_Security,a.Locked,a.Overdue_Comment_Id,a.Overdue_Comment_Security,a.PU_Id,a.Sheet_Id,a.Skip_Comment_Id,a.Start_Time,a.System_Complete_Duration_time,a.Tag,a.Target_Duration,a.Title,coalesce(@NEWUserId,a.UserId),dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Activities_Upd_Order_Flow]
ON  [dbo].[Activities]
  FOR UPDATE
  AS
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
create table #TmpActivities (Activity_Id int,Activity_Status Int, Activity_Type_Id int, KeyId Datetime,Activity_Priority int,UserId int,Sheet_Id int)
Insert Into #TmpActivities(Activity_Id ,Activity_Status , Activity_Type_Id , KeyId ,Activity_Priority ,UserId ,Sheet_Id )
Select Activity_Id ,Activity_Status, Activity_Type_Id,KeyId,Activity_Priority,UserId,Sheet_Id From INSERTED Where Activity_Type_Id in (1,2,3) AND Activity_Status in (3,4);
Insert Into #TmpActivities(Activity_Id ,Activity_Status , Activity_Type_Id , KeyId ,Activity_Priority ,UserId ,Sheet_Id )
Select Activity_Id ,Activity_Status, Activity_Type_Id,KeyId,Activity_Priority,UserId,Sheet_Id from (
Select 
 	 A.Activity_Id ,A.Activity_Status, A.Activity_Type_Id,A.KeyId,A.Activity_Priority,A.UserId,A.Sheet_Id, DENSE_RANK() over (partition by A.Sheet_id Order by A.Activity_Priority) rownum
from 
 	 #TmpActivities TA 
 	 Join Activities A on A.Sheet_Id = TA.Sheet_Id AND A.KeyId = TA.KeyId AND A.Activity_Priority >= TA.Activity_Priority AND A.Activity_Status  not in (3,4)) T 
Where rownum = 1;
Delete from #TmpActivities where Activity_Status in (3,4);
UPDATE A
SET A.Activity_Status = 1,A.start_time = A.keyId
From 
 	 Activities A 
 	 Join #TmpActivities TA ON TA.Activity_Id = A.Activity_Id;
INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
SELECT 0, (SELECT ResultSetType = 4,
                                                TopicId = 300,
                                                MessageKey = a.PU_Id, -- Message Key
                                                PUId =  a.PU_Id, -- Also put it in the topic result set
                                                EventType= a.Activity_Type_Id ,
                                                KeyId=a.KeyId1,
                                                KeyTime= dbo.fnServer_CmnConvertFromDbTime(a.KeyId, 'UTC'),--a.KeyId,
                                                ActivityId= a.Activity_Id,
                                                ActivityDesc = a.Activity_Desc ,
                                                APriority = 0,--a.Activity_Priority ,
                                                AStatus = 1 ,
                                                StartTime= dbo.fnServer_CmnConvertFromDbTime(a.Start_Time ,'UTC'),
                                                EndTime = dbo.fnServer_CmnConvertFromDbTime(a.End_Time ,'UTC'),
                                                TDuration = a.Target_Duration,
                                                Title = a.Title,
                                                UserId=a.UserId,
                                                EntryOn= dbo.fnServer_CmnConvertFromDbTime(a.EntryOn,'UTC'),
                                                TransType= 1,
                                                PercentComplete = a.PercentComplete,
                                                Tag = a.Tag ,
                                                ExecutionStartTime = a.Execution_Start_Time,
                                                AutoComplete = a.Auto_Complete,
                                                ExtendedInfo = a.Extended_Info,
                                                ExternalLink = a.External_Link,
                                                TestsToComplete = a.Tests_To_Complete,
                                                Locked = a.Locked,
                                                CommentId = a.Comment_Id, 
                                                OverdueCommentId = a.Overdue_Comment_Id,
                                                SkipCommentId = a.Skip_Comment_Id,
                                                SheetId = a.Sheet_Id,
                                                TransNum = 1,
                                                LockActivity = a.Lock_Activity_Security,
                                                NeedOverdueComment = a.Overdue_Comment_Security
                                FROM Activities a
                                where Activity_Id = OT.Activity_Id  for xml path ('row'), ROOT('rows')), 
UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
From #TmpActivities OT

GO
CREATE TRIGGER [dbo].[Activities_History_Ins]
 ON  [dbo].[Activities]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 458
 If (@Populate_History = 1 or @Populate_History = 3)  and ( Update(Activity_Desc) or Update(Activity_Id) or Update(Activity_Priority) or Update(Activity_Status) or Update(Activity_Type_Id) or Update(ActivityDetail_Comment_Id) or Update(Auto_Complete) or Update(Comment_Id) or Update(Complete_Type) or Update(Display_Activity_Type_Id) or Update(End_Time) or Update(EntryOn) or Update(Execution_Start_Time) or Update(Extended_Info) or Update(External_Link) or Update(HasAvailableCells) or Update(KeyId) or Update(KeyId1) or Update(Lock_Activity_Security) or Update(Locked) or Update(Overdue_Comment_Id) or Update(Overdue_Comment_Security) or Update(PU_Id) or Update(Sheet_Id) or Update(Skip_Comment_Id) or Update(Start_Time) or Update(System_Complete_Duration_time) or Update(Tag) or Update(Target_Duration) or Update(Title) or Update(UserId)) 
   Begin
 	  	   Insert Into Activity_History
 	  	   (Activity_Desc,Activity_Id,Activity_Priority,Activity_Status,Activity_Type_Id,ActivityDetail_Comment_Id,Auto_Complete,Comment_Id,Complete_Type,Display_Activity_Type_Id,End_Time,EntryOn,Execution_Start_Time,Extended_Info,External_Link,HasAvailableCells,KeyId,KeyId1,Lock_Activity_Security,Locked,Overdue_Comment_Id,Overdue_Comment_Security,PU_Id,Sheet_Id,Skip_Comment_Id,Start_Time,System_Complete_Duration_time,Tag,Target_Duration,Title,UserId,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Activity_Desc,a.Activity_Id,a.Activity_Priority,a.Activity_Status,a.Activity_Type_Id,a.ActivityDetail_Comment_Id,a.Auto_Complete,a.Comment_Id,a.Complete_Type,a.Display_Activity_Type_Id,a.End_Time,a.EntryOn,a.Execution_Start_Time,a.Extended_Info,a.External_Link,a.HasAvailableCells,a.KeyId,a.KeyId1,a.Lock_Activity_Security,a.Locked,a.Overdue_Comment_Id,a.Overdue_Comment_Security,a.PU_Id,a.Sheet_Id,a.Skip_Comment_Id,a.Start_Time,a.System_Complete_Duration_time,a.Tag,a.Target_Duration,a.Title,a.UserId,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
