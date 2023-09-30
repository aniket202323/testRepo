-- declare @Value varchar(5000) exec dbo.spCSS_GetParameter 327,null,null,'mm/dd/yyyy hh:mm:ss',@value OUTPUT select @value
CREATE PROCEDURE dbo.spCSS_GetParameter 
@ParmId int,
@UserId int,
@HostName varchar, 
@DefaultValue varchar(5000) = NULL, 
@Value varchar(5000) OUTPUT
AS
select @Value = dbo.fnServer_CmnGetParameter(
          @ParmId ,
          @UserId ,
          @HostName , 
          @DefaultValue,
 	   Null) 
