Create Procedure dbo.spDBR_Get_Sp
@spname varchar(100)
AS
 	 declare @objname as nvarchar(100)
 	 set @objname = N'[dbo].['
 	 set @objname = @objname + @spname
 	 set @objname = @objname + N']'
 	 
 	 select text from syscomments where id= object_id(@objname) for xml auto
