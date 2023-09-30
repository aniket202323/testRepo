Create Procedure dbo.spDBR_Get_Ad_Hoc_Port
@UserID int,
@Node varchar(50)
AS
declare @port varchar(50)
execute spServer_CmnGetParameter 161,@UserID, @Node, @port output
select @port as port_num
 	  	  	 
