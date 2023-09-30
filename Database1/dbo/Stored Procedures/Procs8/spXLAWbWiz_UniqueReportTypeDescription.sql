CREATE PROCEDURE dbo.spXLAWbWiz_UniqueReportTypeDescription 
 	 @Description      Varchar(255) = NULL
AS
DECLARE @ReturnStatus 	  	                 Int
 	 --Needed to define return status
DECLARE @ThisDescription_IsUnique 	         Bit
DECLARE @ThisDescription_Is_Not_Unique 	         Bit
 	 --Initialize
SELECT @ReturnStatus = -1 	  	  	 
 	 --Define return status
SELECT @ThisDescription_IsUnique 	         = 1 	 --(Duplicate Not Found in Table)
SELECT @ThisDescription_Is_Not_Unique 	         = 0 	 --(Duplicate Found in Table)
If @Description Is NULL -- Grab all descriptions
  BEGIN
    SELECT DISTINCT Description FROM Report_Types
  END
Else --@Description NOT NULL; look for it
  BEGIN
    If EXISTS (SELECT RT.Report_Type_Id FROM Report_Types RT WHERE RT.Description = @Description)
      SELECT @ReturnStatus = @ThisDescription_Is_Not_Unique 
    Else
      SELECT @ReturnStatus = @ThisDescription_IsUnique
    --EndIf
    SELECT [ReturnStatus] = @ReturnStatus
  END
--EndIf:@Description
