--  spEMAC_GetAttachedVariables 4,1
Create Procedure dbo.spEMAC_GetAttachedVariables 
@ATId int,
@User_Id int
AS
Declare @Alarm_Type_Id int
Select @Alarm_Type_Id = Alarm_Type_Id from Alarm_Templates where AT_Id = @ATId
DECLARE  @AttachedVariables table(
  AT_Id int,
  AT_Desc nvarchar(50),
  ATD_Id int,
  Var_Id int,
  VariableRule_Comment_Id int,
  Var_Desc nvarchar(50),
  PU_Id int,
  Variable_Comment_Id int,
  PU_Desc nvarchar(50),
  PL_Id int,
  PL_Desc nvarchar(50),
  EG_Id int,
  EG_Desc nVarChar(100),
  PUG_Desc nvarchar(50),
  PVar_Id int,
  Sampling_Size 	 Int,
  VarsWithSamplingSize Int)
If @Alarm_Type_Id = 1
  Begin
 	  	 insert into @AttachedVariables(AT_Id,AT_Desc,ATD_Id,Var_Id,VariableRule_Comment_Id,
 	  	  	  	  	  	  	  	  	  	 EG_Id,EG_Desc,Sampling_Size)
 	  	  	 select a.AT_Id, a.AT_Desc, b.ATD_Id, b.Var_Id, b.Comment_Id,
 	  	  	  	  	  c.EG_Id, c.EG_Desc, Sampling_Size = isnull(b.Sampling_Size,0)
 	  	  	 from Alarm_Templates a
 	  	  	 join alarm_template_var_data b on a.at_id = b.at_id
 	  	  	 left outer join email_groups c on c.EG_Id = b.EG_Id
 	  	  	 where a.AT_Id = @ATId and b.atvrd_id is NULL
  End
Else
 	  	 insert into @AttachedVariables(AT_Id,AT_Desc,ATD_Id,Var_Id,VariableRule_Comment_Id,
 	  	  	  	  	  	  	  	  	  	 EG_Id,EG_Desc,Sampling_Size)
 	 select a.AT_Id, a.AT_Desc, b.ATD_Id, b.Var_Id, b.Comment_Id,
 	   c.EG_Id, c.EG_Desc,Sampling_Size =isnull(b.Sampling_Size,0)
 	 from Alarm_Templates a
 	 join alarm_template_var_data b on a.at_id = b.at_id
 	 left outer join email_groups c on c.EG_Id = b.EG_Id
 	 where a.AT_Id = @ATId and b.atsrd_id is NULL
update @AttachedVariables set Var_Desc = Variables.Var_Desc, PU_Id = Variables.PU_Id, 
 	  	  	  	  	  	  	 Variable_Comment_Id = Variables.Comment_Id, 
 	  	  	  	  	  	  	 PUG_Desc = PU_Groups.PUG_Desc, PVar_Id = Variables.PVar_Id
from Variables
join @AttachedVariables  a on a.Var_Id = Variables.Var_Id
join PU_Groups on PU_Groups.PUG_Id = Variables.PUG_Id
update @AttachedVariables set PU_Desc = Prod_Units.PU_Desc, PL_Id = Prod_Units.PL_Id
from Prod_Units
join @AttachedVariables a on a.PU_Id = Prod_Units.PU_Id
update @AttachedVariables set PL_Desc = Prod_Lines.PL_Desc
from Prod_Lines
join @AttachedVariables a on a.PL_Id = Prod_Lines.PL_Id
update @AttachedVariables set PL_Desc = Prod_Lines.PL_Desc
from Prod_Lines
join @AttachedVariables a on a.PL_Id = Prod_Lines.PL_Id
update @AttachedVariables set VarsWithSamplingSize = (select COUNT(*)
from alarm_template_var_data  a
WHERE a.Sampling_Size > 0  and a.Var_Id = c.Var_Id and a.AT_Id != @ATId)
FROM @AttachedVariables c
update @AttachedVariables set VarsWithSamplingSize = 0 WHERE VarsWithSamplingSize is NULL
select*  from @AttachedVariables
order by Var_Desc
