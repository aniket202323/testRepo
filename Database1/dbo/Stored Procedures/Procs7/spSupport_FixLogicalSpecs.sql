CREATE PROCEDURE dbo.spSupport_FixLogicalSpecs
AS
DECLARE  @SpecVar Table (Id Int Identity(1,1),SpecId Int)
DECLARE  @Variables Table (Id Int Identity(1,1),VarId Int)
DECLARE @CurrentId int
DECLARE @RowsToDo Int
INSERT INTO @SpecVar(SpecId)
 	 SELECT Spec_Id 
 	 FROM Specifications 
 	 WHERE Data_Type_Id = 4
SET @RowsToDo = @@ROWCOUNT 
WHILE  	 @RowsToDo > 0
BEGIN
 	 SELECT @CurrentId = SpecId FROM @SpecVar WHERE Id = @RowsToDo
 	 UPDATE Active_Specs Set L_Entry = '1' WHERE Spec_Id = @CurrentId and  L_Entry = 'True'
 	 UPDATE Active_Specs Set L_Reject = '1' WHERE Spec_Id = @CurrentId and  L_Reject = 'True'
 	 UPDATE Active_Specs Set L_User = '1' WHERE Spec_Id = @CurrentId and  L_User = 'True'
 	 UPDATE Active_Specs Set L_Warning = '1' WHERE Spec_Id = @CurrentId and  L_Warning = 'True'
 	 UPDATE Active_Specs Set Target = '1' WHERE Spec_Id = @CurrentId and  Target = 'True'
 	 UPDATE Active_Specs Set U_Entry = '1' WHERE Spec_Id = @CurrentId and  U_Entry = 'True'
 	 UPDATE Active_Specs Set U_Reject = '1' WHERE Spec_Id = @CurrentId and  U_Reject = 'True'
 	 UPDATE Active_Specs Set U_User = '1' WHERE Spec_Id = @CurrentId and  U_User = 'True'
 	 UPDATE Active_Specs Set U_Warning = '1' WHERE Spec_Id = @CurrentId and  U_Warning = 'True'
 	 UPDATE Active_Specs Set L_Control = '1' WHERE Spec_Id = @CurrentId and  L_Control = 'True'
 	 UPDATE Active_Specs Set T_Control = '1' WHERE Spec_Id = @CurrentId and  T_Control = 'True'
 	 UPDATE Active_Specs Set U_Control = '1' WHERE Spec_Id = @CurrentId and  U_Control = 'True'
 	 
 	 UPDATE Active_Specs Set L_Entry = '0' WHERE Spec_Id = @CurrentId and  L_Entry = 'False'
 	 UPDATE Active_Specs Set L_Reject = '0' WHERE Spec_Id = @CurrentId and  L_Reject = 'False'
 	 UPDATE Active_Specs Set L_User = '0' WHERE Spec_Id = @CurrentId and  L_User = 'False'
 	 UPDATE Active_Specs Set L_Warning = '0' WHERE Spec_Id = @CurrentId and  L_Warning = 'False'
 	 UPDATE Active_Specs Set Target = '0' WHERE Spec_Id = @CurrentId and  Target = 'False'
 	 UPDATE Active_Specs Set U_Entry = '0' WHERE Spec_Id = @CurrentId and  U_Entry = 'False'
 	 UPDATE Active_Specs Set U_Reject = '0' WHERE Spec_Id = @CurrentId and  U_Reject = 'False'
 	 UPDATE Active_Specs Set U_User = '0' WHERE Spec_Id = @CurrentId and  U_User = 'False'
 	 UPDATE Active_Specs Set U_Warning = '0' WHERE Spec_Id = @CurrentId and  U_Warning = 'False'
 	 UPDATE Active_Specs Set L_Control = '0' WHERE Spec_Id = @CurrentId and  L_Control = 'False'
 	 UPDATE Active_Specs Set T_Control = '0' WHERE Spec_Id = @CurrentId and  T_Control = 'False'
 	 UPDATE Active_Specs Set U_Control = '0' WHERE Spec_Id = @CurrentId and  U_Control = 'False'
 	 SET @RowsToDo = @RowsToDo -1
END
SET @RowsToDo = 0
INSERT INTO @Variables(VarId)
 	 SELECT Var_Id 
 	 FROM Variables 
 	 WHERE Data_Type_Id = 4
SET @RowsToDo = @@ROWCOUNT  	 
WHILE  	 @RowsToDo > 0
BEGIN
 	 SELECT @CurrentId = VarId FROM @Variables WHERE Id = @RowsToDo
 	 UPDATE Var_Specs Set L_Entry = '1' WHERE Var_Id = @CurrentId and  L_Entry = 'True'
 	 UPDATE Var_Specs Set L_Reject = '1' WHERE Var_Id = @CurrentId and  L_Reject = 'True'
 	 UPDATE Var_Specs Set L_User = '1' WHERE Var_Id = @CurrentId and  L_User = 'True'
 	 UPDATE Var_Specs Set L_Warning = '1' WHERE Var_Id = @CurrentId and  L_Warning = 'True'
 	 UPDATE Var_Specs Set Target = '1' WHERE Var_Id = @CurrentId and  Target = 'True'
 	 UPDATE Var_Specs Set U_Entry = '1' WHERE Var_Id = @CurrentId and  U_Entry = 'True'
 	 UPDATE Var_Specs Set U_Reject = '1' WHERE Var_Id = @CurrentId and  U_Reject = 'True'
 	 UPDATE Var_Specs Set U_User = '1' WHERE Var_Id = @CurrentId and  U_User = 'True'
 	 UPDATE Var_Specs Set U_Warning = '1' WHERE Var_Id = @CurrentId and  U_Warning = 'True'
 	 UPDATE Var_Specs Set L_Control = '1' WHERE Var_Id = @CurrentId and  L_Control = 'True'
 	 UPDATE Var_Specs Set T_Control = '1' WHERE Var_Id = @CurrentId and  T_Control = 'True'
 	 UPDATE Var_Specs Set U_Control = '1' WHERE Var_Id = @CurrentId and  U_Control = 'True'
 	 
 	 UPDATE Var_Specs Set L_Entry = '0' WHERE Var_Id = @CurrentId and  L_Entry = 'False'
 	 UPDATE Var_Specs Set L_Reject = '0' WHERE Var_Id = @CurrentId and  L_Reject = 'False'
 	 UPDATE Var_Specs Set L_User = '0' WHERE Var_Id = @CurrentId and  L_User = 'False'
 	 UPDATE Var_Specs Set L_Warning = '0' WHERE Var_Id = @CurrentId and  L_Warning = 'False'
 	 UPDATE Var_Specs Set Target = '0' WHERE Var_Id = @CurrentId and  Target = 'False'
 	 UPDATE Var_Specs Set U_Entry = '0' WHERE Var_Id = @CurrentId and  U_Entry = 'False'
 	 UPDATE Var_Specs Set U_Reject = '0' WHERE Var_Id = @CurrentId and  U_Reject = 'False'
 	 UPDATE Var_Specs Set U_User = '0' WHERE Var_Id = @CurrentId and  U_User = 'False'
 	 UPDATE Var_Specs Set U_Warning = '0' WHERE Var_Id = @CurrentId and  U_Warning = 'False'
 	 UPDATE Var_Specs Set L_Control = '0' WHERE Var_Id = @CurrentId and  L_Control = 'False'
 	 UPDATE Var_Specs Set T_Control = '0' WHERE Var_Id = @CurrentId and  T_Control = 'False'
 	 UPDATE Var_Specs Set U_Control = '0' WHERE Var_Id = @CurrentId and  U_Control = 'False'
 	 SET @RowsToDo = @RowsToDo -1
END 	 
