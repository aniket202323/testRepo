CREATE PROCEDURE [dbo].[sps88r_StatusList]
@Units nVarChar(1000)
AS
Declare @Sql nVarChar(1000)
Create Table #SelectedUnits(
 	 PU_Id Int
)
If @Units Is Not Null
Begin
 	 Select @Sql = 'Insert Into #SelectedUnits Select PU_Id From Prod_Units Where PU_Id In (' + @Units + ')'
 	 Execute(@Sql)
End
If @Units Is Null
 	 Select Distinct Id = prodstatus_id, Status = prodstatus_desc
 	 From production_status
 	 Order By prodstatus_desc
Else
 	 Select Distinct Id = s.prodstatus_id, Status = s.prodstatus_desc
 	 From production_status s
 	 Join PrdExec_Status v On v.Valid_Status = s.ProdStatus_Id
 	 Join #SelectedUnits u On u.PU_Id = v.PU_Id
 	 Order By s.prodstatus_desc 	 
