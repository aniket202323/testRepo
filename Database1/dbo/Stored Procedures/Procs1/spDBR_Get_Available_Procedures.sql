Create Procedure dbo.spDBR_Get_Available_Procedures
@filter varchar(100)
AS
 	 declare @sqlfilter varchar(100)
 	 set @sqlfilter = '%' + @filter + '%'
 	 
 	 if (@filter = '')
 	 begin
 	  	 /*select Command_Text from Client_SP_Prototypes */
 	  	 select o.name from sysobjects o  where o.xtype = 'p' and left(o.name,2) = 'sp'
 	 end
 	 else
 	 begin
 	  	 select o.name from sysobjects o  where o.xtype = 'p' and left(o.name,2) = 'sp' and o.name like @sqlfilter
 	 /* 	 select Command_Text from Client_SP_Prototypes where command_text like @sqlfilter 	 */
 	 end
