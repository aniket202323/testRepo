CREATE FUNCTION [dbo].[fnCmn_IsUnitConfiguredForNPTime](
 	  @PU_Id Int)
RETURNS  Bit
/*
Summary: Returns 1 if the unit specified is configured for NP Time, else returns 0.
*/
AS
BEGIN
 	 Declare @isConfigured Bit
 	 If Exists(Select * From Prod_Units Where PU_Id = @PU_Id And Non_Productive_Category Is Not Null)
 	  	 Set @isConfigured = 1
 	 Else
 	  	 Set @isConfigured = 0
 	 Return @isConfigured
END
