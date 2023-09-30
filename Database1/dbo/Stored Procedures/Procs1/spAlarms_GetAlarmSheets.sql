CREATE PROCEDURE dbo.spAlarms_GetAlarmSheets
 	  	  @UserId int
		 ,@VariableId INT = null
		 ,@PUIds 	 nvarchar(max) = null 
	  	 
AS

--------------------------------------------------------------------------------------
--Getting all the sheets (with variable and unit details) which the user has access to
--------------------------------------------------------------------------------------

--DECLARE @AuthorisedSheets TABLE(Sheet_Id Int, Access_level int, Var_Id int, PU_Id INT)  
CREATE TABLE #AuthorisedSheets(Sheet_Id Int, Access_level int, Var_Id int, PU_Id INT)  


IF (@PUIds IS NOT NULL) Set @PUIds = REPLACE(@PUIds, ' ', '')
IF @PUIds = '' SET @PUIds = Null

--Seek and Send approch

--Select only sheet with this variable
IF @VariableId IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM Variables_Base WHERE Var_Id = @VariableId)
			BEGIN
				SELECT Error = 'No variables found with the variable id supplied', Code = 'InvalidData', ErrorType = 'InvalidVariableId', PropertyName1 = 'VariableId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @VariableId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 				RETURN
			END
		-----------------------------------------------------------------
		--Retrun sheets for a particular variable
		---------------------------------------------------------------
		IF Exists(SELECT 1 FROM User_Security WHERE User_Id = @UserId  AND Group_Id =1 and Access_Level = 4) -- Administrator with admin access, sees everything under the sun
			BEGIN
				INSERT INTO #AuthorisedSheets (Sheet_Id , Access_level , Var_Id , PU_Id )
				    SELECT s.Sheet_Id, 4, SV.Var_Id, VB.PU_Id FROM Sheets s 
						JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
						JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id AND VB.Var_Id = @VariableId
					WHERE S.Sheet_Type = 11 AND s.Is_Active =1
			END
		ELSE
			BEGIN
				INSERT INTO #AuthorisedSheets  (Sheet_Id , Access_level , Var_Id , PU_Id )
					-- Display/Sheet level security
				 SELECT s.Sheet_Id, Access_level, SV.Var_Id, VB.PU_Id  FROM Sheets s  
					JOIN  User_Security us ON us.Group_Id = s.Group_Id AND us.user_id = @UserId  AND s.Is_Active =1 AND S.Sheet_Type = 11
					JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
					JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id AND VB.Var_Id = @VariableId
				     WHERE s.Group_Id is Not null
				  	 UNION
				 -- Display Group/Sheet Group level security
				 SELECT s.Sheet_Id, Access_level, SV.Var_Id, VB.PU_Id FROM Sheets s
				  	 JOIN Sheet_Groups sg ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1 AND S.Sheet_Type = 11
				  	 JOIN  User_Security us ON us.Group_Id = sg.Group_Id AND us.user_id = @UserId
					 JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
					 JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id AND VB.Var_Id = @VariableId
				  	 WHERE s.Group_Id is null AND sg.Group_Id is Not null AND s.Is_Active =1
				  	 UNION
				 --Display or Display group that is not assigned any security
				 SELECT s.Sheet_Id ,3 Access_level, SV.Var_Id, VB.PU_Id 
				  	 FROM Sheets s  
				  	 JOIN Sheet_Groups sg ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1 AND S.Sheet_Type = 11
					 JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
					 JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id AND VB.Var_Id = @VariableId
					 WHERE s.Group_Id is null AND SG.Group_Id is null
			END

	END
--Select only sheets under this units
ELSE IF @PUIds IS NOT NULL
	BEGIN
		--DECLARE @Requested_PUIds Table([PU_Id] [int] NOT NULL)
		CREATE TABLE #Requested_PUIds([PU_Id] [int] NOT NULL)
		--Split comma seperated string
		DECLARE @xml XML
		SET @xml = cast(('<X>'+replace(@PUIds,',','</X><X>')+'</X>') as xml)
		INSERT INTO #Requested_PUIds (PU_Id) 
			SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
		
		INSERT INTO #Requested_PUIds (PU_ID)
		SELECT PU_ID FROM Prod_Units_Base WHERE Master_Unit IN (SELECT PU_ID FROM #Requested_PUIds)

		IF Exists(SELECT 1 FROM User_Security WHERE User_Id = @UserId  AND Group_Id =1 and Access_Level = 4) -- Administrator with admin access, sees everything under the sun
			BEGIN
				INSERT INTO #AuthorisedSheets (Sheet_Id , Access_level , Var_Id , PU_Id )
				    SELECT s.Sheet_Id, 4, SV.Var_Id, VB.PU_Id FROM Sheets s 
						JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
						JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id
						JOIN #Requested_PUIds RP ON VB.PU_Id = RP.PU_Id
					WHERE S.Sheet_Type = 11 AND s.Is_Active =1
			END
		ELSE
			BEGIN
				INSERT INTO #AuthorisedSheets  (Sheet_Id , Access_level , Var_Id , PU_Id )
					-- Display/Sheet level security
				 SELECT s.Sheet_Id, Access_level, SV.Var_Id, VB.PU_Id  FROM Sheets s  
					JOIN  User_Security us ON us.Group_Id = s.Group_Id AND us.user_id = @UserId  AND s.Is_Active =1 AND S.Sheet_Type = 11
					JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
					JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id
					JOIN #Requested_PUIds RP ON VB.PU_Id = RP.PU_Id
				     WHERE s.Group_Id is Not null
				  	 UNION
				 -- Display Group/Sheet Group level security
				 SELECT s.Sheet_Id, Access_level, SV.Var_Id, VB.PU_Id FROM Sheets s
				  	 JOIN Sheet_Groups sg ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1 AND S.Sheet_Type = 11
				  	 JOIN  User_Security us ON us.Group_Id = sg.Group_Id AND us.user_id = @UserId
					 JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
					 JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id
					 JOIN #Requested_PUIds RP ON VB.PU_Id = RP.PU_Id
				  	 WHERE s.Group_Id is null AND sg.Group_Id is Not null AND s.Is_Active =1
				  	 UNION
				 --Display or Display group that is not assigned any security
				 SELECT s.Sheet_Id ,3 Access_level, SV.Var_Id, VB.PU_Id 
				  	 FROM Sheets s  
				  	 JOIN Sheet_Groups sg ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1 AND S.Sheet_Type = 11
					 JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
					 JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id
					 JOIN #Requested_PUIds RP ON VB.PU_Id = RP.PU_Id
					 WHERE s.Group_Id is null AND SG.Group_Id is null
			END

	END
-- Send back all the authorized sheets
ELSE
	BEGIN
		IF Exists(SELECT 1 FROM User_Security WHERE User_Id = @UserId  AND Group_Id =1 and Access_Level = 4) -- Administrator with admin access, sees everything under the sun
			BEGIN
				INSERT INTO #AuthorisedSheets (Sheet_Id , Access_level , Var_Id , PU_Id )
				    SELECT s.Sheet_Id, 4, SV.Var_Id, VB.PU_Id FROM Sheets s 
						JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
						JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id
					WHERE S.Sheet_Type = 11 AND s.Is_Active =1
			END
		ELSE
			BEGIN
				INSERT INTO #AuthorisedSheets  (Sheet_Id , Access_level , Var_Id , PU_Id )
					-- Display/Sheet level security
				 SELECT s.Sheet_Id, Access_level, SV.Var_Id, VB.PU_Id  FROM Sheets s  
					JOIN  User_Security us ON us.Group_Id = s.Group_Id AND us.user_id = @UserId  AND s.Is_Active =1 AND S.Sheet_Type = 11
					JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
					JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id
				     WHERE s.Group_Id is Not null
				  	 UNION
				 -- Display Group/Sheet Group level security
				 SELECT s.Sheet_Id, Access_level, SV.Var_Id, VB.PU_Id FROM Sheets s
				  	 JOIN Sheet_Groups sg ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1 AND S.Sheet_Type = 11
				  	 JOIN  User_Security us ON us.Group_Id = sg.Group_Id AND us.user_id = @UserId
					 JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
					 JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id
				  	 WHERE s.Group_Id is null AND sg.Group_Id is Not null AND s.Is_Active =1
				  	 UNION
				 --Display or Display group that is not assigned any security
				 SELECT s.Sheet_Id ,3 Access_level, SV.Var_Id, VB.PU_Id 
				  	 FROM Sheets s  
				  	 JOIN Sheet_Groups sg ON sg.Sheet_Group_Id=s.Sheet_Group_Id  AND s.Is_Active =1 AND S.Sheet_Type = 11
					 JOIN Sheet_Variables SV ON s.Sheet_Id = SV.Sheet_Id
					 JOIN Variables_Base VB ON SV.Var_Id = VB.Var_Id
					 WHERE s.Group_Id is null AND SG.Group_Id is null
			END

	END


--------------------------------------------------------------
--Throw error if no alarm sheets found for the user or in plant apps
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM #AuthorisedSheets)
	BEGIN
		-- Checking for any available alarm sheet in PA, else throw error dont trow this now as the wrpper sproc is only expeccting authorization error
		--IF NOT EXISTS (SELECT 1 FROM Sheets where Sheet_Type = 11)
		--	BEGIN
		--		SELECT Error = 'ERROR:No Alarm Sheets configured at the moment in Plant Application', Code = 'NoAlarmSheetsinPlantApps', ErrorType = 'NoAlarmSheetsinPlantApps', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
		--		PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		--		RETURN
		--	END
		SELECT Error = 'No authorized alarm sheets configured for this user', Code = 'InsufficientPermission', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
 
--Return the result Set
SELECT AUS.Sheet_Id, AUS.Access_level, AUS.Var_Id, AUS.PU_Id FROM #AuthorisedSheets AUS
