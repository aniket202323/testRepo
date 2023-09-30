Create Procedure dbo.spDS_GetAddWasteGeneralDetail
AS
      Declare  @NoType nVarChar(25),
               @NoMeasurement nVarChar(25),
               @NoResearchStatus nVarChar(25),
               @NoResearchUser nVarChar(25),
               @NoCause nVarChar(25),
               @NoLocation nVarChar(25),
               @NoAction nVarChar(25)
 Select @NoType = '<None>'
 Select @NoMeasurement = '<None>'
 Select @NoResearchStatus = '<None>'
 Select @NoResearchUser = '<None>'
 Select @NoCause = '<None>'
 Select @NoLocation = '<None>'
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
--------------------------------------------------------
-- Waste Event Type
-----------------------------------------------------------
 Create table #Type (
  WetId int,
  WetDesc nVarChar(50))
 Insert Into #Type
  Select WET_Id, WET_Name 
  From Waste_Event_Type
  Insert Into #Type values(0, @NoType)
  Select WetId, WetDesc
   From #Type
    Order by WETDesc
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
  Insert Into #ResearchStatus Values (0, @NoResearchUser) 
 Select * From #ResearchStatus Order By StatusDesc
--------------------------------------------------------
-- Constants
-------------------------------------------------------
 Select @NoType as NoType, @NoMeasurement as NoMeasurement, @NoResearchUser as NoResearchUser, 
        @NoResearchStatus as NoResearchStatus, @NoCause as NoCause, @NoAction as NoAction, @NoLocation as NoLocation
--------------------------------
-- Delete temporary tables
-------------------------------
-- Drop Table #DisplayOptionsSettings
 Drop Table #Users
 Drop Table #ResearchStatus
 Drop Table #Type
