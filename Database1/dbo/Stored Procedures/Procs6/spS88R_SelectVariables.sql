CREATE procedure [dbo].[spS88R_SelectVariables]
--Declare
@Variables nVarChar(1000),
@Unit int
AS
/*************************************
-- For Testing
--**************************************
Select @Variables = '1720,1722,1723,1724'
Select @Unit = 52
--****************************************/
Declare @SQL nVarChar(3000)
Select @SQL =  'Select Distinct VariableId = v.var_id, Variable = v.var_desc, Unit = pu2.pu_desc, Line = pl.pl_desc '
Select @SQL = @SQL + 'From Variables v '
Select @SQL = @SQL + 'Join Prod_Units pu1 on pu1.pu_id = v.pu_id '
Select @SQL = @SQL + 'Join Prod_Units pu2 on pu2.pu_id = case when pu1.master_unit is null then pu1.pu_id else pu1.master_unit End and pu2.pu_id = ' + convert(nVarChar(20),@Unit) + ' '
Select @SQL = @SQL + 'join Prod_Lines pl on pl.pl_id = pu2.pl_id '
Select @SQL = @SQL + 'Where v.var_id in (' + @Variables + ') '
Select @SQL = @SQL + 'Order By Unit, Line'
Exec (@SQL)
