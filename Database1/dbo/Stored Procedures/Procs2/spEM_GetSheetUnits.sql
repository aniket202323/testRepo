CREATE PROCEDURE dbo.spEM_GetSheetUnits 
@SheetId  int,
@LineId 	   Int 
AS
 	 SELECT Display = s.Sheet_Desc,Line = pl.Pl_desc,Unit =  pu.PU_Desc
 	  	 FROM Sheet_Unit  su
 	  	 Join sheets s on s.Sheet_Id = su.Sheet_Id 
 	  	 Join Prod_Units pu on pu.PU_Id = su.PU_Id
 	  	 Join Prod_Lines pl on pl.PL_Id = pu.PL_Id 
 	  	 WHERE s.Sheet_Type = 30 and su.Sheet_Id <> @SheetId and pu.PL_Id = @LineId
