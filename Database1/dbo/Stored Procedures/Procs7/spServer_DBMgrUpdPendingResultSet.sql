/* ##### spServer_UpdPendingResultSet #####
Description 	 : Updates pending result set for different topics.
Creation Date 	 : NA
Created By 	 : NA
#### Update History ####
DATE 	  	  	  Modified By 	  	 UserStory/Defect No 	  	 Comments 	 
---- 	  	  	  ----------- 	  	 ------------------- 	  	 --------
*/
CREATE PROCEDURE dbo.spServer_DBMgrUpdPendingResultSet @TopicId       INT,
                                                       @TableId       INT,
                                                       @RootId        BIGINT,
                                                       @TransType     INT,
                                                       @TransNum      INT,
                                                       @ResultSetType INT    = 4,
                                                       @UserId        INT, 
                                                       @TimeStamp     DATETIME = NULL
AS
BEGIN
    BEGIN
        IF @TableId = 80
            BEGIN
                INSERT INTO Pending_ResultSets( Processed,
                                                RS_Value,
                                                User_Id,
                                                Entry_On )
                SELECT 0,
                       (SELECT ResultSetType = @ResultSetType,
                               TopicId = @TopicId,
                               MessageKey = PU_Id, -- Message Key
                               PUId = PU_Id, -- Also put it in the topic result set
                               EventType = Activity_Type_Id,
                               KeyId = KeyId1,
                               KeyTime = dbo.fnServer_CmnConvertFromDbTime(KeyId, 'UTC'),
                               ActivityId = Activity_Id,
                               ActivityDesc = Activity_Desc,
                               APriority = Activity_Priority,
                               AStatus = Activity_Status,
                               StartTime = dbo.fnServer_CmnConvertFromDbTime(Start_Time, 'UTC'),
                               EndTime = dbo.fnServer_CmnConvertFromDbTime(End_Time, 'UTC'),
                               TDuration = Target_Duration,
                               Title = Title,
                               UserId = UserId,
                               EntryOn = dbo.fnServer_CmnConvertFromDbTime(EntryOn, 'UTC'),
                               TransType = @TransType,
                               PercentComplete = PercentComplete,
                               Tag = Tag,
                               ExecutionStartTime = Execution_Start_Time,
                               AutoComplete = Auto_Complete,
                               ExtendedInfo = Extended_Info,
                               ExternalLink = External_Link,
                               TestsToComplete = Tests_To_Complete,
                               Locked = Locked,
                               CommentId = Comment_Id,
                               OverdueCommentId = Overdue_Comment_Id,
                               SkipCommentId = Skip_Comment_Id,
                               SheetId = Sheet_Id,
                               TransNum = @TransNum,
                               LockActivity = Lock_Activity_Security,
                               NeedOverdueComment = Overdue_Comment_Security
                               FROM Activities AS A
                               WHERE A.Activity_Id = @RootId FOR XML PATH('row'), ROOT('rows'), ELEMENTS XSINIL),
                       @UserId,
                       dbo.fnServer_CmnGetDate(GETUTCDATE())
            END
 	  	 ELSE IF @TableId = 1 AND @ResultSetType = 2 --For Test Value Update
 	  	     BEGIN
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
                SELECT 0,
                       (SELECT RSTId=@ResultSetType,
                              VarId = T.Var_Id,
 	  	  	  	  	  	  	   PUId = V.PU_ID,
 	  	  	  	  	  	  	   UserId = T.Entry_By,
 	  	  	  	  	  	  	   Canceled = T.Canceled,
 	  	  	  	  	  	  	   Value = T.Result,
 	  	  	  	  	  	  	   ResultOn = T.Result_On,
 	  	  	  	  	  	  	   TransType = @TransType,
 	  	  	  	  	  	  	   PostDB =1, 
 	  	  	  	  	  	  	   SecondUserId = T.Second_User_Id,
 	  	  	  	  	  	  	   TransNum = @TransNum,
 	  	  	  	  	  	  	   EventId =T.Event_Id,
 	  	  	  	  	  	  	   ArrayId = T.Array_Id,
 	  	  	  	  	  	  	   CommentId = T.Comment_Id,
 	  	  	  	  	  	  	   ESigId =  T.Signature_Id,
 	  	  	  	  	  	  	   EntryOn =dbo.fnServer_CmnConvertFromDbTime(T.Entry_On, 'UTC'),
 	  	  	  	  	  	  	   TestId = T.Test_Id,
 	  	  	  	  	  	  	   ShouldArchive = null, --null0,
 	  	  	  	  	  	  	   HasHistory = CASE  
 	  	  	  	  	  	  	  	  	  	  	 WHEN EXISTS (SELECT 1 FROM Test_History WHERE Test_Id = T.Test_Id) 
 	  	  	  	  	  	  	  	  	  	  	 THEN 1 ELSE 0
 	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	   IsLocked = T.Locked
                             FROM Tests AS T JOIN Variables v on T.var_id = v.var_id
 	  	  	  	  	  	  	  WHERE T.Test_Id = @RootId FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL),
                       @UserId,
                       dbo.fnServer_CmnGetDate(GETUTCDATE());
 	  	  	 END
 	  	 ELSE IF @TableId = 13 AND @ResultSetType = 6 -- For Alarm messages
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	 SELECT 0,
 	  	  	  	  	 (
 	  	  	  	  	 SELECT  
 	  	  	  	  	 RSTId = @ResultSetType
 	  	  	  	  	 ,PreDB = 1
 	  	  	  	  	 ,TransNum = @TransNum
 	  	  	  	  	 ,AlarmId = A.Alarm_Id
 	  	  	  	  	 ,ATDId = A.ATD_Id
 	  	  	  	  	 ,StartTime = dbo.fnServer_CmnConvertFromDbTime(A.Start_Time, 'UTC')--Need to review the date conversion.
 	  	  	  	  	 ,EndTime = dbo.fnServer_CmnConvertFromDbTime(A.End_Time, 'UTC')
 	  	  	  	  	 ,AlarmDuration = A.Duration
 	  	  	  	  	 ,Ack = A.Ack
 	  	  	  	  	 ,AckOnTime = dbo.fnServer_CmnConvertFromDbTime(A.Ack_On, 'UTC')
 	  	  	  	  	 ,AckBy = A.Ack_By
 	  	  	  	  	 ,StartValue = A.Start_Result
 	  	  	  	  	 ,EndValue = A.End_Result
 	  	  	  	  	 ,MinValue = A.Min_Result
 	  	  	  	  	 ,MaxValue = A.Max_Result
 	  	  	  	  	 ,Cause1 = A.Cause1
 	  	  	  	  	 ,Cause2 = A.Cause2
 	  	  	  	  	 ,Cause3 = A.Cause3
 	  	  	  	  	 ,Cause4 = A.Cause4
 	  	  	  	  	 ,CauseCommentId = A.Cause_Comment_Id
 	  	  	  	  	 ,Action1 = A.Action1
 	  	  	  	  	 ,Action2 = A.Action2
 	  	  	  	  	 ,Action3 = A.Action3
 	  	  	  	  	 ,Action4 = A.Action4
 	  	  	  	  	 ,ActionCommentId = A.Action_Comment_Id
 	  	  	  	  	 ,ResearchUserId = A.Research_User_Id
 	  	  	  	  	 ,ResearchStatusId = A.Research_Status_Id
 	  	  	  	  	 ,ResearchOpenDate = dbo.fnServer_CmnConvertFromDbTime(A.Research_Open_Date, 'UTC')
 	  	  	  	  	 ,ResearchCloseDate = dbo.fnServer_CmnConvertFromDbTime(A.Research_Close_Date, 'UTC')
 	  	  	  	  	 ,ResearchCommentId = A.Research_Comment_Id
 	  	  	  	  	 ,SourcePUId = A. Source_PU_Id
 	  	  	  	  	 ,AlarmTypeId = A.Alarm_Type_Id
 	  	  	  	  	 ,AlarmKeyId = A.Key_Id
 	  	  	  	  	 ,Description = A.Alarm_Desc
 	  	  	  	  	 ,TransType = @TransType
 	  	  	  	  	 --,CommentId = AT.Comment_Id-- not sure about this is correct
 	  	  	  	  	 ,APId = AT.AP_Id
 	  	  	  	  	 ,ATId = AT.AT_Id
 	  	  	  	  	 --,VarCommentId = ATVD.Comment_Id -- not sure about this is correct
 	  	  	  	  	 ,AlarmCutoff = A.Cutoff
 	  	  	  	  	 ,ESigId = A.Signature_Id
 	  	  	  	  	 ,PathId = A.Path_Id
 	  	  	  	  	 ,UserId = A.User_Id
 	  	  	  	  	 ,ATSRDId = A.ATSRD_Id
 	  	  	  	  	 ,AlarmSubTypeId = A.SubType
 	  	  	  	  	 ,ATVRDId = A.ATVRD_Id
 	  	  	  	  	 --,CurrentValue = (SELECT TOP 1 Result FROM Tests WHERE Var_Id =A.Key_Id  AND (Result IS NOT NULL OR Result <> '') ORDER BY Result_On DESC)-- not sure about this is correct
 	  	  	  	  	 --,InAlarm = NULL -- not sure about this is correct
 	  	  	  	  	 --,AlarmControlFlag = NULL -- not sure about this is correct
 	  	  	  	  	 --,CurrentTime = Result On from test table 
 	  	  	  	  	 FROM Alarms A
 	  	  	  	  	 JOIN Alarm_Template_Var_Data ATVD ON A.ATD_Id = ATVD.ATD_Id
 	  	  	  	  	 JOIN Alarm_Templates AT ON ATVD.AT_Id = AT.AT_Id
 	  	  	  	  	 WHERE A.Alarm_Id = @RootId
 	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	 ,@UserId
 	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	 END
 	  	  	 ELSE IF @TableId = 4 AND @ResultSetType = 1-- For Production Event
                     BEGIN
                           INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
                                  SELECT 0,
                                  (
                                  SELECT  
                                  RSTId = 1
                                  ,NotUsed = Null
                                  ,TransType = @TransType
                                  ,EventId = E.Event_Id
                                  ,EventNum = E.Event_Num
                                  ,PUId = E.PU_Id
                                  ,TimeStamp = dbo.fnServer_CmnConvertFromDbTime(E.TimeStamp, 'UTC')
                                  ,AppProdId = E.Applied_Product
                                  ,SrcEventId = E.Source_Event
                                  ,EventStatus = E.Event_Status
                                  ,Confirmed = E.Confirmed
                                  ,UserId = E.User_Id
                                  ,PostDB = 1
                                  ,Conformance = E.Conformance
                                  ,TestPctComplete = E.Testing_Prct_Complete
                                  ,StartTime = E.Start_Time
                                  ,TransNum = @TransNum
                                  ,TestingStatus = E.Testing_Status
                                  ,CommentId = E.Comment_Id
                                  ,EventSubTypeId = E.Event_Subtype_Id
                                  ,EntryOn = dbo.fnServer_CmnConvertFromDbTime(E.Entry_On, 'UTC')
                                  ,ApprovedUserId = E.Approver_User_Id
                                  ,Obsolete = NULL
                                  ,ApprovedReasonId = E.Approver_Reason_Id
                                  ,UserReasonId = E.User_Reason_Id
                                  ,SignOffId = E.User_Signoff_Id
                                  ,ExtendedInfo = E.Extended_Info
                                  ,ESigId = E.Signature_Id                 
                                  FROM Events E
                                  WHERE E.Event_Id = @RootId
                                  FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
                                  ,@UserId
                                  ,dbo.fnServer_CmnGetDate(GETUTCDATE())
                     END
                     ELSE IF @TableId = 9 AND @ResultSetType = 8 -- For User Defined Event
                     BEGIN
                           INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
                                  SELECT 0,
                                  (
                                  SELECT  
                                  RSTId = @ResultSetType
                                  ,PreDB = 0
                                  ,UDEId = UDE.UDE_Id
                                  ,UDENum = UDE.UDE_Desc
                                  ,PUId = UDE.PU_Id
                                  ,EventSubtypeId = UDE.Event_Subtype_Id
                                  ,StartTime = dbo.fnServer_CmnConvertFromDbTime(UDE.Start_Time, 'UTC')
                                  ,EndTime = dbo.fnServer_CmnConvertFromDbTime(UDE.End_Time, 'UTC')
                                  ,UDEDuration = UDE.Duration
                                  ,Ack = UDE.Ack
                                  ,AckOn = UDE.Ack_On
                                  ,AckBy = UDE.Ack_By
                                  ,Cause1 = UDE.Cause1
                                  ,Cause2 = UDE.Cause2
                                  ,Cause3 = UDE.Cause3
                                  ,Cause4 = UDE.Cause4
                                  ,CommentId = UDE.Comment_Id
                                  ,Action1 = UDE.Action1
                                  ,Action2 = UDE.Action2
                                  ,Action3 = UDE.Action3
                                  ,Action4 = UDE.Action4
                                  ,ActionCommentId = UDE.Action_Comment_Id
                                  ,ResearchUserId = UDE.Research_User_Id
                                  ,ResearchStatusId = UDE.Research_Status_Id
                                  ,ResearchOpenDate = dbo.fnServer_CmnConvertFromDbTime(UDE.Research_Open_Date, 'UTC')
                                  ,ResearchCloseDate = dbo.fnServer_CmnConvertFromDbTime(UDE.Research_Close_Date, 'UTC')
                                  ,ResearchCommentId = UDE.Research_Comment_Id
                                  ,UDECommentId = UDE.Comment_Id
                                  ,TransType = @TransType                                
                                  ,EventSubTypeDesc = ES.Event_subtype_Desc
                                  ,TransNum = @TransNum
                                  ,UserId = UDE.User_Id
                                  ,ESigId = UDE.Signature_Id
                                  ,ProductionEventId = NULL
                                  ,ParentUDEId = UDE.Parent_UDE_Id
                                  ,EventStatus = UDE.Event_Status
                                  ,TestingStatus = UDE.Testing_Status
                                  ,TestPctComplete = UDE.Testing_Prct_Complete
                                  FROM User_Defined_Events UDE
                                  LEFT JOIN event_subtypes ES ON ES.Event_Subtype_Id = UDE.Event_subtype_Id
                                  WHERE UDE.UDE_Id = @RootId
                                  FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
                                  ,@UserId
                                  ,dbo.fnServer_CmnGetDate(GETUTCDATE())
                           END           
 	  	 ELSE IF @TableId = 16 AND @ResultSetType = 5 -- For Downtime
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	 SELECT 0,
 	  	  	  	  	 (
 	  	  	  	  	 Select 
 	  	  	  	  	  	 RSTId = @ResultSetType,
 	  	  	  	  	  	 PUId = PU_Id,
 	  	  	  	  	  	 SourcePUId = Source_PU_Id,
 	  	  	  	  	  	 StatusId = TEStatus_Id,
 	  	  	  	  	  	 FaultId = TEFault_Id,
 	  	  	  	  	  	 Reason1Id = Reason_Level1,
 	  	  	  	  	  	 Reason2Id = Reason_Level2,
 	  	  	  	  	  	 Reason3Id = Reason_Level3,
 	  	  	  	  	  	 Reason4Id = Reason_Level4,
 	  	  	  	  	  	 ProdRate  =NULL,
 	  	  	  	  	  	 NotUsed =NULL,
 	  	  	  	  	  	 TransType = @TransType,
 	  	  	  	  	  	 StartTime = Start_Time,--dbo.fnServer_CmnConvertFromDbTime(Start_Time, 'UTC'),
 	  	  	  	  	  	 EndTime = End_Time,--dbo.fnServer_CmnConvertFromDbTime(End_Time,'UTC'),
 	  	  	  	  	  	 TimedEventId = TEDet_Id,
 	  	  	  	  	  	 PostDB = 1 ,
 	  	  	  	  	  	 TransNum = @TransNum,
 	  	  	  	  	  	 Action1 = Action_Level1,
 	  	  	  	  	  	 Action2 = Action_Level2,
 	  	  	  	  	  	 Action3 = Action_Level3,
 	  	  	  	  	  	 Action4 = Action_Level4,
 	  	  	  	  	  	 ActionCommentId =Action_Comment_Id ,
 	  	  	  	  	  	 ResearchCommentId = Research_Comment_Id,
 	  	  	  	  	  	 ResearchStatusId = Research_Status_Id,
 	  	  	  	  	  	 ResearchOpenDate = Research_Open_Date,--dbo.fnServer_CmnConvertFromDbTime(Research_Open_Date,'UTC'),
 	  	  	  	  	  	 ResearchCloseDate = Research_Close_Date,--dbo.fnServer_CmnConvertFromDbTime(Research_Close_Date,'UTC'),
 	  	  	  	  	  	 CommentId = Cause_Comment_Id,
 	  	  	  	  	  	 Obsolete =NULL,
 	  	  	  	  	  	 Obsolete =NULL,
 	  	  	  	  	  	 Obsolete =NULL,
 	  	  	  	  	  	 Obsolete =NULL,
 	  	  	  	  	  	 Obsolete =NULL,
 	  	  	  	  	  	 Obsolete =NULL,
 	  	  	  	  	  	 Obsolete =NULL,
 	  	  	  	  	  	 ResearchUserId = Research_User_Id,
 	  	  	  	  	  	 RsnTreeDataId = Event_Reason_Tree_Data_Id,
 	  	  	  	  	  	 ESigId = Signature_Id,
 	  	  	  	  	  	 UserId = User_Id,
 	  	  	  	  	  	 Duration 
 	  	  	  	  	 From Timed_Event_Details Where tedet_Id = @RootId
 	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	 ,@UserId
 	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	 END
 	  	 ELSE IF @TableId = 20 AND @ResultSetType = 7 -- For Time Based Event
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	 SELECT 0, 
 	  	  	  	    (SELECT RSTId = @ResultSetType, 
 	  	  	  	  	  	    SheetId = Sheet_Id, 
 	  	  	  	  	  	    UserId = @UserId, 
 	  	  	  	  	  	    TransType = @TransType, 
 	  	  	  	  	  	    --TimeStamp = dbo.fnServer_CmnConvertFromDbTime(Result_On, 'UTC'), 
 	  	  	  	  	  	    TimeStamp = Result_On,--Need to pass db time
 	  	  	  	  	  	    PostDB = 1, 
 	  	  	  	  	  	    ApprovedUserId = Approver_User_Id, 
 	  	  	  	  	  	    ApprovedReasonId = Approver_Reason_Id, 
 	  	  	  	  	  	    UserReasonId = Approver_Reason_Id, 
 	  	  	  	  	  	    SignOffId = User_Signoff_Id, 
 	  	  	  	  	  	    ESigId = Signature_Id, 
 	  	  	  	  	  	    TransNum = @TransNum, 
 	  	  	  	  	  	    CommentId = Comment_Id
 	  	  	  	  	  	    FROM Sheet_Columns
 	  	  	  	  	  	    WHERE Sheet_Id = @RootId
 	  	  	  	  	  	  	  	  AND Result_On = @TimeStamp FOR XML PATH('row'), ROOT('rows'), ELEMENTS XSINIL), 
 	  	  	  	    @UserId, 
 	  	  	  	    dbo.fnServer_CmnGetDate(GETUTCDATE());
 	  	  	 END
 	  	  	 ELSE IF @TableId = 14 AND @ResultSetType = 10 -- For Event Details
 	  	  	 BEGIN
 	  	  	  	 ;WITH E AS (SELECT Event_Id, TimeStamp FROM Events WHERE Event_Id = @RootId) 
 	  	  	 
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, 
 	  	  	  	  	  	  	  	  	  	  	  	 RS_Value, 
 	  	  	  	  	  	  	  	  	  	  	  	 User_Id, 
 	  	  	  	  	  	  	  	  	  	  	  	 Entry_On )
 	  	  	  	 SELECT 0, 
 	  	  	  	  	    (SELECT RSTId = @ResultSetType, 
 	  	  	  	  	  	  	    PreDB = 0, -- Need data
 	  	  	  	  	  	  	    UserId = @UserId, 
 	  	  	  	  	  	  	    TransType = @TransType, 
 	  	  	  	  	  	  	    TransNum = @TransNum, 
 	  	  	  	  	  	  	    EventId = E.Event_Id, 
 	  	  	  	  	  	  	    PUId = ED.PU_Id, 
 	  	  	  	  	  	  	    Obsolete = NULL,
 	  	  	  	  	  	  	    AltEventNum = ED.Alternate_Event_Num, 
 	  	  	  	  	  	  	    CommentId = ED.Comment_Id, 
 	  	  	  	  	  	  	    Obsolete = NULL,
 	  	  	  	  	  	  	    Obsolete = NULL,
 	  	  	  	  	  	  	    Obsolete = NULL,
 	  	  	  	  	  	  	    Obsolete = NULL,
 	  	  	  	  	  	  	    --TimeStamp = dbo.fnServer_CmnConvertFromDbTime(E.TimeStamp, 'UTC'), 
 	  	  	  	  	  	  	    --EntryOn = dbo.fnServer_CmnConvertFromDbTime(ED.Entered_On, 'UTC'),
 	  	  	  	  	  	  	    TimeStamp =  E.TimeStamp,--Need to pass db time
 	  	  	  	  	  	  	    EntryOn = ED.Entered_On,--Need to pass db time
 	  	  	  	  	  	  	    PPSetupDetailId = ED.PP_Setup_Detail_Id, 
 	  	  	  	  	  	  	    ShipmentId = ED.Shipment_Id, 
 	  	  	  	  	  	  	    OrderId = ED.Order_Id, 
 	  	  	  	  	  	  	    OrderLineId = ED.Order_Line_Id, 
 	  	  	  	  	  	  	    PPId = ED.PP_Id, 
 	  	  	  	  	  	  	    InitialDimensionX = ED.Initial_Dimension_X, 
 	  	  	  	  	  	  	    InitialDimensionY = ED.Initial_Dimension_Y, 
 	  	  	  	  	  	  	    InitialDimensionZ = ED.Initial_Dimension_Z, 
 	  	  	  	  	  	  	    InitialDimensionA = ED.Initial_Dimension_A, 
 	  	  	  	  	  	  	    FinalDimensionX = ED.Final_Dimension_X, 
 	  	  	  	  	  	  	    FinalDimensionY = ED.Final_Dimension_Y, 
 	  	  	  	  	  	  	    FinalDimensionZ = ED.Final_Dimension_Z, 
 	  	  	  	  	  	  	    FinalDimensionA = ED.Final_Dimension_A, 
 	  	  	  	  	  	  	    OrientationX = ED.Orientation_X, 
 	  	  	  	  	  	  	    OrientationY = ED.Orientation_Y, 
 	  	  	  	  	  	  	    OrientationZ = ED.Orientation_Z, 
 	  	  	  	  	  	  	    ESigId = ED.Signature_Id
 	  	  	  	  	  	  	    FROM  E
 	  	  	  	  	  	  	  	  	 INNER JOIN Event_Details AS ED ON E.Event_Id = ED.Event_Id FOR XML PATH('row'), ROOT('rows'), ELEMENTS XSINIL), 
 	  	  	  	  	    @UserId, 
 	  	  	  	  	    dbo.fnServer_CmnGetDate(GETUTCDATE());
 	  	  	 END
 	  	  	 ELSE IF @TableId = 42 AND @ResultSetType = 2 -- For Test data
 	  	  	 BEGIN
 	  	  	 INSERT INTO Pending_ResultSets( Processed, 
 	  	  	  	  	  	  	  	  	  	  	 RS_Value, 
 	  	  	  	  	  	  	  	  	  	  	 User_Id, 
 	  	  	  	  	  	  	  	  	  	  	 Entry_On )
 	  	  	 SELECT 0, 
 	  	  	  	    (SELECT RSTId = @ResultSetType, 
 	  	  	  	  	  	    VarId = T.Var_Id, 
 	  	  	  	  	  	    PUId = NULL, 
 	  	  	  	  	  	    UserId = Entry_By, 
 	  	  	  	  	  	    Canceled = T.Canceled, 
 	  	  	  	  	  	    Result = T.Result, 
 	  	  	  	  	  	    --ResultOn = dbo.fnServer_CmnConvertFromDbTime(T.Result_On, 'UTC'),
 	  	  	  	  	  	    ResultOn = T.Result_On,--Need to pass db time
 	  	  	  	  	  	    TransType = @TransType, 
 	  	  	  	  	  	    PostDB = 1, 
 	  	  	  	  	  	    SecondUserId = T.Second_User_Id, 
 	  	  	  	  	  	    TransNum = @TransNum, 
 	  	  	  	  	  	    EventId = T.Event_Id, 
 	  	  	  	  	  	    ArrayId = T.Array_Id, 
 	  	  	  	  	  	    CommentId = T.Comment_Id, 
 	  	  	  	  	  	    ESigId = T.Signature_Id, 
 	  	  	  	  	  	    --EntryOn = dbo.fnServer_CmnConvertFromDbTime(T.Entry_On, 'UTC'), 
 	  	  	  	  	  	    EntryOn = T.Entry_On,--Need to pass db time
 	  	  	  	  	  	    TestId = T.Test_Id, 
 	  	  	  	  	  	    ShouldArchive = NULL, 
 	  	  	  	  	  	    HasHistory = NULL, 
 	  	  	  	  	  	    IsLocked = Locked
 	  	  	  	  	  	    FROM Tests AS T
 	  	  	  	  	  	    WHERE T.Test_Id = @RootId FOR XML PATH('row'), ROOT('rows'), ELEMENTS XSINIL), 
 	  	  	  	    @UserId, 
 	  	  	  	    dbo.fnServer_CmnGetDate(GETUTCDATE());
 	  	  	 END
 	  	  	 
    END
    RETURN 1
END
