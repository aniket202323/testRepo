CREATE PROCEDURE dbo.spServer_DBMgrUpdCrewSchedule
 	 @CS_Id        int OUTPUT,
 	 @PU_Id        int,
 	 @StartTime    Datetime,             
 	 @EndTime      Datetime,             
 	 @CrewName 	   nvarchar(10),
 	 @ShiftName    nvarchar(10),
 	 @UserId       int, 	  	  	  	 
 	 @CommentId    int, 	  	  	 
 	 @TransType    int,              
 	 @TransNum     int
AS
--
-- @TransType
--    1 = Insert
--    2 = Update
--    3 = Delete
-- @TransNum
--    0 = Normal
--    1 = Chain Shifts
DECLARE @ChainCSId 	 Int
DECLARE @CurrentCSId 	 Int
DECLARE @ChainTime 	 DateTime
DECLARE @DebugFlag tinyint
Declare @ID Int
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
--Select @DebugFlag = 1 
If @DebugFlag = 1 
BEGIN 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdCrewSchedule /CSId: ' + Isnull(convert(nvarchar(10),@CS_Id),'Null') + 
   	 ' /PUId: ' + Isnull(convert(nvarchar(10),@PU_Id),'Null') + 
 	 ' /StartTime: ' + Isnull(convert(nVarChar(25),@StartTime,120),'Null') + 
 	 ' /EndTime ' + Isnull(convert(nVarChar(25),@EndTime,120),'Null') + 
 	 ' /CrewName: ' + Isnull(@CrewName,'Null') + 
 	 ' /ShiftName: ' + Isnull(@ShiftName,'Null') + 
 	 ' /UserId: ' + Isnull(convert(nvarchar(10),@UserId),'Null') + 
 	 ' /CommentId: ' + Isnull(convert(nvarchar(10),@CommentId),'Null') + 
 	 ' /TransType: ' + Isnull(convert(nvarchar(10),@TransType),'Null') + 
 	 ' /TransNum: ' + Isnull(convert(nvarchar(10),@TransNum),'Null'))
 END
 	 If (@TransNum =1010) -- Transaction From WebUI
 	   SELECT @TransNum = 0
  If @TransNum Not in (0,1)
  BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END DBMgrUpdCrewSchedule: Return(1)' )
    Return(1)
  END
-- Right now, the model only sends insert transactions
IF @TransType = 1
BEGIN
 	 IF @ShiftName = 'CLOSE' Or @CrewName = 'CLOSE' --Close Out Active Record
 	 BEGIN
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Process Close Record' )
 	  	 SELECT @EndTime = @StartTime 
 	  	 Select @CurrentCSId  = CS_Id  FROM Crew_Schedule Where Start_Time < @StartTime AND End_Time > @StartTime  And PU_Id = @PU_Id
 	  	 IF @CurrentCSId Is Not NULL
 	  	 BEGIN
 	  	  	 IF @TransNum = 1  -- Chain logic
 	  	  	 BEGIN
 	  	  	  	 SELECT  @ChainTime = Min(Start_Time) FROM Crew_Schedule WHERE Start_Time >= @EndTime  And PU_Id = @PU_Id
 	  	  	  	 IF @ChainTime Is Not Null
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT @ChainCSId = Null
 	  	  	  	  	 SELECT 	 @ChainCSId 	 = CS_Id,@ChainTime = Start_Time FROM Crew_Schedule Where Start_Time = @ChainTime  And PU_Id = @PU_Id
 	  	  	  	  	 IF @StartTime <> @ChainTime 
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 Update Crew_Schedule Set User_Id = @UserId,Start_Time = @EndTime WHERE  CS_Id = @ChainCSId
 	  	  	  	  	 END
 	  	  	  	 END
 	  	  	 END
 	  	  	 UPDATE Crew_Schedule SET End_Time = @StartTime, User_Id = @UserId 	 WHERE CS_Id = @CurrentCSId
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END DBMgrUpdCrewSchedule: Return(2)' )
 	  	 END
 	  	 RETURN (2)
 	 END
 	 --See If this is a duplicate (reload)
 	 Select @ChainCSId  = CS_Id  FROM Crew_Schedule Where Start_Time = @StartTime AND End_Time = @EndTime  And PU_Id = @PU_Id
 	 IF @ChainCSId Is Not NULL
 	 BEGIN
 	  	 Select @CS_Id = @ChainCSId
 	  	 SELECT @TransType = 2
 	  	 GOTO DoModify
 	 END
 	 --If this record is contained in another record skip it
 	 Select @ChainCSId  = CS_Id  FROM Crew_Schedule Where Start_Time <= @StartTime AND End_Time >= @EndTime  And PU_Id = @PU_Id
 	 IF @ChainCSId Is Not NULL
 	 BEGIN
 	  	 Select @CS_Id = @ChainCSId
 	  	 Return(1)
 	 END
 	 --Clear all overlaps
 	 DELETE From Crew_Schedule WHERE Start_Time >= @StartTime and End_Time <= @EndTime   And PU_Id = @PU_Id 	 
--Update records that cross boundries
 	 Update Crew_Schedule Set User_Id = @UserId,End_Time = @StartTime WHERE Start_Time < @StartTime and End_Time > @StartTime  And PU_Id = @PU_Id
 	 Update Crew_Schedule Set User_Id = @UserId,Start_Time = @EndTime WHERE Start_Time < @EndTime and End_Time > @EndTime   And PU_Id = @PU_Id
 	 
 	 IF @TransNum = 1  -- Chain logic
 	 BEGIN
 	  	 SELECT  @ChainTime = Max(Start_Time) FROM Crew_Schedule WHERE Start_Time < @EndTime  And PU_Id = @PU_Id
 	  	 IF @ChainTime Is Not Null
 	  	 BEGIN
 	  	  	 SELECT @ChainCSId = Null
 	  	  	 SELECT 	 @ChainCSId 	 = CS_Id,@ChainTime = End_Time FROM Crew_Schedule Where Start_Time = @ChainTime  And PU_Id = @PU_Id
 	  	  	 IF @StartTime <> @ChainTime 
 	  	  	 BEGIN
 	  	  	  	 Update Crew_Schedule Set User_Id = @UserId,End_Time = @StartTime WHERE  CS_Id = @ChainCSId
 	  	  	 END
 	  	 END
 	  	 SELECT  @ChainTime = NULL
 	  	 SELECT  @ChainTime = Min(Start_Time) FROM Crew_Schedule WHERE Start_Time >= @EndTime  And PU_Id = @PU_Id
 	  	 IF @ChainTime Is Not Null
 	  	 BEGIN
 	  	  	 SELECT @ChainCSId = Null
 	  	  	 SELECT 	 @ChainCSId 	 = CS_Id,@ChainTime = Start_Time FROM Crew_Schedule Where End_Time = @ChainTime  And PU_Id = @PU_Id
 	  	  	 IF @EndTime <> @ChainTime 
 	  	  	 BEGIN
 	  	  	  	 Update Crew_Schedule Set User_Id = @UserId,Start_Time = @EndTime WHERE  CS_Id = @ChainCSId
 	  	  	 END
 	  	 END
 	 END
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Inserting ST:' + Isnull(convert(nVarChar(25),@StartTime,120),'Null') + ' ET:' + Isnull(convert(nVarChar(25),@EndTime,120),'Null') )
 	 INSERT INTO Crew_Schedule (PU_Id,  Start_Time, End_Time, Crew_Desc, Shift_Desc, Comment_Id,User_Id)
 	  	    VALUES 	 (@PU_Id, @StartTime, @EndTime, @CrewName, @ShiftName, @CommentId,@UserId)
 	 SELECT @CS_Id = Scope_Identity()
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END DBMgrUpdCrewSchedule: Return(1)' )
 	 RETURN (1)
END
DoModify:
IF @TransType = 2 and  @CS_Id IS NOT NULL --Only support update to crew/shift
BEGIN
 	 UPDATE Crew_Schedule SET Crew_Desc = @CrewName,Shift_Desc = @ShiftName, User_Id = @UserId 
 	  	 WHERE CS_Id = @CS_Id
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END DBMgrUpdCrewSchedule: Return(2)' )
 	 RETURN (2)
END
-- This SP should be returning result sets to generate the Post's that are needed.  We do not currently support CrewSchedule
-- Result sets, but someday we will.
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END DBMgrUpdCrewSchedule: Return(0)' )
RETURN (0)
