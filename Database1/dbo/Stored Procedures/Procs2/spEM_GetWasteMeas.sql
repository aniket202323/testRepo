Create Procedure dbo.spEM_GetWasteMeas
   @PU_Id             int
  AS
  --
    SELECT  WEMT_Id,WEMT_Name,Conversion,Conversion_Spec,Var_Desc
      FROM Waste_Event_Meas w
      LEFT JOIN Variables ON Conversion_Spec = Var_Id
      WHERE w.PU_Id  = @PU_Id
