CREATE PROCEDURE dbo.spRS_IEPutReportTypeParameters 
 	   @RTP_Id  	  	  	 Int 	  	 -- NOT USED
 	 , @Report_Type_Id 	 Int
 	 , @RP_Id 	  	  	 Int =  NULL
 	 , @Default_Value 	 Varchar(7000) = NULL
 	 , @Optional 	  	  	 TinyInt
 	 , @RTP_Id_Target 	 Int  OUTPUT
AS
/*  
 	 ---------------
 	 Update 8-20-02 MSI/DS
 	 Input parameter @Default_Value and Local Parameter @lDefaultValue
 	 increased to varchar(7000)
    ---------------
    Update 8-13-02 MSI/DS
    Changes to the order of preference:
    If @Default_Value Is Null Then
        Use Target computer values
    Else
        Use PRP Package Values
    End If
    ---------------
    For Use with IMPORT of report packages
    MSI/MT 9-5-2000(included constraint check MSI/MT/1-9-2001)
*/
--------------------------------------------------
--Local variables use no underscore or prefix 'l'
--------------------------------------------------
Declare @lDefaultValue 	  	 Varchar(7000)
Declare @lStatus 	  	  	 Int
Declare @lKeyExists 	  	  	 Bit
Declare @ThisReportTypeRowExists 	 Bit
DECLARE @ThisParameterIsDefault 	  	 Bit
DECLARE @ThisParameterDefaultValue 	 Varchar(7000)
---------------
-- Initialize
---------------
SELECT @lStatus = -9191 	  	  	 
SELECT @RTP_Id_Target = -9191
If @RTP_Id = 0 OR @RTP_Id Is NULL 
    BEGIN
 	 SELECT @lStatus = -2000
 	 GOTO END_OF_PROC
    END
/* dbo.Report_Type_Parameters has unique constraint [@Report_Type_Id, @RP_Id]
   Check for Existence of this constraint. We'll use this constraint to 
   decide if input parm will be used for row insert or update
*/
If EXISTS (SELECT RTP.* FROM Report_Type_Parameters RTP WHERE RTP.Report_Type_Id = @Report_Type_Id AND RTP.RP_Id = @RP_Id)
    SELECT @ThisReportTypeRowExists = 1 
ELSE
    SELECT @ThisReportTypeRowExists = 0
--Get Default Requirements on this Report_Parameter (RP_ID) from Local Report_Parameters; 
--Msi/mt/9-17-2001
-----------------------------------
-- Get System Default_Value
-----------------------------------
SELECT 	 @ThisParameterIsDefault = Is_Default, 
 	 @ThisParameterDefaultValue = Default_Value
FROM  	 Report_Parameters 
WHERE  	 RP_Id = @RP_Id
--------------------------------------------------
-- Report Type Parameter Row does NOT exist; 
-- I N S E R T  A New Row For It
--------------------------------------------------
If @ThisReportTypeRowExists = 0 	  	  	 
    BEGIN
 	 --------------------------------------------
 	 -- If This Is A "Default" Parameter Then
 	 -- Use Local Default_Value, NULL Or Not
 	 --------------------------------------------
 	 /*
 	 If @ThisParameterIsDefault = 1 	  	 
 	     BEGIN
 	         INSERT INTO Report_Type_Parameters
 	               ( Report_Type_Id,  RP_Id,  Default_Value,  Optional ) 
 	         VALUES(@Report_Type_Id, @RP_Id, @ThisParameterDefaultValue, @Optional )
 	         If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 20
 	         SELECT @RTP_Id_Target = Scope_Identity()
 	     END
 	 */
 	 --------------------------------------------
 	 -- This Is NOT A "Default" Parameter
 	 -- @ThisParameterIsDefault = 0
 	 -- Use Local Default_Value Unless It Is Null
 	 --------------------------------------------
 	 --Else 
 	     BEGIN
 	  	 ----------------------------------------
 	  	 -- Nothing Was Passed In So
 	  	 -- Use Local Default_Value, Null Or Not
 	  	 ----------------------------------------
 	  	 If @Default_Value Is Null
 	  	     BEGIN
 	                 INSERT INTO Report_Type_Parameters
 	                       ( Report_Type_Id,  RP_Id,  Default_Value,  Optional ) 
 	                 VALUES(@Report_Type_Id, @RP_Id, @ThisParameterDefaultValue, @Optional )
 	                 If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 20
 	                 SELECT @RTP_Id_Target = Scope_Identity()
 	  	     END
 	  	 -----------------------------------
 	  	 -- Something Was Passed-In
 	  	 -- Use Passed-In Value
 	  	 -----------------------------------
 	  	 Else 
 	  	     BEGIN
 	                 INSERT INTO Report_Type_Parameters
 	                       ( Report_Type_Id,  RP_Id,  Default_Value,  Optional ) 
 	                 VALUES(@Report_Type_Id, @RP_Id, @Default_Value, @Optional )
 	                 If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 20
 	                 SELECT @RTP_Id_Target = Scope_Identity()
 	  	     END
 	  	 --EndIf
 	     END
 	 --EndIf
    END
-------------------------------
-- Yes Report Type Row Exists; 
-- Update It
-------------------------------
Else If @ThisReportTypeRowExists = 1 	  	 
    BEGIN
 	 SELECT 	 @RTP_Id_Target = @RTP_Id, 
 	  	 @lDefaultValue = RTP.Default_Value  
 	   FROM  	 Report_Type_Parameters RTP 
 	  WHERE  	 RTP.Report_Type_Id = @Report_Type_Id 
 	  	 AND RTP.RP_Id = @RP_Id
 	 --------------------------------------------
 	 -- If This Is A "Default" Parameter Then
 	 -- Use Local Default_Value, NULL Or Not
 	 --------------------------------------------
 	 /*
 	 If @ThisParameterIsDefault = 1 	  	  	 
 	     BEGIN
 	  	 UPDATE  	 Report_Type_Parameters
 	  	 SET     	 Default_Value = @ThisParameterDefaultValue, 
 	  	  	 Optional = @Optional
 	  	 WHERE   	 Report_Type_Id = @Report_Type_Id 
 	  	  	 AND RP_Id = @RP_Id 	  	 
 	  	 If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 10
 	     END 	 
 	 */
 	 -----------------------------------
 	 -- This Is NOT A Default Parameter
 	 -- @ThisParameterIsDefault = 0
 	 -----------------------------------
 	 --Else 
 	     BEGIN
 	  	 -----------------------------
 	  	 -- If Nothing Was Passed-In
 	  	 -- Use Local Default Value
 	  	 -----------------------------
 	  	 If @Default_Value Is Null
 	  	     BEGIN
 	  	         UPDATE  	 Report_Type_Parameters
 	  	            SET  	 Default_Value = @ThisParameterDefaultValue, 
 	  	  	  	 Optional = @Optional
 	  	          WHERE  	 Report_Type_Id = @Report_Type_Id 
 	  	  	  	 AND RP_Id = @RP_Id
 	  	         If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 11
 	  	     END
 	  	 ----------------------------------------------
 	  	 -- Something Was Passed In
 	  	 -- Update It With The Passed-In Value
 	  	 ----------------------------------------------
 	  	 Else 
 	  	     BEGIN
 	  	         UPDATE  	 Report_Type_Parameters
 	  	            SET  	 Default_Value = @Default_Value,
 	  	  	  	 Optional = @Optional
 	  	          WHERE  	 Report_Type_Id = @Report_Type_Id 
 	  	  	  	 AND RP_Id = @RP_Id
 	  	         If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 11
 	  	     END
 	  	 --EndIf @ThisParameterDefaultValue
 	     END
        --EndIf @ThisParameterIsDefault = 0
    END
--EndIf @ThisReportTypeRowExists
END_OF_PROC:
Return (@lStatus)
