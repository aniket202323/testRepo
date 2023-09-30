CREATE PROCEDURE dbo.spCSS_RemoveClientConnection
@ConnectionID int 
AS
Declare @StartTime datetime, @MinTime datetime, @@ClientId int 
UPDATE Client_Connections
  SET End_Time = dbo.fnServer_CmnGetDate(getutcdate()), Last_heartbeat = dbo.fnServer_CmnGetDate(getutcdate())
  WHERE Client_Connection_Id = @ConnectionID
DELETE Client_Connection_App_Data 
  WHERE Client_Connection_Id = @ConnectionID
DELETE Client_Connection_Module_Data 
  WHERE Client_Connection_Id = @ConnectionID
--Delete any connections that are more than 2 months old
Select @StartTime = dateadd(Month, -2, dbo.fnServer_CmnGetDate(getutcdate())), @MinTime = MIN(Start_Time) 
  From Client_Connections
Declare MyCursor2 INSENSITIVE CURSOR
  For (Select top 5000 Client_Connection_Id
    From Client_Connections 
    Where Start_Time between @MinTime and @StartTime) 
  For Read Only
  Open MyCursor2
  MyLoop1:
    Fetch Next From MyCursor2 Into @@ClientId
    If (@@Fetch_Status = 0) 
      Begin
        Delete from Client_Connection_User_History where Client_Connection_Id = @@ClientId
        Delete from Client_Connection_App_Data where Client_Connection_Id = @@ClientId
        Delete from Client_Connection_Module_Data where Client_Connection_Id = @@ClientId
        Delete from Client_Connections where Client_Connection_Id = @@ClientId
        Goto MyLoop1
      End
Close MyCursor2
Deallocate MyCursor2
