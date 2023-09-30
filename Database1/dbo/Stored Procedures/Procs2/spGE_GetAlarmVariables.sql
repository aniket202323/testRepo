CREATE PROCEDURE dbo.spGE_GetAlarmVariables
  @PuId int
  AS
   Select Distinct p.PU_Id,atd.Var_Id
 	  	 From  Alarm_Template_Var_Data atd
 	  	 Join  variables v on v.Var_Id = atd.Var_Id
 	  	 Join Prod_Units p ON p.PU_Id = v.Pu_Id
 	  	 Where v.pu_Id  = @PUId
