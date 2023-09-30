CREATE PROCEDURE dbo.spRS_IEPutReportWebPageDependencies
 	   @RWD_Id 	  	 int  	  	  	 --NOT USED
 	 , @RWP_Id 	  	 int
 	 , @RDT_Id 	  	 int
 	 , @Value 	  	 Varchar(255)
 	 , @RWD_Id_Target 	 Int  OUTPUT
AS
/*  For use with IMPORT of report packages
    MSI-MT 8-14-2000
    Included constraint check (MST/MT/1-10-2001)
*/
--'local' vars use prefix 'l' or no underscores
Declare @lStatus 	  	 int
Declare @lContraintExists 	 Bit
SELECT @lStatus = -9191
SELECT @RWD_Id_Target = -9191
If @RWD_Id= 0 OR @RWD_Id Is NULL
    BEGIN
 	 Select @lStatus = -2000
 	 GOTO  END_OF_PROC
    END
/* Check If unique [RWP_Id, RDT_Id, Value] constraint exists
   We'll use this constraint to determine if we need insert
   or update of the input row
*/
If EXISTS ( SELECT RWPD.RWD_Id  
 	     FROM   Report_WebPage_Dependencies RWPD
      	     WHERE  RWPD.RWP_Id = @RWP_Id  
 	     AND    RWPD.RDT_Id = @RDT_Id  
 	     AND    RWPD.Value = @Value
     	   )
SELECT @lContraintExists = 1 Else SELECT @lContraintExists = 0
If @lContraintExists = 0 	  	  	 --No constraints; will insert
    BEGIN
 	 INSERT INTO Report_WebPage_Dependencies
 	 ( RWP_Id, RDT_Id, Value ) Values( @RWP_Id, @RDT_Id, @Value )
 	 If @@Error <> 0 Select @lStatus = @@Error Else Select @lStatus = 20
 	 Select @RWD_Id_Target = Scope_Identity()
    END
Else If @lContraintExists = 1 	  	  	 --Yes Constraint exists; get target ID
    BEGIN
 	 SELECT  @RWD_Id_Target = RWPD.RWD_Id  
 	 FROM    Report_WebPage_Dependencies RWPD
      	 WHERE   RWPD.RWP_Id = @RWP_Id  
 	 AND     RWPD.RDT_Id = @RDT_Id  
 	 AND     RWPD.Value  = @Value
 	 SELECT  	 @lStatus = 12 	  	  	 --No update, already up to date
    END
END_OF_PROC:
Return (@lStatus)
