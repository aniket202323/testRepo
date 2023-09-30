Create Procedure dbo.spAL_GetPUIDs
  @PEIId Int
 AS
  -- Select Result Information.
  Select PU_Id
    From PrdExec_Input_Sources
    Where PEI_Id = @PEIId
RETURN(0)
