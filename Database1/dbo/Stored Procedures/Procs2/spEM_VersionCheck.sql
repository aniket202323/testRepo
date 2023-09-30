CREATE PROCEDURE dbo.spEM_VersionCheck
  @Version_Check nVarChar(10),
  @Current_Version nVarChar(10) OUTPUT
  AS
  --
  -- Return Code  0      = Success
  --              50500  = Failure
  --
  SELECT @Current_Version = '41'
  IF @Version_Check <> @Current_Version
    RETURN(1)
  RETURN(0)
