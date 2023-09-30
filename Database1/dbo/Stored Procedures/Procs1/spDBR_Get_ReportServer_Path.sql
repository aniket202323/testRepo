Create Procedure dbo.spDBR_Get_ReportServer_Path
@UserID int = 1,
@Node varchar(50) = ''
AS
declare @path varchar(300)
execute spServer_CmnGetParameter 10,@UserID, @Node, @path output
declare @USEHttps VARCHAR(255)
declare @protocol varchar(10)
set @protocol='http://'
SELECT @USEHttps = Value FROM Site_Parameters WHERE Parm_Id = 90
if (@USEHttps='1')
begin
 set @protocol='https://'
end
declare @slash varchar(2)
set @slash = (select right(@path, 1))
if (@slash = '/')
begin
 	 set @path = (select left(@path, len(@path)-1))
 	 end
 	 set @slash = (select left(@path, 2))
 	 if (@slash = '//')
 	 begin
 	  	 set @path = (select right(@path, len(@path)-2))
 	 end
set @path = @protocol + @path + '/viewer/rsFrontDoor.asp?'
select @path as path
 	  	  	 
