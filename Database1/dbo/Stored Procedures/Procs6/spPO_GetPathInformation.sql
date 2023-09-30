Create Procedure dbo.spPO_GetPathInformation
 	 @Line_Id int
  AS
DECLARE @PathId Int
Create Table #PathData(FromPUId Int,ToPUId Int)
Declare pp_Cursor Cursor For 
 	 Select Distinct pp.Path_Id from  Production_Plan_Starts pps
 	 Join Production_Plan pp on pp.PP_Id = pps.PP_Id
 	 Join Prdexec_Paths pep on pep.Path_Id = pp.Path_Id and pep.pl_Id = @Line_Id and Is_Line_Production = 1
 	 Join Prod_Units pu On pu.PL_Id = pep.pl_Id 
 	 Where End_Time is null
Open pp_Cursor
pp_Cursor_Loop:
Fetch Next From pp_Cursor into @PathId
 	 If @@Fetch_Status = 0
 	   Begin
 	  	 Insert InTo #PathData(FromPUId,ToPUId) 
 	  	  	  	 Select Distinct  ppis.pu_Id,p.PU_Id
 	  	  	  	 From PrdExec_Path_units p
 	  	  	  	 Join PrdExec_Inputs ppi on ppi.PU_Id = p.PU_Id
 	  	  	  	 Join PrdExec_Path_Input_Sources ppis On ppis.PEI_Id = ppi.PEI_Id and ppis.Path_Id = p.Path_Id
 	  	  	  	 Where p.Path_Id = @PathId
 	  	 If @@Rowcount = 0
 	  	    Insert InTo #PathData(FromPUId,ToPUId) 
 	  	  	  	 Select Distinct  pis.pu_Id,p.PU_Id
 	  	  	  	 From PrdExec_Path_units p
 	  	  	  	 Join PrdExec_Inputs ppi on ppi.PU_Id = p.PU_Id
 	  	  	  	 Join prdexec_Input_Sources pis on pis.PEI_Id = ppi.PEI_Id
 	  	  	  	 Where p.Path_Id = @PathId
 	  	 Goto pp_Cursor_Loop
 	   End
Close pp_Cursor
Deallocate pp_Cursor
select * from #PathData
Drop Table #PathData
