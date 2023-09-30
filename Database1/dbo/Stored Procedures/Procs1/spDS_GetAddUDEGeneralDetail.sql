--            EXECUTE spDS_GetAddUDEGeneralDetail 35,0
Create Procedure dbo.spDS_GetAddUDEGeneralDetail
 @SheetId int,
 @RunType int,
 @InUDEId  Int = Null
AS
      Declare  @NoType nVarChar(25),
               @NoUser nVarChar(25),
 	  	  	    @NoStatus nVarChar(25),
               @NoResearchStatus nVarChar(25),
               @NoResearchUser nVarChar(25),
               @NoCause nVarChar(25),
               @NoAction nVarChar(25), 
               @NoPU nVarChar(25),
               @NoEventSubType nVarChar(25), 
 	            @TreeNameId int,
               @PUId int,
               @SheetType int,
               @EventSubtypeId Int,
 	  	  	    @DefaultStatus 	 Int
 Select @NoType = '<None>'
 Select @NoUser = '<None>'
 Select @NoResearchStatus = '<None>'
 Select @NoResearchUser = '<None>'
 Select @NoCause = '<None>'
 Select @NoAction = '<None>'
 Select @NoPU = '<None>'
 Select @NoEventSubType='<None>'
 Select @NoStatus = '<None>'
--------------------------------------------------------
-- Constants
-------------------------------------------------------
 Select @NoType as NoType, @NoUser as NoUser, @NoResearchUser as NoResearchUser, @NoResearchStatus as NoResearchStatus,
        @NoCause as NoCause, @NoAction as NoAction, @NoPU as NoPU, @NoEventSubType as NoEventSubType,NoStatus = @NoStatus
----------------------------------------------------
-- PUs
----------------------------------------------------
Select @PUId = Master_Unit, @SheetType = Sheet_Type,@EventSubtypeId = Event_Subtype_Id  from Sheets where Sheet_Id = @SheetId
 IF @InUDEId IS NOT NULL AND @SheetType = 14 --SOE
 BEGIN
 	 Select @PUId = PU_Id,@EventSubtypeId = Event_Subtype_Id  FROM User_Defined_Events WHERE UDE_Id = @InUDEId 
 END
 DECLARE   @PUids Table(
  PUId int,
  PUDesc nVarChar(50) NULL,
  GroupId int NULL)
 Insert Into @PUids (PUId,PUDesc,GroupId) values(0, @NoPU,0) 
 If (@RunType = 1 and @SheetType = 25) --adding a new UDE to Autolog-UDE display
   Begin
     Insert Into @PUids(PUId,PUDesc,GroupId)
      Select s.Master_Unit, p.PU_Desc, p.Group_Id
       From Sheets s
        join Prod_Units p on s.Master_Unit = p.PU_Id
          Where s.Sheet_Id = @SheetId
   End
 Else
   If @RunType = 1 --adding a new UDE from the SOE display
    Begin
      Insert Into @PUids(PUId,PUDesc,GroupId)
        Select su.PU_Id, p.PU_Desc, p.Group_Id
         From Sheet_Unit su
          join Sheets s on s.Sheet_Id = su.Sheet_Id
          join Prod_Units p on su.PU_Id = p.PU_Id
            Where s.Sheet_Id = @SheetId
    End
 Else
    Begin
     Insert Into @PUids(PUId,PUDesc,GroupId)
      Select PU_Id, PU_Desc, Group_Id 
       From Prod_Units 
          Where PU_Id<>0
    End
 Select PUId,PUDesc,GroupId From @PUids Order by PUDesc 
----------------------------------------------------
-- Event SubTypes
----------------------------------------------------
 DECLARE  @EventSubTypes Table(
  EventSubTypeId int,
  EventSubTypeDesc nVarChar(50) NULL)
 Insert Into @EventSubTypes(EventSubTypeId,EventSubTypeDesc)
  Select es.Event_Subtype_Id, es.Event_SubType_Desc
   From Event_Subtypes es
    Join Event_Configuration ec on ec.Event_Subtype_Id = es.Event_Subtype_id
    join @PUids pu on pu.PUId = ec.PU_id
    Where es.ET_Id = 14
  Insert Into @EventSubTypes (EventSubTypeId,EventSubTypeDesc) values(0, @NoEventSubType)
 Select Distinct EventSubTypeId,EventSubTypeDesc From @EventSubTypes Order by EventSubTypeDesc 
------------------------------------------------------
-- Users
----------------------------------------------------
 DECLARE @Users Table  (
  UserId int,
  UserName nVarChar(30) NULL)
  Insert Into @Users(UserId,UserName)
  Select User_Id, UserName 
   From Users 
    Where System=0
  Insert Into @Users (UserId,UserName) values(0, @NoResearchUser)
 Select UserId,UserName From @Users Order by UserName
---------------------------------------------------------------
-- Research Status
-------------------------------------------------------------
 DECLARE  @ResearchStatus Table(
   StatusId int,
   StatusDesc nVarChar(50)
)
 Insert Into @ResearchStatus
  Select Research_Status_Id, Research_Status_Desc
   From Research_Status
  Insert Into @ResearchStatus Values (0, @NoResearchStatus) 
 Select StatusId,StatusDesc From @ResearchStatus Order By StatusDesc
SELECT @DefaultStatus = a.Default_Event_Status
 	 FROM Event_Subtypes a
 	 WHERE a.Event_Subtype_Id = @EventSubtypeId
SELECT @DefaultStatus = coalesce(@DefaultStatus,0)
--------------------------------------------------------
-- Event Status
--------------------------------------------------------
DECLARE @Status Table (ProdStatus_Id int , ProdStatus_Desc nVarChar(50),LockData Int)
IF @DefaultStatus <> 0
BEGIN
 	  Insert Into @Status(ProdStatus_Id,ProdStatus_Desc,LockData)
 	   Select ProdStatus_Id, ProdStatus_Desc,coalesce(LockData,0)
 	    From Production_status a
 	    Join PrdExec_Status b on b.Valid_Status = a.ProdStatus_Id 
 	    WHERE b.PU_Id = @PUId
END
ELSE
BEGIN  
 	 Insert Into @Status (ProdStatus_Id,ProdStatus_Desc,LockData) Values (0,@NoStatus,0)
END
Select ProdStatus_Id,ProdStatus_Desc,LockData From @Status Order by ProdStatus_Desc
SELECT DefaultStatus = @DefaultStatus
