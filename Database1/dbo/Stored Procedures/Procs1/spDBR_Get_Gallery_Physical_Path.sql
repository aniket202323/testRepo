Create Procedure dbo.spDBR_Get_Gallery_Physical_Path
@UserID int,
@Node varchar(50)
AS
declare @path varchar(300)
execute spServer_CmnGetParameter 158,@UserID, '', @path output
select @path as Path
