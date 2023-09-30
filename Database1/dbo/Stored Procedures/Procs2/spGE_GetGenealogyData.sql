Create Procedure dbo.spGE_GetGenealogyData 
 	 @unit_Id int
 AS
  set nocount on
  Declare @PathId Int
  Select @PathId = Null
  Select @PathId =  Path_Id 
 	 From PrdExec_Path_Unit_Starts
 	 Where End_Time is Null and PU_Id = @Unit_Id
  SELECT PU_Id, PU_Desc
    FROM Prod_Units
    where PU_id  = @unit_Id
  Create Table   #ProdPath (Pu_Desc nvarchar(50),Source_PU_Desc nvarchar(50),PU_Id Int,Source_PU_Id Int,Step Int,HideInput Int,AllowManualMovement Int) 
  If @PathId is null
     Begin
      INSERT into #ProdPath (Pu_Desc,Source_PU_Desc,PU_Id,Source_PU_Id,Step,HideInput,AllowManualMovement) 
 	  	 Select  Distinct   	 pu.PU_Desc, 	 Source_PU_Desc = Input_Name,
 	  	  	 Source_PU_Id =  pei.PEI_Id, 	 ps.PU_Id,Step   = Input_Order,0,1
 	  	 From  prdexec_status ps
 	  	 Join PrdExec_inputs pei on pei.PU_Id = ps.pu_Id
 	  	 JOIN Prod_Units pu ON pu.PU_ID = ps.Pu_Id
 	  	 Where  ps.Pu_Id = @Unit_Id
     End
  Else
 	 Begin
      INSERT into #ProdPath (Pu_Desc,Source_PU_Desc,PU_Id,Source_PU_Id,Step,HideInput,AllowManualMovement) 
 	  	 Select  Distinct   	 pu.PU_Desc, 	 Source_PU_Desc = Input_Name,Source_PU_Id =  pei.PEI_Id,
 	  	  	  	  	  	  	 pei.PU_Id,Step   = Input_Order,Hide_Input,Allow_Manual_Movement
 	  	 From PrdExec_Path_Inputs ppi
 	  	 Join PrdExec_inputs pei on pei.PEI_Id = ppi.PEI_Id and pei.pu_Id = @Unit_Id
 	  	 JOIN Prod_Units pu ON pu.PU_ID = pei.Pu_Id
 	  	 Where  ppi.Path_Id = @PathId
 	 End
  INSERT into #ProdPath (Pu_Desc,Source_PU_Desc,PU_Id,Source_PU_Id,Step,HideInput,AllowManualMovement) 
 	 Select  Distinct  	 PU_Desc,Source_PU_Desc = PU_Desc,PU_Id, 	 Source_PU_Id =  PU_Id, 	 1,0,1
 	 From Prod_Units
 	 Where pu_Id = @Unit_Id 
  select * From #ProdPath
  set nocount off
