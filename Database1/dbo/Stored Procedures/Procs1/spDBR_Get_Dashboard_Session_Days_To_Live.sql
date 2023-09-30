Create Procedure dbo.spDBR_Get_Dashboard_Session_Days_To_Live
@UserID int = 29,
@Node varchar(50) = ''
AS
declare @@sessionlife int
execute spServer_CmnGetParameter 168,@UserID, @Node, @@sessionlife output
 	 select @@sessionlife as Days_To_Live
