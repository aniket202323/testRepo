Create Procedure dbo.spDBR_Get_Apps_Path 
@UserID int = 29,
@Node varchar(50) = ''
AS
declare @appsserver varchar(150)
declare @appspath varchar(50)
declare @webservices varchar(50)
declare @USEHttps VARCHAR(255)
declare @protocol varchar(10)
set @protocol='http://'
SELECT @USEHttps = Value FROM Site_Parameters WHERE Parm_Id = 90
if (@USEHttps='1')
begin
 set @protocol='https://'
end
execute spServer_CmnGetParameter 27,@UserID, @Node, @appsserver output
declare @slash varchar(2)
set @slash = (select right(@appsserver, 1))
if (@slash = '/')
begin
 	 set @appsserver = (select left(@appsserver, len(@appsserver)-1))
 	 end
 	 set @slash = (select left(@appsserver, 2))
 	 if (@slash = '//')
 	 begin
 	  	 set @appsserver = (select right(@appsserver, len(@appsserver)-2))
 	 end
set @appsserver =@protocol + @appsserver + '/'
execute spServer_CmnGetParameter 30,@UserID, @Node, @appspath output
set @slash = (select right(@appspath, 1))
if (@slash = '/')
begin
 	 set @appspath = (select left(@appspath, len(@appspath)-1))
 	 end
 	 set @slash = (select left(@appspath, 1))
 	 if (@slash = '/')
 	 begin
 	  	 set @appspath = (select right(@appspath, len(@appspath)-1))
 	 end
set @appsserver = @appsserver + @appspath + '/'
execute spServer_CmnGetParameter 310,@UserID, @Node, @webservices output
set @slash = (select right(@webservices, 1))
if (@slash = '/')
begin
 	 set @webservices = (select left(@webservices, len(@webservices)-1))
 	 end
 	 set @slash = (select left(@webservices, 1))
 	 if (@slash = '/')
 	 begin
 	  	 set @webservices = (select right(@webservices, len(@webservices)-1))
 	 end
--set @appsserver = @appsserver + @webservices
select @appsserver as path, @webservices as WSDM
 	  	  	 
