CREATE PROCEDURE dbo.spRS_IEPutReportParameters
 	   @RP_Id 	  	  	 Int 	  	  	 --NOT USED
 	 , @RP_Name 	  	  	 Varchar(50) 	  	 --Our "practical Key"
 	 , @RPT_Id 	  	  	 Int
 	 , @RPG_Id 	  	  	 Int = NULL
 	 , @Description 	  	 Varchar(255) = NULL
 	 , @Default_Value 	 Varchar(7000) = NULL
 	 , @Is_Default 	  	 Tinyint
 	 , @spName 	  	  	 Varchar(50) = NULL
 	 , @MultiSelect 	  	 TinyInt = NULL
 	 , @RP_Id_Target 	  	 Int 	 OUTPUT
AS
/*  
    @RP_Name was Varchar(20)
    This field should be Varchar(50)
    Revised MSI/DS 5-31-2002
    For use with IMPORT of report packages
    MSI-MT 8-15-2000
    Revised MSI/MT/1-9-2001
*/
Declare @lRPId 	  	 Int
Declare @DefaultValue 	 Varchar(50)
Declare @lStatus 	 Int
Declare @lRPNameExists 	 Bit
SELECT @lStatus = -9191
SELECT @RP_Id_Target = -9191
If @RP_Id = 0 OR @RP_Id Is NULL
    BEGIN
 	 Select @lStatus = -2000
 	 GOTO END_OF_PROC
    END
/* Check for Existing of Unique Report Parameter Name which is our "Practical Key"
   dbo.Report_Parameters has unique RP_Name
   MSI/MT/1-9-2001
*/
If EXISTS(SELECT RP.RP_Id  FROM Report_Parameters RP  WHERE RP.RP_Name = @RP_Name)
  Begin
 	 SELECT @lRPNameExists = 1
  End
Else 
  Begin
 	 SELECT @lRPNameExists = 0
  End
If @lRPNameExists = 0 	  	  	  	 --No RP_Name exists; free to insert
    BEGIN
 	 INSERT INTO Report_Parameters
 	       (RP_Name,  RPT_Id,  RPG_Id,  Description,  Default_Value,  Is_Default,  spName,  MultiSelect)
 	 Values(@RP_Name, @RPT_Id, @RPG_Id, @Description, @Default_Value, @Is_Default, @spName, @MultiSelect)
 	 If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 20
 	 SELECT @RP_Id_Target = Scope_Identity()
 	 if @@Error <> 0 SELECT @lStatus = @@Error
    END
Else If @lRPNameExists = 1 	  	  	 --Yes RP_Name exists; do update
    BEGIN
 	 SELECT @RP_Id_Target = RP.RP_Id, @DefaultValue = RP.Default_Value  
 	 FROM Report_Parameters RP  WHERE RP.RP_Name = @RP_Name
 	 If @DefaultValue Is NULL 	  	 --No default, free hand update
 	     BEGIN
 	  	 UPDATE  Report_Parameters
 	   	 SET     RPT_Id=@RPT_Id, RPG_Id=@RPG_Id, Description=@Description
 	      	       , Default_Value=@Default_Value, Is_Default=@Is_Default, spName=@spName, MultiSelect=@MultiSelect
 	      	 WHERE   RP_Name = @RP_Name
 	      	 If @@Error <> 0 SELECT @lStatus = @@Error Else SELECT @lStatus = 10
 	     END
 	 Else 	  	  	  	  	 --Has default value, don't update Default_Value
 	     BEGIN
 	      	 UPDATE Report_Parameters
 	      	 SET    RPT_Id=@RPT_Id, RPG_Id=@RPG_Id, Description=@Description
 	              , Is_Default=@Is_Default, spName=@spName, MultiSelect=@MultiSelect
 	      	 WHERE  RP_Name = @RP_Name
 	      	 If @@Error <> 0 Select @lStatus = @@Error Else Select @lStatus = 11 	      	 
 	     END
    END
END_OF_PROC:
Return (@lStatus)
