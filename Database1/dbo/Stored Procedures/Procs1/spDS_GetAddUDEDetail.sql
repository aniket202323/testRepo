Create Procedure dbo.spDS_GetAddUDEDetail
@UDEId int,
@RegionalServer Int = 0
AS
 Declare @PUId int, 
         @EventSubTypeId int, 
         @ESignature_Level int,
         @EventStatus  Int,
         @Ack 	  	  	 INT,
         @AckReq 	    INT
DECLARE @InvalidStatuses Table(InvalidStatus nVarChar(100))
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Select @PUId = NULL
 Select @EventSubTypeId = NULL
 Select @ESignature_Level = NULL
-- Select @NoCause = '<None>'
-- Select @NoAction = '<None>'
-----------------------------------------------------
-- Get basic info
-------------------------------------------------------
 Select @PUId = PU_Id, @EventSubTypeId= Event_SubType_Id,@EventStatus = Event_Status,@Ack = coalesce(ack,0) 
  From User_Defined_Events
   Where UDE_Id = @UDEID
SELECT @AckReq = a.Ack_Required 
   From Event_SubTypes a
    Where Event_SubType_Id = @EventSubTypeId  	 
  Select Cause_Tree_Id as CauseTreeId, Action_Tree_Id as ActionTreeId, ESignature_Level
   From Event_SubTypes
    Where Event_SubType_Id = @EventSubTypeId  	 
------------------------------------------------------------------------------
-- detail info
-----------------------------------------------------------------------------
 Select UD.PU_Id as PUId, PU.PU_Desc as PUDesc, UD.Event_SubType_Id as EventSubTypeId, ET.Event_SubType_Desc as EventSubTypeDesc, 
        UD.UDE_Desc as UDEDesc,  UD.Start_Time as StartTime, UD.End_Time as EndTime, 
        Datediff(minute, UD.Start_Time , UD.End_Time) as Duration, 
        UD.ACK as ACK,  UD.Ack_by as ACKUserId, US2.UserName as ACKUser ,  UD.ACK_On as ACKDate,
        UD.Cause1 as CauseLevel1, RE.Event_Reason_Name as CauseName1, 
        UD.Cause2 as CauseLevel2, RE2.Event_Reason_Name as CauseName2, 
        UD.Cause3 as CauseLevel3, RE3.Event_Reason_Name as CauseName3, 
        UD.Cause4 as CauseLevel4, RE4.Event_Reason_Name as CauseName4, 
        UD.Action1 as ActionLevel1, RE5.Event_Reason_Name as ActionName1, 
        UD.Action2 as ActionLevel2, RE6.Event_Reason_Name as ActionName2, 
        UD.Action3 as ActionLevel3, RE7.Event_Reason_Name as ActionName3, 
        UD.Action4 as ActionLevel4, RE8.Event_Reason_Name as ActionName4, 
        UD.Research_User_Id as ResearchUserId, US.UserName as ResearchUserName,
        UD.Research_Status_Id as ResearchStatusId, RS.Research_Status_Desc as ResearchStatusDesc,
        UD.Research_Open_Date as ResearchOpenDate, UD.Research_Close_Date as ResearchCloseDate,
        UD.Cause_Comment_Id as CauseCommentId, -- CO.Comment as CauseComment, 	 
        UD.Action_Comment_Id as ActionCommentId, -- CO2.Comment as ActionComment,
        UD.Research_Comment_Id as ResearchCommentId, -- CO3.Comment as ResearchComment,
        UD.Comment_Id as CommentId, -- , CO4.Comment as Comment
        ET.Duration_Required as DurationRequired, ET.Cause_Required as CauseRequired, 
        ET.Action_Required as ActionRequired, ET.Ack_Required as AckRequired,
        EventStatus = isnull(ud.Event_Status,0),
        EventTestingStatus = ISNULL(ud.Testing_Status ,0)
  From User_Defined_Events UD
   Inner Join Prod_Units PU on UD.PU_id = PU.PU_Id
   Left Outer Join Event_SubTypes ET on ET.Et_Id=14 And UD.Event_SubType_Id = ET.Event_SubType_Id
   Left Outer Join Users US2 on UD.Ack_By = US2.User_Id
   Left Outer Join Event_Reasons RE on UD.Cause1 = RE.Event_Reason_Id
   Left Outer Join Event_Reasons RE2 on UD.Cause2 = RE2.Event_Reason_Id
   Left Outer Join Event_Reasons RE3 on UD.Cause3 = RE3.Event_Reason_Id
   Left Outer Join Event_Reasons RE4 on UD.Cause4 = RE4.Event_Reason_Id
   Left Outer Join Event_Reasons RE5 on UD.Action1 = RE5.Event_Reason_Id
   Left Outer Join Event_Reasons RE6 on UD.Action2 = RE6.Event_Reason_Id
   Left Outer Join Event_Reasons RE7 on UD.Action3 = RE7.Event_Reason_Id
   Left Outer Join Event_Reasons RE8 on UD.Action4 = RE8.Event_Reason_Id
   Left Outer Join Users US on UD.Research_User_Id = US.User_Id
   Left Outer Join Research_Status RS on UD.Research_Status_Id = RS.Research_Status_Id
    Where UD.UDE_Id = @UDEID
------------------------------------------------------------------------------
-- History
-----------------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Start Time')
 	 Insert into @T(TimeColumns) Values ('End Time')
 	 Insert into @CHT(HeaderTag,Idx) Values (16304,1) -- Unit
 	 Insert into @CHT(HeaderTag,Idx) Values (16070,2) -- Event Type
 	 Insert into @CHT(HeaderTag,Idx) Values (16342,3) -- Start Time
 	 Insert into @CHT(HeaderTag,Idx) Values (16333,4) -- End Time
 	 Insert into @CHT(HeaderTag,Idx) Values (16345,5) -- User
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select [Unit] = pu.PU_Desc,
 	  	 [Event Type] = es.Event_Subtype_Desc,
 	  	 [Start Time] = uh.Start_Time,
 	  	 [End Time] = uh.End_Time,
 	  	 [User] = uh.User_Id
 	 From User_Defined_Event_History uh
 	 Join Prod_Units pu on pu.PU_Id = uh.PU_Id
 	 Left Join Event_Subtypes es on es.Event_Subtype_Id = uh.Event_Subtype_Id
 	 Where UDE_Id = @UDEId
 	   order by Modified_On desc
END
ELSE
BEGIN
 	 Select pu.PU_Desc, uh.Start_Time, uh.End_Time, es.Event_Subtype_Desc
 	 From User_Defined_Event_History uh
 	 Join Prod_Units pu on pu.PU_Id = uh.PU_Id
 	 Left outer Join Event_Subtypes es on es.Event_Subtype_Id = uh.Event_Subtype_Id
 	 Where UDE_Id = @UDEId
 	 order by Modified_On desc
END
INSERT INTO @InvalidStatuses(InvalidStatus)
 	 SELECT InvalidStatus = a.ProdStatus_Desc 
 	  	 FROM Production_Status  a
 	  	 LEFT JOIN PrdExec_Trans b on a.ProdStatus_Id = b.To_ProdStatus_Id and b.PU_Id = @PUId and b.From_ProdStatus_Id = @EventStatus 
 	  	 WHERE  b.PU_Id is null and a.ProdStatus_Id <> @EventStatus
INSERT INTO @InvalidStatuses(InvalidStatus)
 	 SELECT InvalidStatus = a.ProdStatus_Desc 
 	  	 FROM Production_Status a
 	  	  	 WHERE a.ProdStatus_Id not in (select Valid_Status FROM PrdExec_Status b WHERE  b.PU_Id = @PUId and Valid_Status Is not Null)
INSERT INTO @InvalidStatuses(InvalidStatus)
 	 SELECT InvalidStatus = '<None>' WHERE @EventStatus IS Not Null
IF @AckReq = 1 and @Ack = 0
 	 INSERT INTO @InvalidStatuses(InvalidStatus) SELECT ProdStatus_Desc FROM Production_Status WHERE LockData = 1
select DISTINCT InvalidStatus FROM @InvalidStatuses
