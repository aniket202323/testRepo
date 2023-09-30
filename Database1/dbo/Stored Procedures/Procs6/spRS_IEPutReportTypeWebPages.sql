CREATE PROCEDURE dbo.spRS_IEPutReportTypeWebPages
 	   @RTW_Id 	  	 int 	  	 --NOT USED
 	 , @Report_Type_Id 	 int
 	 , @RWP_Id 	  	 int
 	 , @Page_Order 	  	 int
 	 , @RTW_Id_Target 	 int OUTPUT
AS
/*  For user with IMPORT of report packages
    MSI-MT 1-9-2001 added constraints check
*/
Declare @lStatus 	  	 int
Declare @lConstraintExists 	 Bit
SELECT @lStatus = -9191 	 --Initialized
SELECT @RTW_Id_Target = -9191
If @RTW_Id Is NULL or @RTW_Id = 0 
    BEGIN
 	 Select @lStatus = -2000
 	 GOTO END_OF_PROC
    END
/* Check for Existence of Unique contraint [Report_Type_Id, RWP_Id]
   We'll use this constraint to decide if input params will be used for insert
   or an update
*/
If EXISTS( SELECT RTWP.* 
 	    FROM   Report_Type_WebPages RTWP 
 	    WHERE  RTWP.Report_Type_Id = @Report_Type_Id  
 	    AND    RTWP.RWP_Id = @RWP_Id
 	  )
SELECT @lConstraintExists = 1 Else SELECT @lConstraintExists = 0
If @lConstraintExists = 0 	  	  	 --No constraint exists; free to insert
    BEGIN
 	 INSERT INTO Report_Type_WebPages
 	       (  Report_Type_Id,  RWP_Id,  Page_Order )
 	 Values( @Report_Type_Id, @RWP_Id, @Page_Order )
 	 If @@Error <> 0 Select @lStatus = @@Error Else SELECT @lStatus = 20
 	 SELECT @RTW_Id_Target = Scope_Identity() 	 
    END
Else If @lConstraintExists = 1 	  	  	 --Yes constraint exists; 
    BEGIN
 	 SELECT @RTW_Id_Target = RTWP.RTW_Id
 	 FROM   Report_Type_WebPages RTWP 
 	 WHERE  RTWP.Report_Type_Id = @Report_Type_Id  
 	 AND    RTWP.RWP_Id = @RWP_Id
 	 SELECT @lStatus = 12 	  	  	 --No update, already up to date
    END
END_OF_PROC:
Return (@lStatus)
