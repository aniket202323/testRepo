Create Procedure dbo.spDBR_GetParameterTabBit
@UserID int = 27,
@Node varchar(50) = ''
AS
 	 
 	 declare @value varchar(50)
 	 execute spServer_CmnGetParameter 162,@UserID, @Node, @value output
 	 
select coalesce(@value, 0) as value
