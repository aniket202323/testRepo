CREATE PROCEDURE dbo.spRS_IEPutReportWebPageParameters
 	   @Rpt_WebPage_Param_Id 	  	 int 	  	 --NOT USED
 	 , @RP_Id 	  	  	 int
 	 , @RWP_Id 	  	  	 int
 	 , @Rpt_WebPage_Param_Id_Target 	 int OUTPUT
AS
/*  For use with IMPORT of report packages
    MSI-MT 8-14-2000
*/
Declare @lStatus 	  	 int
Declare @lConstraintExists 	 Bit
SELECT @lStatus = -9191
SELECT @Rpt_WebPage_Param_Id_Target = -9191
If @Rpt_WebPage_Param_Id = 0 OR @Rpt_WebPage_Param_Id Is NULL
    BEGIN
 	 SELECT @lStatus = -2000
 	 GOTO   END_OF_PROC
    END
/* dbo.Report_WebPage_Parameters has unique [RP_Id, RWP_Id] constraint 
   We'll use this constraint to decide if input params are to be inserted
*/
If EXISTS( SELECT RWPP.* 
 	    FROM   Report_WebPage_Parameters RWPP 
 	    WHERE  RWPP.RP_Id = @RP_Id 
 	   AND     RWPP.RWP_Id = @RWP_Id 
 	  )
SELECT @lConstraintExists = 1 Else SELECT @lConstraintExists = 0
If @lConstraintExists = 0 	  	  	 --No constraint exists; insert
    BEGIN
 	 INSERT INTO Report_WebPage_Parameters
 	 ( RP_Id, RWP_Id )  Values( @RP_Id, @RWP_Id )
 	 If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 20
 	 SELECT @Rpt_WebPage_Param_Id_Target = Scope_Identity()
    END
Else If @lConstraintExists = 1 	  	  	 --Yes constraint exists; get target ID
    BEGIN
 	 SELECT @Rpt_WebPage_Param_Id_Target = RWPP.Rpt_WebPage_Param_Id
 	 FROM   Report_WebPage_Parameters RWPP 
 	 WHERE  RWPP.RP_Id = @RP_Id 
 	 AND    RWPP.RWP_Id = @RWP_Id 
 	 SELECT @lStatus = 12 	  	  	 --No Update; already up to date
    END
END_OF_PROC:
Return (@lStatus)
