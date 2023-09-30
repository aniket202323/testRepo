CREATE PROCEDURE dbo.spRS_IEPutReportTypeDependencies
 	   @RTD_Id 	  	 Int 	  	 --NOT USED
 	 , @Report_Type_Id 	 Int
 	 , @RDT_Id 	  	 Int
 	 , @Value 	  	 Varchar(255)
 	 , @RTD_Id_Target 	 Int OUTPUT
AS
/*  For use with IMPORT of report packages
    MSI-MT 8-14-2000
    MSI/MT/1-9-2001 added constraints check
*/
--local variables has either prefix 'l' or don't use underscore
Declare @lStatus 	  	 int
Declare @lRTDId 	  	  	 Int
Declare @lConstraintExists 	 Bit
SELECT @lStatus = -9191 	  	 --Initialized
If @RTD_Id Is NULL or @RTD_Id = 0 
    BEGIN
 	 SELECT @lStatus = -2000
 	 GOTO END_OF_PROC
    END
/* Check for Existence of unique [Report_Type_Id, RDT_Id, Value] Constraints
   We'll use this constraint to decide if incoming row info is for insert or update
*/
If EXISTS( SELECT  RTD.*  
 	    FROM    Report_Type_Dependencies RTD  
 	    WHERE   RTD.Report_Type_Id = @Report_Type_Id  
 	    AND     RTD.RDT_Id = @RDT_Id  
 	    AND     RTD.Value = @Value
 	 )
SELECT @lConstraintExists = 1 Else SELECT @lConstraintExists = 0
If @lConstraintExists = 0 	  	  	 --No Constraint exist; free to insert
    BEGIN
 	 INSERT INTO Report_Type_Dependencies
 	 (Report_Type_Id, RDT_Id, Value) Values(@Report_Type_Id, @RDT_Id, @Value)
 	 If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 20  --Successful insert
 	 SELECT @RTD_Id_Target = Scope_Identity()
    END
Else If @lConstraintExists = 1 	  	  	 --Yes constraints exists; get target's ID
    BEGIN
 	 SELECT @RTD_Id_Target = RTD.RTD_Id  
 	 FROM   Report_Type_Dependencies RTD  
 	 WHERE  RTD.Report_Type_Id = @Report_Type_Id  
 	 AND    RTD.RDT_Id = @RDT_Id  
 	 AND    RTD.Value = @Value
 	 SELECT @lStatus = 12 	  	  	 --No update, already up to date
    END
END_OF_PROC:
Return (@lStatus)
