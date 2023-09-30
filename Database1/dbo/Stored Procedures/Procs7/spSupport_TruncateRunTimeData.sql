CREATE PROCEDURE dbo.spSupport_TruncateRunTimeData 
@PassWord varchar(100)
AS
Set NoCount On
Declare @HistOnly Int
IF @PassWord = 'Caution History Data Will Be Lost'
BEGIN
 	 SET @HistOnly = 1
END
ELSE IF @PassWord = 'Caution All Data Will Be Lost'
BEGIN
 	 SET @HistOnly = 0
END
ELSE
BEGIN
 	 SELECT 'Incorrect Password'
 	 RETURN
END
Declare @TableName VarChar(100)
Declare @FKName VarChar(100)
Declare @FKTable VarChar(100)
Declare @Fks Table (Id Int Identity(1,1),fkName VarChar(100),FkTable VarChar(100))
Declare @DropSQL VarChar(1000)
DECLARE @TablesToTruncate TABLE (TName VarChar(100))
/* Tests */
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Array_Data')
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Tests')
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('GB_RSum')
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('GB_RSum_Data')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Test_History')
/* Events */
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Events')
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Event_Components')
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Event_Details')
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Event_Status_Transitions')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Event_Component_History')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Event_History')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Event_Detail_History')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('PrdExec_Input_Event_History')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('PrdExec_Input_Event_Transitions')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('PrdExec_Output_Event_History')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('PrdExec_Output_Event_Transitions')
/* WASTE */
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Waste_Event_Details')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Waste_Event_Detail_History')
/* DownTime*/
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Timed_Event_Details')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Timed_Event_Detail_History')
/* User_Defined_Events*/
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('User_Defined_Events')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('User_Defined_Event_History')
/*Alarms */
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Alarms')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Alarm_History')
/* Path Starts */
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('PrdExec_Path_Unit_Starts')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('PrdExec_Path_Unit_Starts_History')
/* Sheet_Columns*/
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Sheet_Columns')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Sheet_Column_History')
/* Non Productive times*/
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('NonProductive_Detail')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('NonProductive_Detail_History')
/*Common Tables */
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('ESignature')
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Table_Fields_Values')
If @HistOnly != 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Comments')
/* Production _Starts*/
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Production_Starts_History')
/* Misc*/
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Client_Connection_User_History')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Message_Log_Detail')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Server_Log_Records')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Report_Engine_Activity')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('errors')
If @HistOnly = 1 INSERT INTO @TablesToTruncate(TName) VALUES ('Audit_Trail')
WHILE Exists (Select 1 From @TablesToTruncate)
BEGIN
 	 SELECT @TableName = TName FROM @TablesToTruncate
 	 Insert INTO @Fks(fkName,FkTable)
 	 SELECT s1.Name,s2.Name
 	 From sys.sysobjects s1
 	 Join sys.sysforeignkeys sf ON s1.id = sf.constid
 	 JOIN sys.sysobjects s2 on s2.id = sf.FkeyId
 	 Where rkeyId = object_id(@TableName)
 	 WHILE Exists (Select 1 From @Fks)
 	 BEGIN
 	  	 SELECT @FKName = fkName,@FKTable = FkTable From @Fks
 	  	 SELECT @DropSQL = 'ALTER TABLE ' + @FKTable + ' DROP CONSTRAINT ' + @FKName
 	  	 EXECUTE (@DropSQL)
 	  	 DELETE FROM @Fks WHERE fkName = @FKName
 	 END
 	 SELECT @DropSQL = 'TRUNCATE TABLE ' + @TableName 
 	 EXECUTE (@DropSQL)
 	 DELETE FROM @TablesToTruncate WHERE TName = @TableName
END
If @HistOnly != 1
BEGIN
 	 UPDATE PrdExec_Input_Event set Event_Id = Null Where Event_Id Is Not Null
 	 UPDATE PrdExec_Output_Event  set Event_Id = Null Where Event_Id Is Not Null
 	 Alter TABLE Production_Starts DISABLE TRIGGER ALL
 	 DELETE FROM Production_Starts WHERE End_Time Is Not NULL
 	 UPDATE Production_Starts SET Start_Time = '1/1/1970',Prod_Id = 1
 	 Alter TABLE Production_Starts ENABLE TRIGGER ALL
 	 Declare @Now DateTime
 	 Select @Now = GETDATE()
 	 Alter TABLE Var_Specs DISABLE TRIGGER ALL
 	 DELETE FROM Var_Specs  WHERE Expiration_Date <  @Now
 	 Alter TABLE Var_Specs ENABLE TRIGGER ALL
 	 
 	 Alter TABLE Active_Specs DISABLE TRIGGER ALL
 	 DELETE FROM Active_Specs  WHERE Expiration_Date <  @Now
 	 Alter TABLE Active_Specs ENABLE TRIGGER ALL
END
If @HistOnly != 1 
BEGIN
 	 DROP TABLE Tests
 	 DROP TABLE Test_History
END
PRINT 'Table Truncation Completed - ReRun Plant Applications Install'
