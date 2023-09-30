CREATE PROCEDURE dbo.spEM_ShowStoredProcedure 
 	 @SPNAME     nVarChar(100),
 	 @Parameters nvarchar(255)
  AS
Select @Parameters = coalesce(@Parameters, ' ')
Execute (@SPNAME + ' ' + @Parameters)
