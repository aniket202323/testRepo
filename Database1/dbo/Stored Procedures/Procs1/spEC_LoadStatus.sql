Create Procedure dbo.spEC_LoadStatus 
 AS
Select Status_Name = ProdStatus_Desc,Status_Id = ProdStatus_Id,Color = Case when c.color Is Null then 16777215
 	  	  	  	  	  	  	  	  	 Else c.color
 	  	  	  	  	  	  	  	  	 End,Icon_Id,LockData = coalesce(LockData,0)
 From Production_Status ps
 Left Join Colors c on c.Color_Id = ps.Color_Id 
order by ProdStatus_Desc
Select PU_Id,From_ProdStatus_Id,To_ProdStatus_Id,
 	 Status_Valid_For_Input = Case When Status_Valid_For_Input is Null Then 0
 	  	  	  	 Else Status_Valid_For_Input
 	  	  	  	 End
 	 From prdexec_trans pt
 	 Join Production_Status ps on ps.ProdStatus_Id = To_ProdStatus_Id
Order By PU_Id,From_ProdStatus_Id,ProdStatus_Desc
