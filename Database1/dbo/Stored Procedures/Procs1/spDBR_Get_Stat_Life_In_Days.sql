Create Procedure dbo.spDBR_Get_Stat_Life_In_Days
@UserID int = 29,
@Node varchar(50) = ''
AS
declare @@statlife int
execute spServer_CmnGetParameter 169,@UserID, @Node, @@statlife output
 	 select @@statlife as Days_To_Live
