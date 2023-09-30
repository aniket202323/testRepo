Create Procedure dbo.spDBR_Get_Gallery_Virtual_Path
@UserID int,
@Node varchar(500)
AS
declare @path varchar(300)
execute spServer_CmnGetParameter 163,@UserID, @Node, @path output
select @path as Path
