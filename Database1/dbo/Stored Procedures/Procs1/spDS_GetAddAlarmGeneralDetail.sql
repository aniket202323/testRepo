Create Procedure dbo.spDS_GetAddAlarmGeneralDetail
AS
      Declare  @NoResearchStatus nVarChar(25),
               @NoResearchUser nVarChar(25),
               @NoCause nVarChar(25),
               @NoAction nVarChar(25)
 Select @NoResearchStatus = '<None>'
 Select @NoResearchUser = '<None>'
 Select @NoCause = '<None>'
 Select @NoAction = '<None>'
/*
--------------------------------------------------------
-- DisplayOptions
-------------------------------------------------------
 Create Table #DisplayOptionsSettings ( Name nVarChar(50),  Value nVarChar(50) Null  )
-- Insert Into #DisplayOptionsSettings Values ('DISPLAYBUTTONS', 'True')
 Insert Into #DisplayOptionsSettings Values ('DISPLAYNAVIGATIONBUTTONS', 'False')
 Insert Into #DisplayOptionsSettings Values ('DISPLAYCONFIRMBUTTONS', 'False')
 Select * From  #DisplayOptionsSettings
*/
------------------------------------------------------
-- Users
----------------------------------------------------
 Create Table #Users (
  UserId int,
  UserName nVarChar(30) NULL)
 Insert Into #Users
  Select User_Id, UserName 
   From Users 
    Where System=0
 Insert Into #Users values(0, @NoResearchUser)
 Select * From #Users Order by UserName
---------------------------------------------------------------
-- Research Status
-------------------------------------------------------------
 Create Table #ResearchStatus(
   StatusId int,
   StatusDesc nVarChar(50)
)
 Insert Into #ResearchStatus
  Select Research_Status_Id, Research_Status_Desc
   From Research_Status
 Insert Into #ResearchStatus Values (0, @NoResearchStatus) 
 Select * From #ResearchStatus Order By StatusDesc
--------------------------------------------------------
-- Constants
-------------------------------------------------------
 Select @NoResearchUser as NoResearchUser, @NoResearchStatus as NoResearchStatus,
        @NoCause as NoCause, @NoAction as NoAction
--------------------------------
-- Delete temporary tables
-------------------------------
-- Drop Table #DisplayOptionsSettings
 Drop Table #Users
 Drop Table #ResearchStatus
