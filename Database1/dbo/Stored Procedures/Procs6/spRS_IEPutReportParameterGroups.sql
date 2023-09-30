CREATE PROCEDURE dbo.spRS_IEPutReportParameterGroups 
 	   @Group_Id 	  	 int 	  	  	 --NOT USED
 	 , @Group_Name 	  	 varchar(20)
 	 , @Group_Type 	  	 int
 	 , @Group_Id_Target 	 int 	 OUTPUT
AS
/*  For user with IMPORT of report packages
    to update relevant rows in Report_Parameter_Groups
    MSI-MT 8-14-2000/Modified to include constraint 1-9-2001
*/
Declare @GroupType 	  	 int 	 
Declare @lStatus 	  	 int
Declare @lConstraintExists 	 Bit
Select @lStatus = -9191
Select @Group_Id_Target = -9191
If @Group_Id = 0 OR @Group_Id Is NULL
    BEGIN
 	 Select @lStatus = -2000
 	 GOTO END_OF_PROC
    END
/* Check Existing Constraint, [dbo.Report_Parameter_Groups
   has unique Group_Name as constraint]
*/
If EXISTS( SELECT RPG.Group_Id  
 	    FROM   Report_Parameter_Groups RPG  
 	    WHERE  RPG.Group_Name = @Group_Name
 	  )
SELECT @lConstraintExists = 1 Else SELECT @lConstraintExists = 0
If @lConstraintExists = 0 	  	  	 --No constraint exists; free insert
    BEGIN
 	 INSERT INTO Report_Parameter_Groups
 	 (Group_Name, Group_Type) values(@Group_Name, @Group_Type) 	 
 	 If @@Error <> 0 Select @lStatus = @@Error Else Select @lStatus = 20
 	 Select @Group_Id_Target = Scope_Identity()
 	 if @@Error <> 0 Select @lStatus = @@Error
    END
Else If @lConstraintExists = 1 	  	  	 --Yes constraint exists; get target ID, may update
    BEGIN
 	 SELECT @Group_Id_Target = @Group_Id
 	      , @GroupType = RPG.Group_Type
   	 FROM   Report_Parameter_Groups RPG  
 	 WHERE  RPG.Group_Name = @Group_Name
        If NOT @GroupType Is NULL 	  	  	 
 	     SELECT @lStatus = 12 	  	 --update not needed
 	 Else 	  	  	  	  	  	 
 	     BEGIN
 	         UPDATE Report_Parameter_Groups
 	         SET    Group_Type = @Group_Type
 	         WHERE  Group_Name = @Group_Name
 	         If @@Error <> 0 Select @lStatus = @@Error Else Select @lStatus = 10
            END 	 
    END
END_OF_PROC:
Return (@lStatus)
