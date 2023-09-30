CREATE PROCEDURE dbo.spEMPE_SetProtocol
@enableSSL bit =1
AS
Declare @port nVarChar(10)
Declare @slashIndex int
Declare @columnIndex int
Declare @currentRS varchar(5000)
Declare @currentWeb varchar(5000)
Declare @newRSValue varchar(5000)
Declare @newWebValue varchar(5000)
Declare @machineName nvarchar(500)
select @currentRS=value from Site_Parameters p where p.Parm_Id=10  -- in the form of server:port/PAReporting
select @currentWeb=value from Site_Parameters p where p.Parm_Id=27  -- in the form of server:port
select @port=value from Site_Parameters p where p.Parm_Id=91
 	  	  	 
select @columnIndex=CHARINDEX(':', @currentWeb)
 if (@columnIndex=0)  --no ':' so we are in old style machine name only
 begin
 	 select @newWebValue=@currentWeb
 end
else
 begin
   select @newWebValue=substring(@currentWeb,1,@columnIndex-1)
 end
 select @slashIndex=CHARINDEX('/', @currentRS)
 select @columnIndex=CHARINDEX(':', @currentRS)
  if (@columnIndex=0)  --no ':' so we are in old style machine name 
 begin
 	 select @machineName=substring(@currentRS,1,@slashIndex-1)
 end
else
 begin
   select @machineName=substring(@currentRS,1,@columnIndex-1)
 end
 	 update site_parameters set value = @enableSSL where parm_id = 90
if (@enableSSL=1) 
 	 begin 
 	  	 select @Port=RTRIM(LTRIM(value)) from Site_Parameters p where p.Parm_Id=92
 	  	 select @newWebValue=@newWebValue+':'+@Port
 	  	 select @newRSValue=@machineName+':'+@Port+'/'+SUBSTRING(@currentRS,@slashIndex+1,LEN(@currentRS)-@slashIndex)
 	  	 update dbo.Report_Tree_Nodes set URL=REPLACE(URL,'http://','https://')
 	  	 update dbo.Report_Tree_Nodes set URL=REPLACE(URL, 'https://'+@machineName+'/','https://'+@newWebValue+'/')
 	  	 update dbo.Report_Tree_Nodes set URL=REPLACE(URL, 'https://'+@currentWeb+'/','https://'+@newWebValue+'/')
 	  	 update dbo.Dashboard_Users set Dashboard_Key=REPLACE(Dashboard_Key,'http://','https://')
 	  	 update dbo.Dashboard_Users set Dashboard_Key=REPLACE(Dashboard_Key, 'https://'+@machineName+'/','https://'+@newWebValue+'/') 	  	 
 	  	 update dbo.Dashboard_Users set Dashboard_Key=REPLACE(Dashboard_Key, 'https://'+@currentWeb+'/','https://'+@newWebValue+'/') 	  	 
 	 end
else
 	 begin
 	  	 select @Port=RTRIM(LTRIM(value)) from Site_Parameters p where p.Parm_Id=91
 	  	 select @newWebValue=@newWebValue+':'+@Port
 	  	 select @newRSValue=@machineName+':'+@Port+'/'+SUBSTRING(@currentRS,@slashIndex+1,LEN(@currentRS)-@slashIndex)
 	  	 update dbo.Report_Tree_Nodes set URL=REPLACE(URL,'https://','http://')
 	  	 update dbo.Report_Tree_Nodes set URL=REPLACE(URL, 'http://'+@machineName+'/','http://'+@newWebValue+'/')
 	  	 update dbo.Report_Tree_Nodes set URL=REPLACE(URL,'http://'+@currentWeb+'/','http://'+@newWebValue+'/')
 	  	 update dbo.Dashboard_Users set Dashboard_Key=REPLACE(Dashboard_Key,'https://','http://')
 	  	 update dbo.Dashboard_Users set Dashboard_Key=REPLACE(Dashboard_Key,'http://'+@machineName+'/','http://'+@newWebValue+'/')
 	  	 update dbo.Dashboard_Users set Dashboard_Key=REPLACE(Dashboard_Key,'http://'+@currentWeb+'/','http://'+@newWebValue+'/') 	  	 
 	 end
 	 
update Site_Parameters set Value=@newWebValue where Parm_Id = 27
update Site_Parameters set Value=@newRSValue where Parm_Id=10
