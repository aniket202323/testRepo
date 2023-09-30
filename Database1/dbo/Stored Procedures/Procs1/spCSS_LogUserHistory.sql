CREATE PROCEDURE dbo.spCSS_LogUserHistory 
@ConnectionId int,
@UserId int,
@UserName nvarchar(50),
@Status tinyint
AS
 Declare @Id int
If @UserId = 0
  Select @Id = NULL
else
  Select @Id = @UserId
DECLARE @UTCNow Datetime,@DbNow Datetime
SELECT @UTCNow = Getutcdate()
SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
Insert into Client_Connection_User_History (Client_Connection_Id, User_Id, Username, Timestamp, CCS_Id) 
 Values (@ConnectionId, @Id, @UserName, @DbNow, @Status)
