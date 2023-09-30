Create Procedure dbo.spDBR_Get_Date_Desc
@timeformula varchar(50)
as
 	 insert into #sp_name_results execute spDBR_Shortcut_To_Time @TimeFormula
