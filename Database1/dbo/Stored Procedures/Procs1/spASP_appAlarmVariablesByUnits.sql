CREATE procedure [dbo].[spASP_appAlarmVariablesByUnits]
--declare 
@Units nVarChar(1000),
@UnitId int,
@SearchString nVarChar(50),
@UserId int = NULL
AS
/***************************
--For Testing
--***************************
Select @Units = '2'
Select @UnitId = 2 
Select @SearchString = null
--***************************/
Create Table #Units (
  ItemOrder int,
  Item int 
)
Insert Into #Units (Item, ItemOrder)
  execute ('Select Distinct PU_Id, ItemOrder = CharIndex(convert(nvarchar(10),PU_Id),' + '''' + @Units + ''''+ ',1)  From Prod_Units Where PU_Id in (' + @Units + ')' + ' and pu_id <> 0')
If @UnitId Is Not Null
  Begin
    If @SearchString Is Null
      Begin
        Select Distinct Id = v.Var_Id, Description = v.var_desc 
 	  	  	  	   From variables v  
 	  	  	  	   Join Prod_units pu on pu.pu_id = v.pu_id and (pu.pu_id = @UnitId or pu.master_unit = @UnitId)
          Join #Units u on u.Item = pu.pu_id
 	  	  	  	   Join alarm_template_var_data a on a.var_id = v.var_id
          Order By Description 
      End
    Else
      Begin
        Select Distinct Id = v.Var_Id, Description = v.var_desc 
 	  	  	  	   From variables v  
 	  	  	  	   Join Prod_units pu on pu.pu_id = v.pu_id and (pu.pu_id = @UnitId or pu.master_unit = @UnitId)
          Join #Units u on u.Item = pu.pu_id
 	  	  	  	   Join alarm_template_var_data a on a.var_id = v.var_id
          where v.var_desc like '%' + @SearchString + '%'
          Order By Description 
      End
  End
Else
  Begin
    If @SearchString Is Null
      Begin
        Select Distinct Id = v.Var_Id, Description = v.var_desc 
 	  	  	  	   From variables v  
 	  	  	  	   Join Prod_units pu on pu.pu_id = v.pu_id
          Join #Units u on u.Item = pu.pu_id
 	  	  	  	   Join alarm_template_var_data a on a.var_id = v.var_id
          Order By Description 
      End
    Else
      Begin
        Select Distinct Id = v.Var_Id, Description = v.var_desc 
 	  	  	  	   From variables v  
 	  	  	  	   Join Prod_units pu on pu.pu_id = v.pu_id
          Join #Units u on u.Item = pu.pu_id
 	  	  	  	   Join alarm_template_var_data a on a.var_id = v.var_id
          where v.var_desc like '%' + @SearchString + '%'
          Order By Description 
      End
  End
Drop Table #Units
