-- spEMCC_ByStrName 11,null,1
CREATE PROCEDURE dbo.spEMCC_ByStrName
  @ListType int, @str nvarchar(255), @User_Id int
AS
  if @str is null
    select @str = '(null)'
if @ListType = 11 -- called by SearchCalcs
begin
  create table #mason567 (Calculation_Id int, Calculation_Name nvarchar(255), Calculation_Desc nvarchar(255), Calculation_Type_Desc nvarchar(50), Calc_Type_Id int, VersionNum nVarChar(10), LockedInfo bit, Trigger_Type_Id int, Cmt_Id int, Num_Of_Uses int null,Optimize_Calc_Runs Int)
      if @str = '' 
        insert into #mason567 (Calculation_Id, Calculation_Name, Calculation_Desc, Calculation_Type_Desc, Calc_Type_Id, VersionNum, LockedInfo, Trigger_Type_Id, Cmt_Id, num_of_uses,Optimize_Calc_Runs )
        select ca.Calculation_ID, Calculation_Name, ca.Calculation_Desc, calculation_type_desc, ca.calculation_type_id, version, locked, trigger_type_id, ca.comment_id, (select count(v.calculation_id) from variables v where v.calculation_id = ca.calculation_id), isnull(Optimize_Calc_Runs,1)
 	     from calculations ca
  	     join calculation_types ct on ca.calculation_type_id = ct.calculation_type_id
 	  	 Where System_Calculation is NULL
                 order by calculation_name desc 
      else
        insert into #mason567 (Calculation_Id, Calculation_Name, Calculation_Desc, Calculation_Type_Desc, Calc_Type_Id, VersionNum, LockedInfo, Trigger_Type_Id, Cmt_Id, num_of_uses,Optimize_Calc_Runs )
        select ca.Calculation_ID, Calculation_Name, ca.Calculation_Desc, calculation_type_desc, ca.calculation_type_id, version, locked, trigger_type_id, ca.comment_id, (select count(v.calculation_id) from variables v where v.calculation_id = ca.calculation_id), isnull(Optimize_Calc_Runs,1)
 	     from calculations ca
                 join calculation_types ct on ca.calculation_type_id = ct.calculation_type_id
            where calculation_name like '%' + @str + '%'  and System_Calculation is NULL
 	   order by calculation_name desc 
  select * from #mason567
  drop table #mason567
end
else if @ListType = 96
  select calculation_id from calculations where calculation_name like @str
else if @ListType = 97
    select name from sysobjects where name like @str
else if @ListType = 98
        execute sp_helptext  @str
else
  select Error = 'Error!!!'
